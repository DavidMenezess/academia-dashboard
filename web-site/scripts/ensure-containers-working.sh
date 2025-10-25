#!/bin/bash

# ========================================
# GARANTIR QUE CONTAINERS FUNCIONEM
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
║   GARANTIR QUE CONTAINERS FUNCIONEM          ║
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

# 2. VERIFICAR ARQUIVO DOCKER-COMPOSE
if [ -f "docker-compose-fixed.yml" ]; then
    COMPOSE_FILE="docker-compose-fixed.yml"
elif [ -f "docker-compose.prod.yml" ]; then
    COMPOSE_FILE="docker-compose.prod.yml"
else
    error "Nenhum arquivo docker-compose encontrado!"
    exit 1
fi

log "Usando arquivo: $COMPOSE_FILE"

# 3. PARAR TUDO
log "Parando todos os containers..."
run_docker "compose -f $COMPOSE_FILE down" || true

# 4. LIMPAR SISTEMA
log "Limpando sistema Docker..."
run_docker "system prune -f"
run_docker "volume prune -f"
run_docker "network prune -f"

# 5. CRIAR DADOS INICIAIS
log "Criando dados iniciais..."
mkdir -p data logs api/uploads
cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Força Fitness",
    "endereco": "Rua das Academias, 123 - Centro",
    "telefone": "(11) 99999-9999",
    "email": "contato@forcafitness.com"
  },
  "estatisticas": {
    "total_membros": 150,
    "membros_ativos": 120,
    "receita_mensal": 15000.00,
    "aulas_realizadas": 45,
    "instrutores_ativos": 6
  },
  "ultima_atualizacao": "2025-01-23T00:00:00Z",
  "versao": "1.0.0"
}
EOF

# 6. INSTALAR DEPENDÊNCIAS DA API
if [ -d "api" ]; then
    log "Instalando dependências da API..."
    cd api
    npm install --production
    cd ..
fi

# 7. RECONSTRUIR IMAGENS
log "Reconstruindo imagens..."
run_docker "compose -f $COMPOSE_FILE build --no-cache"

# 8. INICIAR CONTAINERS
log "Iniciando containers..."
run_docker "compose -f $COMPOSE_FILE up -d"

# 9. AGUARDAR INICIALIZAÇÃO
log "Aguardando 60 segundos para inicialização completa..."
sleep 60

# 10. VERIFICAR STATUS
log "Status dos containers:"
run_docker "ps"

# 11. VERIFICAR E CORRIGIR CONTAINERS
for i in {1..5}; do
    log "Verificação $i/5 dos containers..."
    
    dashboard_running=$(run_docker "ps | grep -q 'academia-dashboard-prod' && echo 'yes' || echo 'no'")
    api_running=$(run_docker "ps | grep -q 'academia-data-api-prod' && echo 'yes' || echo 'no'")
    
    if [ "$dashboard_running" = "no" ]; then
        warn "Dashboard não está rodando (tentativa $i)"
        log "Logs do dashboard:"
        run_docker "logs academia-dashboard-prod --tail 20" || true
        log "Reiniciando dashboard..."
        run_docker "compose -f $COMPOSE_FILE restart academia-dashboard"
        sleep 30
    fi
    
    if [ "$api_running" = "no" ]; then
        warn "API não está rodando (tentativa $i)"
        log "Logs da API:"
        run_docker "logs academia-data-api-prod --tail 20" || true
        log "Reiniciando API..."
        run_docker "compose -f $COMPOSE_FILE restart data-api"
        sleep 30
    fi
    
    # Se ambos estão rodando, sair do loop
    if [ "$dashboard_running" = "yes" ] && [ "$api_running" = "yes" ]; then
        success "✅ Todos os containers estão rodando!"
        break
    fi
    
    sleep 20
done

# 12. TESTAR CONECTIVIDADE
log "Testando conectividade..."
sleep 20

# Testar API
if curl -s http://localhost:3000/health > /dev/null; then
    success "✅ API está funcionando na porta 3000!"
else
    warn "⚠️ API não está respondendo na porta 3000"
    log "Logs da API:"
    run_docker "logs academia-data-api-prod --tail 10"
fi

# Testar Dashboard
if curl -s http://localhost > /dev/null; then
    success "✅ Dashboard está funcionando na porta 80!"
else
    warn "⚠️ Dashboard não está respondendo na porta 80"
    log "Logs do dashboard:"
    run_docker "logs academia-dashboard-prod --tail 10"
fi

# 13. VERIFICAR PORTAS
log "Verificando portas abertas..."
netstat -tlnp | grep -E ":(80|3000)" || true

# 14. MOSTRAR IP PÚBLICO
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Não disponível")
log "IP público: $PUBLIC_IP"

# 15. STATUS FINAL
log "Status final dos containers:"
run_docker "ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

success "Verificação concluída!"
echo ""
log "Para monitorar logs:"
echo "  docker logs -f academia-dashboard-prod"
echo "  docker logs -f academia-data-api-prod"
echo ""
log "Para acessar:"
echo "  http://$PUBLIC_IP"
echo "  http://$PUBLIC_IP:3000/health"
echo ""
log "Para reiniciar:"
echo "  docker-compose -f $COMPOSE_FILE restart"
echo ""


