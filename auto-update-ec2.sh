#!/bin/bash

# ========================================
# SCRIPT DE ATUALIZACAO AUTOMATICA EC2
# ========================================

echo "🚀 INICIANDO SISTEMA DE ATUALIZAÇÃO AUTOMÁTICA"
echo "========================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_update() { echo -e "${PURPLE}[UPDATE]${NC} $1"; }

# Configurações
PROJECT_DIR="/home/ubuntu/academia-dashboard"
WEB_DIR="$PROJECT_DIR/web-site"
GITHUB_REPO="https://github.com/DavidMenezess/academia-dashboard.git"
CHECK_INTERVAL=30  # Verificar a cada 30 segundos
MAX_RETRIES=3

# Função para atualizar sistema
update_system() {
    log_update "🔄 Iniciando atualização do sistema..."
    
    # Navegar para o projeto
    cd "$PROJECT_DIR" || {
        log_error "Não foi possível acessar o diretório do projeto!"
        return 1
    }
    
    # Fazer backup do estado atual
    log_info "📦 Fazendo backup do estado atual..."
    git stash push -m "Backup antes da atualização $(date)"
    
    # Buscar alterações
    log_info "📥 Buscando alterações do GitHub..."
    git fetch origin main
    
    # Verificar se há alterações
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log_info "✅ Sistema já está atualizado!"
        return 0
    fi
    
    log_update "🔄 Novas alterações encontradas! Atualizando..."
    
    # Fazer pull das alterações
    git pull origin main
    if [ $? -ne 0 ]; then
        log_error "❌ Falha no git pull!"
        return 1
    fi
    
    log_success "✅ Código atualizado com sucesso!"
    
    # Navegar para web-site
    cd "$WEB_DIR" || {
        log_error "Não foi possível acessar o diretório web-site!"
        return 1
    }
    
    # Parar containers
    log_info "⏹️ Parando containers..."
    docker-compose -f docker-compose.prod.yml down
    
    # Aguardar um momento
    sleep 5
    
    # Iniciar containers
    log_info "▶️ Iniciando containers..."
    docker-compose -f docker-compose.prod.yml up -d
    
    if [ $? -ne 0 ]; then
        log_error "❌ Falha ao iniciar containers!"
        return 1
    fi
    
    # Aguardar inicialização
    log_info "⏳ Aguardando sistema inicializar..."
    sleep 15
    
    # Verificar se está funcionando
    log_info "🔍 Verificando se o sistema está online..."
    for i in {1..5}; do
        if curl -f -s --connect-timeout 10 http://localhost > /dev/null; then
            log_success "✅ Sistema online e funcionando!"
            break
        else
            log_warning "⏳ Aguardando sistema inicializar... (tentativa $i/5)"
            sleep 10
        fi
    done
    
    # Mostrar status
    show_status
    
    return 0
}

# Função para mostrar status
show_status() {
    echo ""
    echo "========================================"
    echo -e "${CYAN}📊 STATUS DO SISTEMA${NC}"
    echo "========================================"
    
    # IP público
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")
    
    echo -e "${GREEN}🌐 URLs do Sistema:${NC}"
    echo -e "   ${BLUE}Login:${NC} http://$PUBLIC_IP/login.html"
    echo -e "   ${BLUE}Admin:${NC} http://$PUBLIC_IP/admin.html"
    echo -e "   ${BLUE}Caixa:${NC} http://$PUBLIC_IP/cashier.html"
    
    echo ""
    echo -e "${GREEN}🐳 Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
    
    echo ""
    echo -e "${GREEN}💾 Uso de Disco:${NC}"
    df -h / | tail -1 | awk '{print "   Uso: " $3 " / " $2 " (" $5 " usado)"}'
    
    echo ""
    echo -e "${GREEN}🧠 Uso de Memória:${NC}"
    free -h | grep "Mem:" | awk '{print "   Uso: " $3 " / " $2}'
    
    echo ""
}

# Função para verificar saúde do sistema
health_check() {
    log_info "🔍 Verificando saúde do sistema..."
    
    # Verificar containers
    if ! docker ps | grep -q "web-site-academia-dashboard"; then
        log_warning "⚠️ Container principal não está rodando!"
        return 1
    fi
    
    # Verificar se responde HTTP
    if ! curl -f -s --connect-timeout 5 http://localhost > /dev/null; then
        log_warning "⚠️ Sistema não está respondendo HTTP!"
        return 1
    fi
    
    log_success "✅ Sistema saudável!"
    return 0
}

# Função para reiniciar sistema
restart_system() {
    log_update "🔄 Reiniciando sistema..."
    
    cd "$WEB_DIR" || return 1
    
    docker-compose -f docker-compose.prod.yml restart
    
    sleep 15
    
    if health_check; then
        log_success "✅ Sistema reiniciado com sucesso!"
        return 0
    else
        log_error "❌ Falha ao reiniciar sistema!"
        return 1
    fi
}

# Função para limpar sistema
cleanup_system() {
    log_info "🧹 Limpando sistema..."
    
    cd "$WEB_DIR" || return 1
    
    # Parar containers
    docker-compose -f docker-compose.prod.yml down
    
    # Limpar containers órfãos
    docker container prune -f
    
    # Limpar imagens não utilizadas
    docker image prune -f
    
    # Limpar volumes não utilizados
    docker volume prune -f
    
    log_success "✅ Sistema limpo!"
}

# Função principal de monitoramento
monitor_loop() {
    log_info "🔄 Iniciando monitoramento automático..."
    log_info "📅 Verificando alterações a cada $CHECK_INTERVAL segundos"
    log_info "⏹️ Pressione Ctrl+C para parar"
    echo ""
    
    while true; do
        # Verificar se o sistema está saudável
        if ! health_check; then
            log_warning "⚠️ Sistema não saudável, tentando reiniciar..."
            restart_system
        fi
        
        # Verificar atualizações
        cd "$PROJECT_DIR" || {
            log_error "Não foi possível acessar o diretório do projeto!"
            sleep $CHECK_INTERVAL
            continue
        }
        
        git fetch origin main > /dev/null 2>&1
        
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            log_update "🔄 Alterações detectadas! Iniciando atualização..."
            update_system
        else
            log_info "✅ Sistema atualizado (verificação em $CHECK_INTERVAL segundos)"
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Menu principal
show_menu() {
    echo ""
    echo "========================================"
    echo -e "${CYAN}🎛️ MENU DE CONTROLE${NC}"
    echo "========================================"
    echo "1. 🔄 Atualizar sistema agora"
    echo "2. 🔍 Verificar status"
    echo "3. 🔄 Reiniciar sistema"
    echo "4. 🧹 Limpar sistema"
    echo "5. 🔄 Iniciar monitoramento automático"
    echo "6. ❌ Sair"
    echo "========================================"
    echo -n "Escolha uma opção (1-6): "
}

# Função para capturar Ctrl+C
cleanup_on_exit() {
    echo ""
    log_info "🛑 Parando monitoramento..."
    log_info "👋 Sistema de atualização automática finalizado!"
    exit 0
}

# Configurar trap para Ctrl+C
trap cleanup_on_exit SIGINT SIGTERM

# Verificar se está no diretório correto
if [ ! -d "$PROJECT_DIR" ]; then
    log_error "❌ Diretório do projeto não encontrado: $PROJECT_DIR"
    log_info "💡 Certifique-se de que está executando na EC2 com o projeto clonado"
    exit 1
fi

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    log_error "❌ Docker não está rodando!"
    log_info "💡 Execute: sudo systemctl start docker"
    exit 1
fi

# Mostrar status inicial
show_status

# Menu interativo
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            update_system
            ;;
        2)
            show_status
            ;;
        3)
            restart_system
            ;;
        4)
            cleanup_system
            ;;
        5)
            monitor_loop
            ;;
        6)
            log_info "👋 Saindo..."
            exit 0
            ;;
        *)
            log_error "❌ Opção inválida!"
            ;;
    esac
    
    echo ""
    echo "Pressione Enter para continuar..."
    read -r
done






