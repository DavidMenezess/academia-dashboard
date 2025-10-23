#!/bin/bash

# ========================================
# SCRIPT DE INICIALIZAÇÃO CORRIGIDO
# Academia Dashboard - Deploy Automático
# ========================================

set -e

# Função de log
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1"; }

# Redirecionar output para log
exec > >(tee -a /var/log/user-data.log) 2>&1

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

# Instalar AWS CLI
log "Instalando AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    log "AWS CLI instalado com sucesso!"
else
    log "AWS CLI já está instalado"
fi

# Configurar Firewall UFW
log "Configurando firewall UFW..."
ufw --force disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp     # SSH
ufw allow 80/tcp     # HTTP
ufw allow 443/tcp    # HTTPS
ufw allow 3000/tcp   # API
ufw --force enable
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
sudo -u ubuntu git clone https://github.com/DavidMenezess/academia-dashboard.git
if [ $? -eq 0 ]; then
    log "Repositório clonado com sucesso!"
else
    error "Falha ao clonar repositório. Continuando sem código fonte..."
fi

# Se o projeto foi clonado, fazer deploy
if [ -d "/home/ubuntu/academia-dashboard" ]; then
    log "Projeto encontrado, verificando estrutura..."
    ls -la /home/ubuntu/academia-dashboard/
    
    if [ -f "/home/ubuntu/academia-dashboard/web-site/docker-compose-fixed.yml" ]; then
        log "docker-compose-fixed.yml encontrado em web-site/"
        cd /home/ubuntu/academia-dashboard/web-site
        COMPOSE_FILE="docker-compose-fixed.yml"
    elif [ -f "/home/ubuntu/academia-dashboard/web-site/docker-compose.prod.yml" ]; then
        log "docker-compose.prod.yml encontrado em web-site/"
        cd /home/ubuntu/academia-dashboard/web-site
        COMPOSE_FILE="docker-compose.prod.yml"
    elif [ -f "/home/ubuntu/academia-dashboard/docker-compose.prod.yml" ]; then
        log "docker-compose.prod.yml encontrado na raiz"
        cd /home/ubuntu/academia-dashboard
        COMPOSE_FILE="docker-compose.prod.yml"
    else
        error "docker-compose.prod.yml não encontrado!"
        ls -la /home/ubuntu/academia-dashboard/
        exit 1
    fi
    
    log "Iniciando deploy da aplicação..."
    
    # Criar diretórios necessários
    mkdir -p data logs api/uploads
    chown -R ubuntu:ubuntu .
    
    # Criar dados iniciais
    log "Criando dados iniciais..."
    cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Força Fitness",
    "endereco": "Rua das Academias, 123 - Centro",
    "telefone": "(11) 99999-9999",
    "email": "contato@forcafitness.com",
    "horario_funcionamento": "06:00 - 22:00",
    "dias_funcionamento": "Segunda a Sábado"
  },
  "estatisticas": {
    "total_membros": 150,
    "membros_ativos": 120,
    "membros_novos_mes": 8,
    "receita_mensal": 15000.00,
    "receita_anual": 180000.00,
    "aulas_realizadas": 45,
    "aulas_agendadas": 12,
    "instrutores_ativos": 6,
    "equipamentos_total": 25,
    "equipamentos_manutencao": 2
  },
  "membros": {
    "por_faixa_etaria": {
      "18-25": 35,
      "26-35": 45,
      "36-45": 40,
      "46-55": 20,
      "55+": 10
    },
    "por_plano": {
      "mensal": 80,
      "trimestral": 35,
      "semestral": 20,
      "anual": 15
    }
  },
  "aulas": {
    "musculacao": {
      "total": 20,
      "participantes_media": 8
    },
    "pilates": {
      "total": 15,
      "participantes_media": 6
    },
    "spinning": {
      "total": 10,
      "participantes_media": 12
    }
  },
  "financeiro": {
    "receitas": {
      "mensalidades": 12000.00,
      "aulas_particulares": 2000.00,
      "produtos": 1000.00
    },
    "despesas": {
      "aluguel": 3000.00,
      "funcionarios": 8000.00,
      "equipamentos": 500.00,
      "utilitarios": 800.00
    }
  },
  "metas": {
    "membros_meta": 200,
    "receita_meta": 20000.00,
    "satisfacao_meta": 4.5
  },
  "ultima_atualizacao": "2025-01-23T00:00:00Z",
  "versao": "1.0.0"
}
EOF
    
    # Instalar dependências da API se necessário
    if [ -d "api" ]; then
        log "Instalando dependências da API..."
        cd api
        npm install --production
        cd ..
    fi
    
    # Limpar containers e volumes órfãos
    log "Limpando containers e volumes órfãos..."
    docker system prune -f || true
    docker volume prune -f || true
    docker network prune -f || true
    
    # Fazer build e iniciar containers
    log "Executando docker-compose..."
    docker-compose -f $COMPOSE_FILE down || true
    
    # Aguardar um pouco antes do build
    sleep 5
    
    # Fazer build com no-cache para garantir que funcione
    log "Fazendo build dos containers..."
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    # Iniciar containers
    log "Iniciando containers..."
    docker-compose -f $COMPOSE_FILE up -d
    
    # Aguardar containers iniciarem
    log "Aguardando containers iniciarem..."
    sleep 45
    
    # Verificar se containers estão rodando
    log "Verificando status dos containers..."
    docker ps
    
    # Verificar e corrigir containers se necessário
    for i in {1..5}; do
        log "Verificação $i/5 dos containers..."
        
        dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
        api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")
        
        if [ "$dashboard_running" = "no" ]; then
            log "⚠️ Dashboard container não está rodando (tentativa $i)"
            log "Verificando logs do dashboard..."
            docker logs academia-dashboard-prod || true
            log "Tentando reiniciar dashboard..."
            docker-compose -f $COMPOSE_FILE restart academia-dashboard
            sleep 20
        fi
        
        if [ "$api_running" = "no" ]; then
            log "⚠️ API container não está rodando (tentativa $i)"
            log "Verificando logs da API..."
            docker logs academia-data-api-prod || true
            log "Tentando reiniciar API..."
            docker-compose -f $COMPOSE_FILE restart data-api
            sleep 20
        fi
        
        # Se ambos estão rodando, sair do loop
        if [ "$dashboard_running" = "yes" ] && [ "$api_running" = "yes" ]; then
            log "✅ Todos os containers estão rodando!"
            break
        fi
        
        sleep 15
    done
    
    # Verificação final
    log "🎯 STATUS FINAL DOS CONTAINERS:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Testar se a aplicação está respondendo
    log "🧪 TESTANDO APLICAÇÃO..."
    sleep 10
    
    # Testar API
    if curl -s http://localhost:3000/health > /dev/null; then
        log "✅ API RESPONDENDO EM http://localhost:3000"
    else
        log "⚠️ API não está respondendo na porta 3000"
    fi
    
    # Testar Dashboard
    if curl -s http://localhost > /dev/null; then
        log "✅ DASHBOARD RESPONDENDO EM http://localhost"
    else
        log "⚠️ Dashboard não está respondendo na porta 80"
    fi
    
    # Verificar portas abertas
    log "Verificando portas abertas..."
    netstat -tlnp | grep -E ":(80|3000)" || true
    
    log "Aplicação iniciada com sucesso!"
else
    log "Projeto não encontrado ou docker-compose.prod.yml ausente"
    log "Deploy manual será necessário"
fi

# Criar serviço systemd para containers
log "Criando serviço systemd para containers..."
cat > /etc/systemd/system/academia-dashboard.service << 'SERVICE_EOF'
[Unit]
Description=Academia Dashboard Containers
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/academia-dashboard/web-site
ExecStart=/usr/local/bin/docker-compose -f docker-compose-fixed.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose-fixed.yml down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Habilitar e iniciar o serviço
systemctl daemon-reload
systemctl enable academia-dashboard.service
log "✅ Serviço systemd criado e habilitado"

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
docker-compose -f docker-compose-fixed.yml down
docker-compose -f docker-compose-fixed.yml up -d --build

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