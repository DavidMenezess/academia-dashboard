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

# Clonar repositório se fornecido
if [ -n "${github_repo}" ] && [ "${github_repo}" != "" ]; then
    log "Clonando repositório: ${github_repo}"
    cd /home/ubuntu
    sudo -u ubuntu git clone ${github_repo} academia-dashboard || {
        error "Falha ao clonar repositório. Continuando sem código fonte..."
    }
else
    warning "URL do repositório GitHub não fornecida"
    warning "Você precisará fazer deploy manual do código"
fi

# Se o projeto foi clonado, fazer deploy
if [ -d "/home/ubuntu/academia-dashboard" ]; then
    log "Projeto encontrado, fazendo deploy..."
    cd /home/ubuntu/academia-dashboard
    
    # Verificar se tem web-site/
    if [ -d "web-site" ]; then
        log "Entrando na pasta web-site..."
        cd web-site
    fi
    
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
    sudo -u ubuntu docker-compose -f docker-compose.prod.yml up -d --build
    
    # Aguardar containers iniciarem
    log "Aguardando containers iniciarem..."
    sleep 30
    
    # Verificar se containers estão rodando
    log "Verificando status dos containers..."
    sudo -u ubuntu docker ps
    
    log "Aplicação iniciada com sucesso!"
else
    warning "Projeto não encontrado"
    warning "Deploy manual será necessário"
fi

# Criar script de atualização
log "Criando script de atualização..."
cat > /usr/local/bin/update-academia-dashboard << 'SCRIPT_EOF'
#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/academia-dashboard"

echo "Atualizando Academia Dashboard..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Erro: Projeto não encontrado em $PROJECT_DIR"
    exit 1
fi

cd $PROJECT_DIR

# Se tem web-site/, entrar nele
if [ -d "web-site" ]; then
    cd web-site
fi

# Backup dos dados
echo "Criando backup..."
BACKUP_DIR="$PROJECT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp -r data $BACKUP_DIR/ 2>/dev/null || true

# Atualizar código
echo "Atualizando código do GitHub..."
git pull

# Rebuild containers
echo "Reconstruindo containers..."
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

echo "Atualização concluída!"
echo "Backup salvo em: $BACKUP_DIR"
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

echo "Backup concluído!"
ls -lh $BACKUP_BASE/backup_*.tar.gz | head -1
BACKUP_EOF

chmod +x /usr/local/bin/backup-academia-dashboard
log "Script de backup criado: /usr/local/bin/backup-academia-dashboard"

# Configurar cron para backup automático (diário às 3h)
log "Configurando backup automático..."
(crontab -u ubuntu -l 2>/dev/null || true; echo "0 3 * * * /usr/local/bin/backup-academia-dashboard >> /var/log/backup-academia.log 2>&1") | crontab -u ubuntu -

# Otimizações de performance
log "Aplicando otimizações de performance..."
# Aumentar limites de arquivos abertos
cat >> /etc/security/limits.conf << 'LIMITS_EOF'
* soft nofile 65535
* hard nofile 65535
LIMITS_EOF

# Otimizar kernel para servidor web
cat >> /etc/sysctl.conf << 'SYSCTL_EOF'
# Otimizações para servidor web
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
SYSCTL_EOF
sysctl -p

# Criar arquivo de informações do sistema
log "Criando arquivo de informações do sistema..."
cat > /home/ubuntu/SYSTEM_INFO.txt << INFO_EOF
========================================
ACADEMIA DASHBOARD - INFORMAÇÕES DO SISTEMA
========================================

🚀 Deploy completado em: $(date)

📍 Informações do Servidor:
- IP Privado: $(hostname -I | awk '{print $1}')
- IP Público: $(curl -s ifconfig.me)
- Hostname: $(hostname)
- SO: $(lsb_release -d | cut -f2)

📦 Versões Instaladas:
- Docker: $(docker --version)
- Docker Compose: $(docker-compose --version)
- Git: $(git --version)

🌐 URLs de Acesso:
- Dashboard: http://$(curl -s ifconfig.me)
- API: http://$(curl -s ifconfig.me):3000
- Health Check: http://$(curl -s ifconfig.me)/health

📁 Diretórios:
- Projeto: /home/ubuntu/academia-dashboard
- Logs: /var/log/user-data.log
- Backups: /home/ubuntu/backups

🔧 Scripts Úteis:
- Atualizar: sudo update-academia-dashboard
- Backup: sudo backup-academia-dashboard
- Ver logs: docker logs -f academia-dashboard-prod
- Ver containers: docker ps
- Reiniciar: cd /home/ubuntu/academia-dashboard && docker-compose -f docker-compose.prod.yml restart

🔒 Segurança:
- Firewall UFW: Ativo
- Fail2ban: Ativo
- SSH: Porta 22

📊 Monitoramento:
- Status containers: docker ps
- Logs aplicação: tail -f /home/ubuntu/academia-dashboard/logs/*.log
- Logs sistema: tail -f /var/log/user-data.log

========================================
INFO_EOF

chown ubuntu:ubuntu /home/ubuntu/SYSTEM_INFO.txt

# Finalização
log "========================================="
log "✅ Configuração concluída com sucesso!"
log "========================================="
log ""
log "📋 Próximos passos:"
log "1. Conecte-se via SSH: ssh -i sua-chave.pem ubuntu@\$(curl -s ifconfig.me)"
log "2. Verifique o arquivo: cat ~/SYSTEM_INFO.txt"
log "3. Acesse o dashboard no navegador"
log ""
log "Para ver este log novamente: tail -f /var/log/user-data.log"
log "========================================="

# Criar arquivo de flag indicando conclusão
touch /var/log/user-data-complete
echo "$(date)" > /var/log/user-data-complete

exit 0
