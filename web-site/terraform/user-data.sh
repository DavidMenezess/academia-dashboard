#!/bin/bash

# ========================================
# SCRIPT DE INICIALIZAÇÃO - AWS FREE TIER
# Academia Dashboard - Deploy Automático
# ========================================

set -e # Parar em caso de erro

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1"
}

warning() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] AVISO: $1"
}

# Redirecionar output para log
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

log "========================================="
log "Iniciando configuração do servidor..."
log "========================================="

# Atualizar sistema
log "Atualizando sistema operacional..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Instalar dependências básicas
log "Instalando dependências básicas..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    ufw \
    fail2ban \
    unzip \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    gnupg \
    lsb-release

# Configurar timezone
log "Configurando timezone para America/Sao_Paulo..."
timedatectl set-timezone America/Sao_Paulo

# Instalar Docker
log "Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
    log "Docker instalado com sucesso!"
else
    log "Docker já está instalado"
fi

# Instalar Docker Compose
log "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log "Docker Compose v2.24.0 instalado!"

# Configurar usuário ubuntu para usar Docker
usermod -aG docker ubuntu

# Configurar Firewall UFW
log "Configurando firewall UFW..."
ufw --force disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp     # SSH
ufw allow 80/tcp     # HTTP
ufw allow 443/tcp    # HTTPS
ufw allow 3000/tcp   # API
ufw --force reload
log "Firewall configurado!"

# Configurar Fail2ban para proteção SSH
log "Configurando Fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Criar diretório do projeto
log "Criando diretório do projeto..."
mkdir -p /home/ubuntu/academia-dashboard
chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard

# Clonar repositório
log "Clonando repositório..."
cd /home/ubuntu
sudo -u ubuntu git clone ${github_repo} academia-dashboard
if [ $? -eq 0 ]; then
    log "Repositório clonado com sucesso!"
else
    error "Falha ao clonar repositório. Continuando sem código fonte..."
fi

# Se o projeto foi clonado, fazer deploy
if [ -d "/home/ubuntu/academia-dashboard" ]; then
    log "Projeto encontrado, verificando estrutura..."
    ls -la /home/ubuntu/academia-dashboard/
    
    if [ -f "/home/ubuntu/academia-dashboard/web-site/docker-compose.prod.yml" ]; then
        log "docker-compose.prod.yml encontrado em web-site/"
        cd /home/ubuntu/academia-dashboard/web-site
    elif [ -f "/home/ubuntu/academia-dashboard/docker-compose.prod.yml" ]; then
        log "docker-compose.prod.yml encontrado na raiz"
        cd /home/ubuntu/academia-dashboard
    else
        error "docker-compose.prod.yml não encontrado!"
        ls -la /home/ubuntu/academia-dashboard/
        exit 1
    fi
    
    log "Iniciando deploy da aplicação..."
    
    # Criar diretórios necessários
    mkdir -p data logs api/uploads
    
    # Criar arquivo de dados inicial se não existir
    if [ ! -f "data/academia_data.json" ]; then
        log "Criando arquivo de dados inicial..."
        cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Dashboard",
    "endereco": "Configurar no admin"
  },
  "estatisticas": {
    "total_membros": 0,
    "membros_ativos": 0,
    "receita_mensal": 0,
    "aulas_realizadas": 0,
    "instrutores_ativos": 0
  },
  "versao": "1.0.0",
  "ultima_atualizacao": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    fi
    
    # Ajustar permissões
    chown -R ubuntu:ubuntu .
    
    # Fazer build e iniciar containers
    log "Executando docker-compose..."
    docker-compose -f docker-compose.prod.yml down || true
    docker-compose -f docker-compose.prod.yml up -d --build
    
    # Aguardar containers iniciarem
    log "Aguardando containers iniciarem..."
    sleep 20
    
    # Verificar se containers estão rodando
    log "Verificando status dos containers..."
    docker ps
    
    # Verificar logs se containers não estiverem rodando
    if ! docker ps | grep -q "academia-dashboard-prod"; then
        warning "⚠️ Dashboard container não está rodando"
        log "Verificando logs do dashboard..."
        docker logs academia-dashboard-prod || true
        log "Tentando reiniciar..."
        docker-compose -f docker-compose.prod.yml restart academia-dashboard
        sleep 10
    else
        log "✅ Dashboard container está rodando"
    fi
    
    if ! docker ps | grep -q "academia-data-api-prod"; then
        warning "⚠️ API container não está rodando"
        log "Verificando logs da API..."
        docker logs academia-data-api-prod || true
        log "Tentando reiniciar..."
        docker-compose -f docker-compose.prod.yml restart data-api
        sleep 10
    else
        log "✅ API container está rodando"
    fi
    
    # Verificação final
    log "🎯 STATUS FINAL DOS CONTAINERS:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Testar se a aplicação está respondendo
    log "🧪 TESTANDO APLICAÇÃO..."
    sleep 5
    if curl -s http://localhost > /dev/null; then
        log "✅ APLICAÇÃO RESPONDENDO EM http://localhost"
    else
        warning "⚠️ Aplicação não está respondendo"
    fi
    
    log "Aplicação iniciada com sucesso!"
else
    warning "Projeto não encontrado ou docker-compose.prod.yml ausente"
    warning "Deploy manual será necessário"
fi

# Criar script de atualização
log "Criando script de atualização..."
cat > /usr/local/bin/update-academia-dashboard << 'SCRIPT_EOF'
#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/academia-dashboard"
BACKUP_DIR="/home/ubuntu/backups/$(date +%Y%m%d_%H%M%S)"

echo "Criando backup..."
mkdir -p $BACKUP_DIR
cp -r $PROJECT_DIR/data $BACKUP_DIR/ 2>/dev/null || true
cp -r $PROJECT_DIR/logs $BACKUP_DIR/ 2>/dev/null || true

echo "Atualizando código do GitHub..."
cd $PROJECT_DIR
git pull

echo "Reconstruindo containers..."
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

echo "Atualização concluída!"
SCRIPT_EOF

chmod +x /usr/local/bin/update-academia-dashboard
log "Script de atualização criado: /usr/local/bin/update-academia-dashboard"

# Criar script de backup
log "Criando script de backup..."
cat > /usr/local/bin/backup-academia-dashboard << 'BACKUP_EOF'
#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/academia-dashboard"
BACKUP_BASE="/home/ubuntu/backups"
BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d_%H%M%S)"

echo "Criando backup do Academia Dashboard..."

mkdir -p $BACKUP_DIR

# Backup dos dados
if [ -d "$PROJECT_DIR/data" ]; then
    cp -r $PROJECT_DIR/data $BACKUP_DIR/
    echo "Dados copiados para $BACKUP_DIR"
fi

# Backup dos logs
if [ -d "$PROJECT_DIR/logs" ]; then
    cp -r $PROJECT_DIR/logs $BACKUP_DIR/
    echo "Logs copiados para $BACKUP_DIR"
fi

# Compactar backup
cd $BACKUP_BASE
tar -czf "backup_$(date +%Y%m%d_%H%M%S).tar.gz" "$(basename $BACKUP_DIR)"
rm -rf $BACKUP_DIR

# Manter apenas últimos 7 backups
ls -t $BACKUP_BASE/backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup salvo em: $BACKUP_DIR"
BACKUP_EOF

chmod +x /usr/local/bin/backup-academia-dashboard
log "Script de backup criado: /usr/local/bin/backup-academia-dashboard"

# Configurar backup automático
log "Configurando backup automático..."
echo "0 2 * * * /usr/local/bin/backup-academia-dashboard" | crontab -

# Aplicar otimizações de performance
log "Aplicando otimizações de performance..."
cat >> /etc/sysctl.conf << 'EOF'
# Otimizações de rede
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5
EOF

sysctl -p

# Criar arquivo de informações do sistema
log "Criando arquivo de informações do sistema..."
cat > /home/ubuntu/SYSTEM_INFO.txt << 'INFO_EOF'
=========================================
INFORMAÇÕES DO SISTEMA - ACADEMIA DASHBOARD
=========================================

Data de criação: $(date)
Sistema: Ubuntu 22.04 LTS
Docker: $(docker --version)
Docker Compose: $(docker-compose --version)

IP Público: $(curl -s ifconfig.me)
IP Privado: $(hostname -I | awk '{print $1}')

Status dos containers:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

Comandos úteis:
- Ver logs: docker logs -f academia-dashboard-prod
- Reiniciar: docker-compose -f docker-compose.prod.yml restart
- Atualizar: sudo update-academia-dashboard
- Backup: sudo backup-academia-dashboard

=========================================
INFO_EOF

chmod 644 /home/ubuntu/SYSTEM_INFO.txt

# Finalizar
log "========================================="
log "✅ Configuração concluída com sucesso!"
log "========================================="

log "Próximos passos:"
log "1. Conecte-se via SSH: ssh -i sua-chave.pem ubuntu@$(curl -s ifconfig.me)"
log "2. Verifique o arquivo: cat ~/SYSTEM_INFO.txt"
log "3. Acesse o dashboard no navegador"
log "Para ver este log novamente: tail -f /var/log/user-data.log"
log "========================================="