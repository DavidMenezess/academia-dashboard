#!/bin/bash

# ========================================
# DIAGNÓSTICO E CORREÇÃO DE CONTAINERS
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
║   DIAGNÓSTICO DE CONTAINERS                  ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Função para executar comandos Docker
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

# 1. Verificar status dos containers
log "Verificando status dos containers..."
run_docker "ps -a"

echo ""
log "Verificando logs do container academia-dashboard-prod..."
run_docker "logs academia-dashboard-prod --tail 50"

echo ""
log "Verificando logs do container academia-data-api-prod..."
run_docker "logs academia-data-api-prod --tail 50"

# 2. Verificar se os arquivos existem
log "Verificando arquivos do projeto..."
cd ~/academia-dashboard/web-site

echo "Arquivos principais:"
ls -la | grep -E "(Dockerfile|docker-compose|src|api)"

echo ""
echo "Conteúdo da pasta src:"
ls -la src/

echo ""
echo "Conteúdo da pasta api:"
ls -la api/

# 3. Verificar se o Dockerfile está correto
log "Verificando Dockerfile..."
if [ -f "Dockerfile" ]; then
    echo "Dockerfile encontrado:"
    head -20 Dockerfile
else
    error "Dockerfile não encontrado!"
fi

# 4. Verificar docker-compose
log "Verificando docker-compose.prod.yml..."
if [ -f "docker-compose.prod.yml" ]; then
    echo "docker-compose.prod.yml encontrado:"
    cat docker-compose.prod.yml
else
    error "docker-compose.prod.yml não encontrado!"
fi

# 5. Parar containers problemáticos
log "Parando containers problemáticos..."
run_docker "stop academia-dashboard-prod academia-data-api-prod" || true
run_docker "rm academia-dashboard-prod academia-data-api-prod" || true

# 6. Limpar sistema
log "Limpando sistema Docker..."
run_docker "system prune -f"

# 7. Reconstruir containers
log "Reconstruindo containers..."
run_docker "compose -f docker-compose.prod.yml build --no-cache"

# 8. Iniciar containers
log "Iniciando containers..."
run_docker "compose -f docker-compose.prod.yml up -d"

# 9. Aguardar inicialização
log "Aguardando 30 segundos para inicialização..."
sleep 30

# 10. Verificar status final
log "Status final dos containers:"
run_docker "ps"

# 11. Verificar logs finais
log "Logs finais do academia-dashboard-prod:"
run_docker "logs academia-dashboard-prod --tail 20"

log "Logs finais do academia-data-api-prod:"
run_docker "logs academia-data-api-prod --tail 20"

# 12. Testar conectividade
log "Testando conectividade..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    success "Dashboard está funcionando!"
else
    warn "Dashboard pode não estar respondendo. Verificando portas..."
    netstat -tlnp | grep -E ":(80|3000)"
fi

success "Diagnóstico concluído!"
echo ""
log "Para monitorar logs em tempo real:"
echo "  docker logs -f academia-dashboard-prod"
echo "  docker logs -f academia-data-api-prod"
echo ""
log "Para verificar status:"
echo "  docker ps"
echo ""
