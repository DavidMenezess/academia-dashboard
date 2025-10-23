#!/bin/bash

# ========================================
# MOVER SCRIPTS DE CORREÇÃO PARA FORA DO CONTAINER
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
║   MOVER SCRIPTS DE CORREÇÃO PARA FORA        ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 1. NAVEGAR PARA O PROJETO
log "Navegando para o projeto..."
cd ~/academia-dashboard/web-site

# 2. CRIAR DIRETÓRIO PARA SCRIPTS DE HOST
log "Criando diretório para scripts de host..."
mkdir -p ~/academia-dashboard-scripts

# 3. MOVER SCRIPTS DE CORREÇÃO
log "Movendo scripts de correção para fora do container..."

# Mover complete-fix.sh
if [ -f "scripts/complete-fix.sh" ]; then
    cp scripts/complete-fix.sh ~/academia-dashboard-scripts/
    log "✅ complete-fix.sh movido"
fi

# Mover definitive-fix.sh
if [ -f "scripts/definitive-fix.sh" ]; then
    cp scripts/definitive-fix.sh ~/academia-dashboard-scripts/
    log "✅ definitive-fix.sh movido"
fi

# Mover ensure-containers-working.sh
if [ -f "scripts/ensure-containers-working.sh" ]; then
    cp scripts/ensure-containers-working.sh ~/academia-dashboard-scripts/
    log "✅ ensure-containers-working.sh movido"
fi

# Mover test-api-only.sh
if [ -f "scripts/test-api-only.sh" ]; then
    cp scripts/test-api-only.sh ~/academia-dashboard-scripts/
    log "✅ test-api-only.sh movido"
fi

# 4. REMOVER SCRIPTS DE CORREÇÃO DO CONTAINER
log "Removendo scripts de correção do container..."
rm -f scripts/complete-fix.sh
rm -f scripts/definitive-fix.sh
rm -f scripts/ensure-containers-working.sh
rm -f scripts/test-api-only.sh

# 5. CRIAR SCRIPT DE CORREÇÃO RÁPIDA NO HOST
log "Criando script de correção rápida no host..."
cat > ~/academia-dashboard-scripts/quick-fix.sh << 'EOF'
#!/bin/bash

# ========================================
# CORREÇÃO RÁPIDA DOS CONTAINERS
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
║   CORREÇÃO RÁPIDA DOS CONTAINERS            ║
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

# 1. NAVEGAR PARA O PROJETO
log "Navegando para o projeto..."
cd ~/academia-dashboard/web-site

# 2. PARAR CONTAINERS
log "Parando containers..."
run_docker "compose -f docker-compose-fixed.yml down" || true

# 3. LIMPAR SISTEMA
log "Limpando containers e volumes..."
run_docker "system prune -af"
run_docker "volume prune -f"

# 4. FAZER BUILD E INICIAR
log "Fazendo build e iniciando containers..."
run_docker "compose -f docker-compose-fixed.yml build --no-cache"
run_docker "compose -f docker-compose-fixed.yml up -d"

# 5. AGUARDAR INICIALIZAÇÃO
log "Aguardando 30 segundos..."
sleep 30

# 6. VERIFICAR STATUS
log "Status dos containers:"
run_docker "ps"

# 7. TESTAR CONECTIVIDADE
log "Testando aplicação..."
if curl -s http://localhost > /dev/null; then
    success "✅ Dashboard funcionando!"
else
    warn "⚠️ Dashboard não respondeu"
fi

if curl -s http://localhost:3000/health > /dev/null; then
    success "✅ API funcionando!"
else
    warn "⚠️ API não respondeu"
fi

success "Correção rápida concluída!"
EOF

chmod +x ~/academia-dashboard-scripts/quick-fix.sh

# 6. CRIAR ALIASES ÚTEIS
log "Criando aliases úteis..."
cat >> ~/.bashrc << 'EOF'

# Aliases para Academia Dashboard
alias dashboard-logs="docker logs -f academia-dashboard-prod"
alias api-logs="docker logs -f academia-data-api-prod"
alias dashboard-status="docker ps | grep academia"
alias dashboard-restart="cd ~/academia-dashboard/web-site && docker-compose -f docker-compose-fixed.yml restart"
alias dashboard-stop="cd ~/academia-dashboard/web-site && docker-compose -f docker-compose-fixed.yml down"
alias dashboard-start="cd ~/academia-dashboard/web-site && docker-compose -f docker-compose-fixed.yml up -d"
alias dashboard-fix="~/academia-dashboard-scripts/quick-fix.sh"
EOF

# 7. MOSTRAR INFORMAÇÕES
success "Scripts movidos com sucesso!"
echo ""
log "Scripts de correção agora estão em: ~/academia-dashboard-scripts/"
echo ""
log "Comandos úteis:"
echo "  dashboard-logs     - Ver logs do dashboard"
echo "  api-logs          - Ver logs da API"
echo "  dashboard-status  - Ver status dos containers"
echo "  dashboard-restart - Reiniciar containers"
echo "  dashboard-stop    - Parar containers"
echo "  dashboard-start   - Iniciar containers"
echo "  dashboard-fix     - Correção rápida"
echo ""
log "Para aplicar as mudanças, execute:"
echo "  source ~/.bashrc"
echo ""

success "Configuração concluída!"
