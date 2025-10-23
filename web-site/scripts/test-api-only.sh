#!/bin/bash

# ========================================
# TESTE ISOLADO DA API
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
║   TESTE ISOLADO DA API                       ║
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

# 1. PARAR TUDO
log "Parando todos os containers..."
run_docker "stop $(docker ps -q)" 2>/dev/null || true
run_docker "rm $(docker ps -aq)" 2>/dev/null || true

# 2. NAVEGAR PARA O PROJETO
log "Navegando para o projeto..."
cd ~/academia-dashboard/web-site

# 3. CRIAR DADOS INICIAIS
log "Criando dados iniciais..."
mkdir -p data
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

# 4. TESTAR API ISOLADAMENTE
log "Testando API isoladamente..."
run_docker "run -d --name test-api \
  -p 3000:3000 \
  -v $(pwd)/api:/app \
  -v $(pwd)/data:/app/data \
  -e NODE_ENV=production \
  -e PORT=3000 \
  node:18-alpine \
  sh -c 'cd /app && npm install --production --silent && node server.js'"

# 5. AGUARDAR API INICIALIZAR
log "Aguardando API inicializar..."
sleep 30

# 6. VERIFICAR LOGS DA API
log "Logs da API:"
run_docker "logs test-api --tail 30"

# 7. TESTAR CONECTIVIDADE
log "Testando conectividade da API..."
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    success "✅ API está funcionando!"
    
    # Testar endpoint de dados
    log "Testando endpoint de dados..."
    if curl -f http://localhost:3000/api/data > /dev/null 2>&1; then
        success "✅ Endpoint de dados está funcionando!"
    else
        warn "⚠️  Endpoint de dados não está respondendo"
    fi
else
    error "❌ API não está funcionando!"
    log "Logs detalhados:"
    run_docker "logs test-api --tail 50"
fi

# 8. VERIFICAR STATUS DO CONTAINER
log "Status do container:"
run_docker "ps | grep test-api"

# 9. LIMPAR CONTAINER DE TESTE
log "Limpando container de teste..."
run_docker "stop test-api" 2>/dev/null || true
run_docker "rm test-api" 2>/dev/null || true

success "Teste da API concluído!"
echo ""
log "Se a API funcionou, o problema está no dashboard."
log "Se a API não funcionou, o problema está na API."
echo ""
