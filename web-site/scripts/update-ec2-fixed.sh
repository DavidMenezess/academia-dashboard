#!/bin/bash

# ========================================
# ATUALIZAÇÃO EC2 COM CORREÇÃO DE PERMISSÕES
# Academia Dashboard - AWS EC2
# ========================================

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1"; }
success() { echo -e "${BLUE}[SUCESSO]${NC} $1"; }

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   ATUALIZAÇÃO EC2 - ACADEMIA DASHBOARD      ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Função para executar comandos Docker com fallback
run_docker() {
    local cmd="$1"
    if docker $cmd 2>/dev/null; then
        return 0
    else
        warn "Executando com sudo: $cmd"
        sudo docker $cmd
        return $?
    fi
}

run_docker_compose() {
    local cmd="$1"
    if docker-compose $cmd 2>/dev/null; then
        return 0
    else
        warn "Executando com sudo: $cmd"
        sudo docker-compose $cmd
        return $?
    fi
}

# 1. Navegar para o diretório correto
log "Navegando para o diretório do projeto..."
cd ~/academia-dashboard/web-site

# 2. Parar containers existentes
log "Parando containers existentes..."
run_docker_compose "-f docker-compose.prod.yml down" || true

# 3. Limpar containers e volumes
log "Limpando containers e volumes..."
run_docker "system prune -f" || true

# 4. Fazer pull das imagens mais recentes
log "Atualizando imagens Docker..."
run_docker "pull node:18-alpine" || true
run_docker "pull nginx:alpine" || true

# 5. Fazer build e iniciar containers
log "Fazendo build e iniciando containers..."
run_docker_compose "-f docker-compose.prod.yml up --build -d"

# 6. Aguardar inicialização
log "Aguardando 30 segundos para inicialização completa..."
sleep 30

# 7. Verificar status dos containers
log "Verificando status dos containers..."
run_docker "ps"

# 8. Verificar logs se houver problemas
log "Verificando logs dos containers..."
if ! run_docker "ps --format 'table {{.Names}}\t{{.Status}}' | grep -q 'Up'"; then
    warn "Alguns containers podem não estar funcionando. Verificando logs..."
    run_docker "logs academia-dashboard-prod" || true
    run_docker "logs academia-data-api-prod" || true
fi

# 9. Testar conectividade
log "Testando conectividade..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    success "Dashboard está funcionando!"
else
    warn "Dashboard pode não estar respondendo ainda. Aguarde mais alguns minutos."
fi

success "Atualização concluída!"
echo ""
log "Para verificar o status:"
echo "  docker ps"
echo "  docker logs academia-dashboard-prod"
echo ""
log "Para acessar o dashboard:"
echo "  http://$(curl -s ifconfig.me)"
echo ""
