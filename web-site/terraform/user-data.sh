#!/bin/bash

# ========================================
# SCRIPT DE INICIALIZAÇÃO - USER DATA
# Academia Dashboard - AWS Free Tier
# ========================================

set -e  # Parar em caso de erro

# Variáveis do template
PROJECT_NAME="${project_name}"
GITHUB_REPO="${github_repo}"
API_PORT="${api_port}"
ENVIRONMENT="${environment}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "$${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]$${NC} $1"
}

error() {
    echo -e "$${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERRO:$${NC} $1"
}

warning() {
    echo -e "$${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] AVISO:$${NC} $1"
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
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log "Docker Compose $${DOCKER_COMPOSE_VERSION} instalado!"

# Configurar usuário ubuntu para usar Docker
usermod -aG docker ubuntu

# Configurar Firewall UFW
log "Configurando firewall UFW..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow $${API_PORT}/tcp  # API
ufw --force reload
log "Firewall configurado!"

# Configurar Fail2ban para proteção SSH
log "Configurando Fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Criar diretório do projeto
PROJECT_DIR="/home/ubuntu/$${PROJECT_NAME}"
log "Criando diretório do projeto: $${PROJECT_DIR}"
mkdir -p $${PROJECT_DIR}
chown -R ubuntu:ubuntu $${PROJECT_DIR}

# Clonar repositório se fornecido
if [ -n "$${GITHUB_REPO}" ] && [ "$${GITHUB_REPO}" != "" ]; then
    log "Clonando repositório: $${GITHUB_REPO}"
    cd /home/ubuntu
    sudo -u ubuntu git clone $${GITHUB_REPO} $${PROJECT_NAME} || {
        error "Falha ao clonar repositório. Continuando sem código fonte..."
    }
else
    warning "URL do repositório GitHub não fornecida"
    warning "Você precisará fazer deploy manual do código"
fi

# Se o projeto foi clonado, fazer deploy
if [ -d "$${PROJECT_DIR}" ] && [ -f "$${PROJECT_DIR}/docker-compose.prod.yml" ]; then
    log "Iniciando deploy da aplicação..."
    cd $${PROJECT_DIR}
    
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
  "ultima_atualizacao": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    fi
    
    # Ajustar permissões
    chown -R ubuntu:ubuntu .
    
    # Fazer build e iniciar containers
    log "Executando docker-compose..."
    
    # Verificar se estamos no diretório correto
    pwd
    ls -la
    
    # Verificar se docker-compose está disponível
    if [ ! -f "docker-compose.prod.yml" ]; then
        error "docker-compose.prod.yml não encontrado!"
        error "Diretório atual: $(pwd)"
        error "Arquivos disponíveis:"
        ls -la
        exit 1
    fi
    
    # Parar containers existentes
    log "Parando containers existentes..."
    docker-compose -f docker-compose.prod.yml down || true
    
    # Aguardar um momento
    sleep 3
    
    # Executar docker-compose
    log "Iniciando containers com docker-compose..."
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
    log "Status final dos containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Criar script de inicialização manual
    log "Criando script de inicialização manual..."
    cat > /home/ubuntu/start-dashboard.sh << 'SCRIPT_EOF'
#!/bin/bash
cd /home/ubuntu/academia-dashboard/web-site
docker-compose -f docker-compose.prod.yml up -d --build
echo "Dashboard iniciado!"
SCRIPT_EOF
    
    chmod +x /home/ubuntu/start-dashboard.sh
    log "✅ Script de inicialização manual criado: /home/ubuntu/start-dashboard.sh"
    
    log "Aplicação iniciada com sucesso!"
else
    warning "Projeto não encontrado ou docker-compose.prod.yml ausente"
    warning "Deploy manual será necessário"
fi

# FORÇAR INICIALIZAÇÃO DOS CONTAINERS
log "🔧 FORÇANDO INICIALIZAÇÃO DOS CONTAINERS..."
cd /home/ubuntu/academia-dashboard/web-site

# Verificar se estamos no diretório correto
log "Diretório atual: $(pwd)"
log "Arquivos disponíveis:"
ls -la

# Verificar se docker-compose.prod.yml existe
if [ -f "docker-compose.prod.yml" ]; then
    log "✅ docker-compose.prod.yml encontrado!"
    
    # Parar containers existentes
    log "Parando containers existentes..."
    docker-compose -f docker-compose.prod.yml down || true
    
    # Aguardar um momento
    sleep 3
    
    # Executar docker-compose
    log "🚀 INICIANDO CONTAINERS COM DOCKER-COMPOSE..."
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
    
else
    error "❌ docker-compose.prod.yml NÃO ENCONTRADO!"
    error "Diretório atual: $(pwd)"
    error "Arquivos disponíveis:"
    ls -la
fi

# Criar script de atualização
log "Criando script de atualização..."
cat > /usr/local/bin/update-academia-dashboard << 'SCRIPT_EOF'
#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/${project_name}"

echo "Atualizando Academia Dashboard..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Erro: Projeto não encontrado em $PROJECT_DIR"
    exit 1
fi

cd $PROJECT_DIR

# Backup dos dados
echo "Criando backup..."
BACKUP_DIR="$PROJECT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp -r data $BACKUP_DIR/

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

PROJECT_DIR="/home/ubuntu/${project_name}"
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

# Instalar AWS CloudWatch Agent (opcional - Free Tier limitado)
# Descomente se quiser monitoramento no CloudWatch
# log "Instalando CloudWatch Agent..."
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# dpkg -i -E ./amazon-cloudwatch-agent.deb
# rm amazon-cloudwatch-agent.deb

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
- API: http://$(curl -s ifconfig.me):${api_port}
- Health Check: http://$(curl -s ifconfig.me)/health

📁 Diretórios:
- Projeto: /home/ubuntu/${project_name}
- Logs: /var/log/user-data.log
- Backups: /home/ubuntu/backups

🔧 Scripts Úteis:
- Atualizar: sudo update-academia-dashboard
- Backup: sudo backup-academia-dashboard
- Ver logs: docker logs -f academia-dashboard-prod
- Ver containers: docker ps
- Reiniciar: cd /home/ubuntu/${project_name} && docker-compose -f docker-compose.prod.yml restart

🔒 Segurança:
- Firewall UFW: Ativo
- Fail2ban: Ativo
- SSH: Porta 22

📊 Monitoramento:
- Status containers: docker ps
- Logs aplicação: tail -f /home/ubuntu/${project_name}/logs/*.log
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


