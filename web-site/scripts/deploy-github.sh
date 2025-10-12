#!/bin/bash

# 🚀 Script de Deploy Automatizado via GitHub
# Deploy Academia Dashboard na AWS usando repositório GitHub

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configurações
PROJECT_NAME="academia-dashboard"
PROJECT_DIR="/home/ubuntu/$PROJECT_NAME"

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🏋️ ACADEMIA DASHBOARD                     ║"
echo "║                   Deploy via GitHub                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Solicitar URL do repositório
echo -e "${YELLOW}"
echo "📝 Digite a URL do seu repositório GitHub:"
echo "Exemplo: https://github.com/SEU-USERNAME/academia-dashboard.git"
echo -e "${NC}"

read -p "URL do repositório: " GITHUB_REPO

if [ -z "$GITHUB_REPO" ]; then
    error "URL do repositório é obrigatória!"
    exit 1
fi

log "Repositório: $GITHUB_REPO"

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    error "Não execute como root. Use: sudo su - ubuntu"
    exit 1
fi

# Atualizar sistema
log "Atualizando sistema..."
sudo apt update -y

# Instalar dependências essenciais
log "Instalando dependências..."
sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Instalar Docker
if ! command -v docker &> /dev/null; then
    log "Instalando Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker ubuntu
    success "Docker instalado com sucesso!"
else
    success "Docker já está instalado"
fi

# Instalar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log "Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    success "Docker Compose instalado com sucesso!"
else
    success "Docker Compose já está instalado"
fi

# Configurar projeto
log "Configurando projeto..."

# Se o diretório não existir, clonar do GitHub
if [ ! -d "$PROJECT_DIR" ]; then
    log "Clonando projeto do GitHub..."
    git clone "$GITHUB_REPO" "$PROJECT_DIR"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        error "Falha ao clonar repositório do GitHub!"
        error "Verifique se o repositório existe e está acessível"
        error "URL: $GITHUB_REPO"
        exit 1
    fi
else
    log "Atualizando projeto do GitHub..."
    cd "$PROJECT_DIR"
    git pull origin main || git pull origin master || warning "Não foi possível atualizar via Git"
fi

# Navegar para o diretório do projeto
cd "$PROJECT_DIR/web-site"

# Verificar se os arquivos necessários existem
required_files=("Dockerfile" "docker-compose.prod.yml" "src/index.html")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        error "Arquivo necessário não encontrado: $file"
        error "Verifique se o repositório GitHub está correto"
        error "Estrutura esperada: web-site/Dockerfile, web-site/docker-compose.aws.yml, etc."
        exit 1
    fi
done

success "Todos os arquivos necessários encontrados"

# Parar containers existentes
log "Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down || true

# Limpar imagens antigas (opcional)
log "Limpando imagens antigas..."
docker system prune -f || true

# Construir e iniciar containers
log "Construindo e iniciando containers..."
docker-compose -f docker-compose.prod.yml up --build -d

# Aguardar containers iniciarem
log "Aguardando containers iniciarem..."
sleep 15

# Verificar status dos containers
log "Verificando status dos containers..."
if docker ps | grep -q "academia-dashboard-prod"; then
    success "Dashboard container está rodando"
else
    error "Dashboard container não está rodando"
    docker logs academia-dashboard-prod
    exit 1
fi

if docker ps | grep -q "academia-data-api-prod"; then
    success "API container está rodando"
else
    error "API container não está rodando"
    docker logs academia-data-api-prod
    exit 1
fi

# Testar endpoints
log "Testando endpoints..."

# Obter IP público
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

# Testar dashboard
if curl -f -s "http://localhost/health" > /dev/null; then
    success "Dashboard health check: OK"
else
    warning "Dashboard health check: FALHOU"
fi

# Testar API
if curl -f -s "http://localhost:3000/health" > /dev/null; then
    success "API health check: OK"
else
    warning "API health check: FALHOU"
fi

# Configurar firewall básico
log "Configurando firewall..."
sudo ufw --force enable || true
sudo ufw allow 22/tcp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true
sudo ufw allow 3000/tcp || true

# Instalar e configurar Nginx (proxy reverso)
if ! command -v nginx &> /dev/null; then
    log "Instalando Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
fi

# Configurar proxy reverso
log "Configurando proxy reverso..."
sudo tee /etc/nginx/sites-available/academia-dashboard << EOF
server {
    listen 80;
    server_name _;
    
    # Dashboard
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Ativar configuração
sudo ln -sf /etc/nginx/sites-available/academia-dashboard /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

# Configurar backup automático
log "Configurando backup automático..."
mkdir -p /home/ubuntu/backups

cat > /home/ubuntu/backup-dashboard.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/ubuntu/backups"

# Backup de dados
docker cp academia-dashboard-aws:/app/data "$BACKUP_DIR/data_$DATE" 2>/dev/null || true

# Backup de logs
docker logs academia-dashboard-prod > "$BACKUP_DIR/logs_$DATE.log" 2>/dev/null || true

# Limpar backups antigos (manter últimos 7 dias)
find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
find "$BACKUP_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
EOF

chmod +x /home/ubuntu/backup-dashboard.sh

# Configurar cron para backup diário
(crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup-dashboard.sh") | crontab -

# Configurar monitoramento básico
log "Configurando monitoramento..."
cat > /home/ubuntu/monitor-dashboard.sh << 'EOF'
#!/bin/bash
# Script de monitoramento básico

# Verificar se containers estão rodando
if ! docker ps | grep -q "academia-dashboard-aws"; then
    echo "❌ Dashboard container não está rodando - $(date)" >> /var/log/dashboard-monitor.log
    # Reiniciar container
    cd /home/ubuntu/academia-dashboard/web-site
    docker-compose -f docker-compose.prod.yml up -d academia-dashboard
fi

if ! docker ps | grep -q "academia-data-api-aws"; then
    echo "❌ API container não está rodando - $(date)" >> /var/log/dashboard-monitor.log
    # Reiniciar container
    cd /home/ubuntu/academia-dashboard/web-site
    docker-compose -f docker-compose.prod.yml up -d data-api
fi
EOF

chmod +x /home/ubuntu/monitor-dashboard.sh

# Configurar cron para monitoramento a cada 5 minutos
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/monitor-dashboard.sh") | crontab -

# Finalizar
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🎉 DEPLOY CONCLUÍDO! 🎉                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

success "Deploy realizado com sucesso!"
log "🌐 Dashboard: http://$PUBLIC_IP"
log "🔧 API: http://$PUBLIC_IP:3000"
log "📊 Health Check: http://$PUBLIC_IP/health"

log "📋 Comandos úteis:"
echo "  - Ver containers: docker ps"
echo "  - Ver logs: docker logs academia-dashboard-prod"
echo "  - Parar: docker-compose -f docker-compose.prod.yml down"
echo "  - Reiniciar: docker-compose -f docker-compose.prod.yml restart"
echo "  - Backup: /home/ubuntu/backup-dashboard.sh"
echo "  - Atualizar: cd $PROJECT_DIR && git pull && docker-compose -f docker-compose.prod.yml up --build -d"

log "🔒 Próximos passos recomendados:"
echo "  1. Configurar domínio personalizado"
echo "  2. Instalar SSL com Let's Encrypt"
echo "  3. Configurar CloudWatch para monitoramento"
echo "  4. Configurar backup automático para S3"

success "Seu dashboard da academia está online e acessível para o mundo! 🌍"
