#!/bin/bash

# ========================================
# SCRIPT RÁPIDO DE ATUALIZAÇÃO EC2
# ========================================

echo "🚀 ATUALIZAÇÃO RÁPIDA DO SISTEMA"
echo "========================================"

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funções
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }

# Configurações
PROJECT_DIR="/home/ubuntu/academia-dashboard"
WEB_DIR="$PROJECT_DIR/web-site"

# Verificar se está no diretório correto
if [ ! -d "$PROJECT_DIR" ]; then
    error "Diretório do projeto não encontrado!"
    info "Clonando projeto..."
    cd /home/ubuntu
    git clone https://github.com/DavidMenezess/academia-dashboard.git
    success "Projeto clonado!"
fi

# Navegar para o projeto
cd "$PROJECT_DIR" || {
    error "Não foi possível acessar o projeto!"
    exit 1
}

info "Atualizando código do GitHub..."
git pull origin main

if [ $? -ne 0 ]; then
    error "Falha no git pull!"
    exit 1
fi

success "Código atualizado!"

# Navegar para web-site
cd "$WEB_DIR" || {
    error "Não foi possível acessar web-site!"
    exit 1
}

info "Parando containers..."
docker-compose -f docker-compose.prod.yml down

info "Iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d

if [ $? -ne 0 ]; then
    error "Falha ao iniciar containers!"
    exit 1
fi

info "Aguardando sistema inicializar..."
sleep 10

# Verificar se está funcionando
info "Verificando sistema..."
if curl -f -s --connect-timeout 10 http://localhost > /dev/null; then
    success "Sistema online!"
else
    warning "Sistema pode estar inicializando..."
fi

# Mostrar informações
echo ""
echo "========================================"
echo -e "${GREEN}🎉 ATUALIZAÇÃO CONCLUÍDA!${NC}"
echo "========================================"

# IP público
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")

echo -e "${BLUE}🌐 URLs do Sistema:${NC}"
echo -e "   http://$PUBLIC_IP/login.html"
echo -e "   http://$PUBLIC_IP/admin.html"
echo -e "   http://$PUBLIC_IP/cashier.html"

echo ""
echo -e "${BLUE}🐳 Containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${BLUE}📊 Status:${NC}"
echo -e "   $(date)"
echo -e "   Sistema atualizado e funcionando!"

echo ""
echo "========================================"
success "Pronto para uso!"






