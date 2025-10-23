#!/bin/bash

# ========================================
# CORREÇÃO DE CONTAINERS EM RESTART
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
║   CORREÇÃO DE CONTAINERS EM RESTART         ║
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

# 1. Parar todos os containers
log "Parando todos os containers..."
run_docker "stop $(docker ps -q)" 2>/dev/null || true
run_docker "rm $(docker ps -aq)" 2>/dev/null || true

# 2. Limpar sistema completamente
log "Limpando sistema Docker completamente..."
run_docker "system prune -af"
run_docker "volume prune -f"

# 3. Verificar arquivos do projeto
log "Verificando arquivos do projeto..."
cd ~/academia-dashboard/web-site

# Verificar se os arquivos essenciais existem
if [ ! -f "Dockerfile" ]; then
    error "Dockerfile não encontrado!"
    exit 1
fi

if [ ! -f "docker-compose.prod.yml" ]; then
    error "docker-compose.prod.yml não encontrado!"
    exit 1
fi

if [ ! -d "src" ]; then
    error "Pasta src não encontrada!"
    exit 1
fi

if [ ! -d "api" ]; then
    error "Pasta api não encontrada!"
    exit 1
fi

# 4. Verificar permissões
log "Verificando permissões dos arquivos..."
chmod +x docker-entrypoint.sh 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true

# 5. Reconstruir imagem do zero
log "Reconstruindo imagem do zero..."
run_docker "build -t academia-dashboard:latest . --no-cache"

# 6. Verificar se a imagem foi criada
log "Verificando imagens disponíveis..."
run_docker "images | grep academia"

# 7. Iniciar containers um por vez
log "Iniciando container da API primeiro..."
run_docker "run -d --name academia-data-api-prod \
  -p 3000:3000 \
  -v $(pwd)/api:/app \
  -v $(pwd)/data:/app/data \
  -e NODE_ENV=production \
  -e PORT=3000 \
  node:18-alpine \
  sh -c 'cd /app && npm install --production && node server.js'"

# Aguardar API inicializar
log "Aguardando API inicializar..."
sleep 15

# Verificar se API está funcionando
if run_docker "logs academia-data-api-prod --tail 10" | grep -q "API da Academia rodando"; then
    success "API iniciada com sucesso!"
else
    warn "API pode não estar funcionando. Verificando logs..."
    run_docker "logs academia-data-api-prod --tail 20"
fi

# 8. Iniciar container do dashboard
log "Iniciando container do dashboard..."
run_docker "run -d --name academia-dashboard-prod \
  -p 80:80 \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/logs:/var/log/nginx \
  -e NGINX_HOST=localhost \
  -e NGINX_PORT=80 \
  -e NODE_ENV=production \
  academia-dashboard:latest"

# Aguardar dashboard inicializar
log "Aguardando dashboard inicializar..."
sleep 15

# 9. Verificar status final
log "Status final dos containers:"
run_docker "ps"

# 10. Verificar logs finais
log "Logs do dashboard:"
run_docker "logs academia-dashboard-prod --tail 10"

log "Logs da API:"
run_docker "logs academia-data-api-prod --tail 10"

# 11. Testar conectividade
log "Testando conectividade..."
sleep 5

if curl -f http://localhost/health > /dev/null 2>&1; then
    success "✅ Dashboard está funcionando!"
elif curl -f http://localhost:3000/health > /dev/null 2>&1; then
    success "✅ API está funcionando!"
    warn "⚠️  Dashboard pode não estar respondendo na porta 80"
else
    warn "⚠️  Nenhum serviço está respondendo. Verificando portas..."
    netstat -tlnp | grep -E ":(80|3000)" || true
fi

success "Correção concluída!"
echo ""
log "Para monitorar logs:"
echo "  docker logs -f academia-dashboard-prod"
echo "  docker logs -f academia-data-api-prod"
echo ""
log "Para verificar status:"
echo "  docker ps"
echo ""
log "Para acessar:"
echo "  http://$(curl -s ifconfig.me)"
echo ""
