#!/bin/bash

# ========================================
# SCRIPT DE ATUALIZACAO PARA EC2 (Linux)
# ========================================

echo "========================================"
echo "    ATUALIZACAO DO SISTEMA NA EC2"
echo "========================================"
echo ""

# Definir cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

try {
    log_info "Navegando para o diretório do projeto..."
    cd /home/ubuntu/academia-dashboard
    
    if [ $? -ne 0 ]; then
        log_error "Diretório não encontrado!"
        exit 1
    fi
    
    log_info "Verificando status do Git..."
    git status --short
    
    log_info "Fazendo pull das alterações do GitHub..."
    git pull origin main
    
    if [ $? -ne 0 ]; then
        log_error "Falha no git pull!"
        exit 1
    fi
    
    log_success "Código atualizado com sucesso!"
    
    log_info "Navegando para o diretório web-site..."
    cd web-site
    
    log_info "Parando containers..."
    docker-compose -f docker-compose.prod.yml down
    
    log_info "Iniciando containers..."
    docker-compose -f docker-compose.prod.yml up -d
    
    if [ $? -ne 0 ]; then
        log_error "Falha ao iniciar containers!"
        exit 1
    fi
    
    log_success "Containers reiniciados com sucesso!"
    
    log_info "Verificando status dos containers..."
    docker ps
    
    log_info "Aguardando sistema inicializar..."
    sleep 10
    
    log_info "Verificando se o sistema está online..."
    if curl -f -s --connect-timeout 10 http://localhost > /dev/null; then
        log_success "Sistema online e funcionando!"
    else
        log_warning "Sistema pode estar inicializando..."
    fi
    
    echo ""
    echo "========================================"
    echo -e "${GREEN}    ATUALIZACAO CONCLUIDA!${NC}"
    echo "========================================"
    echo ""
    echo -e "${BLUE}🌐 URLs do sistema:${NC}"
    echo -e "   ${GREEN}Login:${NC} http://$(curl -s ifconfig.me)/login.html"
    echo -e "   ${GREEN}Admin:${NC} http://$(curl -s ifconfig.me)/admin.html"
    echo -e "   ${GREEN}Caixa:${NC} http://$(curl -s ifconfig.me)/cashier.html"
    echo ""
    echo -e "${BLUE}📊 Status dos containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
} catch {
    log_error "Erro durante a atualização!"
    echo ""
    echo -e "${BLUE}🔧 Soluções possíveis:${NC}"
    echo "   1. Verifique sua conexão com a internet"
    echo "   2. Verifique se o GitHub está acessível"
    echo "   3. Execute 'git status' para verificar o estado"
    echo "   4. Verifique os logs: docker logs web-site-academia-dashboard"
    echo "   5. Reinicie manualmente: docker-compose -f docker-compose.prod.yml restart"
}






