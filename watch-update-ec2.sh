#!/bin/bash

# ========================================
# SCRIPT DE MONITORAMENTO EM TEMPO REAL
# ========================================

echo "👁️ MONITORAMENTO EM TEMPO REAL"
echo "========================================"

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Funções
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
update() { echo -e "${PURPLE}🔄 $1${NC}"; }

# Configurações
PROJECT_DIR="/home/ubuntu/academia-dashboard"
WEB_DIR="$PROJECT_DIR/web-site"
CHECK_INTERVAL=15  # Verificar a cada 15 segundos

# Função para atualizar sistema
update_system() {
    update "Atualizando sistema..."
    
    cd "$PROJECT_DIR" || return 1
    
    # Fazer pull
    git pull origin main
    if [ $? -ne 0 ]; then
        error "Falha no git pull!"
        return 1
    fi
    
    # Reiniciar containers
    cd "$WEB_DIR"
    docker-compose -f docker-compose.prod.yml restart
    
    # Aguardar
    sleep 10
    
    success "Sistema atualizado!"
    return 0
}

# Função para verificar alterações
check_for_updates() {
    cd "$PROJECT_DIR" || return 1
    
    # Buscar alterações
    git fetch origin main > /dev/null 2>&1
    
    # Comparar commits
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        return 0  # Há alterações
    else
        return 1  # Sem alterações
    fi
}

# Função para mostrar status
show_status() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}📊 STATUS DO SISTEMA${NC}"
    echo "========================================"
    
    # IP público
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")
    
    echo -e "${GREEN}🌐 URLs:${NC}"
    echo -e "   http://$PUBLIC_IP/login.html"
    echo -e "   http://$PUBLIC_IP/admin.html"
    echo -e "   http://$PUBLIC_IP/cashier.html"
    
    echo ""
    echo -e "${GREEN}🐳 Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo -e "${GREEN}⏰ Última verificação:${NC} $(date '+%H:%M:%S')"
    echo ""
}

# Função para capturar Ctrl+C
cleanup() {
    echo ""
    info "Parando monitoramento..."
    success "Monitoramento finalizado!"
    exit 0
}

# Configurar trap
trap cleanup SIGINT SIGTERM

# Verificar se está no diretório correto
if [ ! -d "$PROJECT_DIR" ]; then
    error "Diretório do projeto não encontrado!"
    info "Execute primeiro: ./quick-update-ec2.sh"
    exit 1
fi

# Mostrar status inicial
show_status

info "Iniciando monitoramento automático..."
info "Verificando alterações a cada $CHECK_INTERVAL segundos"
info "Pressione Ctrl+C para parar"
echo ""

# Loop principal
while true; do
    if check_for_updates; then
        update "Alterações detectadas!"
        update_system
        show_status
    else
        info "Sistema atualizado (verificação em $CHECK_INTERVAL segundos)"
    fi
    
    sleep $CHECK_INTERVAL
done


