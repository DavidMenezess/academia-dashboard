#!/bin/bash

# ========================================
# SCRIPT DE STATUS - TERRAFORM
# Academia Dashboard - AWS Free Tier
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
success() { echo -e "${BLUE}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   ACADEMIA DASHBOARD - STATUS                 ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se infraestrutura existe
if [ ! -f terraform.tfstate ] || [ ! -s terraform.tfstate ]; then
    warn "Nenhuma infraestrutura deployada"
    exit 0
fi

# Obter informações
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "N/A")
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "N/A")
INSTANCE_STATE=$(terraform output -raw instance_state 2>/dev/null || echo "N/A")

echo "🏗️  INFRAESTRUTURA"
echo "─────────────────────────────────────────────"
success "IP Público: $PUBLIC_IP"
success "Instance ID: $INSTANCE_ID"
success "Estado: $INSTANCE_STATE"
echo ""

# Verificar conectividade
echo "🌐 CONECTIVIDADE"
echo "─────────────────────────────────────────────"

# Ping
if ping -c 1 -W 2 $PUBLIC_IP > /dev/null 2>&1; then
    success "Ping: OK"
else
    warn "Ping: Falhou"
fi

# HTTP (Dashboard)
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${PUBLIC_IP}" | grep -q "200\|301\|302"; then
    success "Dashboard (HTTP): Acessível"
    echo "   URL: http://${PUBLIC_IP}"
else
    warn "Dashboard (HTTP): Não acessível"
fi

# API
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${PUBLIC_IP}:3000/health" | grep -q "200"; then
    success "API: Acessível"
    echo "   URL: http://${PUBLIC_IP}:3000"
else
    warn "API: Não acessível"
fi

echo ""

# Docker containers (via SSH)
echo "🐳 CONTAINERS DOCKER"
echo "─────────────────────────────────────────────"

KEY_NAME=$(grep 'key_name' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")

if [ -f "${KEY_NAME}.pem" ]; then
    CONTAINERS=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>/dev/null || echo "")
    
    if [ -n "$CONTAINERS" ]; then
        echo "$CONTAINERS"
    else
        warn "Não foi possível obter status dos containers"
    fi
else
    warn "Chave SSH não encontrada para verificar containers"
fi

echo ""

# Uso de recursos (via SSH)
if [ -f "${KEY_NAME}.pem" ]; then
    echo "💻 RECURSOS DO SERVIDOR"
    echo "─────────────────────────────────────────────"
    
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} << 'ENDSSH' 2>/dev/null || echo "Não foi possível obter informações de recursos"
        # CPU e Memória
        echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
        echo "Memória: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        echo "Disco: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " usado)"}')"
ENDSSH
fi

echo ""

# Últimos logs
if [ -f "${KEY_NAME}.pem" ]; then
    echo "📝 ÚLTIMOS LOGS"
    echo "─────────────────────────────────────────────"
    
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} \
        "docker logs --tail 5 academia-dashboard-prod 2>/dev/null || echo 'Logs não disponíveis'" 2>/dev/null
fi

echo ""
echo "Para mais detalhes:"
echo "  terraform output          - Ver todos os outputs"
echo "  ./scripts/connect.sh      - Conectar via SSH"
echo "  terraform show            - Ver estado completo"














