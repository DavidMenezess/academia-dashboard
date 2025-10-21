#!/bin/bash

# ========================================
# SCRIPT DE HEALTH CHECK
# Academia Dashboard
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   HEALTH CHECK - ACADEMIA DASHBOARD           ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se infraestrutura existe
if [ ! -f terraform.tfstate ] || [ ! -s terraform.tfstate ]; then
    error "Nenhuma infraestrutura deployada"
    exit 1
fi

# Obter IP público
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null)

if [ -z "$PUBLIC_IP" ]; then
    error "Não foi possível obter IP público"
    exit 1
fi

info "Verificando saúde da aplicação em $PUBLIC_IP"
echo ""

# Contadores
PASS=0
FAIL=0

# 1. Ping
echo "🌐 Teste 1: Conectividade (Ping)"
if ping -c 3 -W 2 $PUBLIC_IP > /dev/null 2>&1; then
    success "Servidor respondendo ao ping"
    ((PASS++))
else
    error "Servidor não responde ao ping"
    ((FAIL++))
fi

# 2. SSH
echo ""
echo "🔑 Teste 2: SSH"
KEY_NAME=$(grep 'key_name' terraform.tfvars | cut -d'"' -f2 2>/dev/null)
if [ -f "${KEY_NAME}.pem" ]; then
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} "exit" 2>/dev/null; then
        success "SSH acessível"
        ((PASS++))
    else
        error "SSH não acessível"
        ((FAIL++))
    fi
else
    warn "Chave SSH não encontrada para testar"
fi

# 3. HTTP (Dashboard)
echo ""
echo "📊 Teste 3: Dashboard (HTTP:80)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://${PUBLIC_IP}" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "301" || "$HTTP_CODE" == "302" ]]; then
    success "Dashboard acessível (HTTP $HTTP_CODE)"
    ((PASS++))
else
    error "Dashboard não acessível (HTTP $HTTP_CODE)"
    ((FAIL++))
fi

# 4. API Health Check
echo ""
echo "🔌 Teste 4: API Health Check"
API_RESPONSE=$(curl -s --connect-timeout 10 "http://${PUBLIC_IP}:3000/health" 2>/dev/null || echo "")
if echo "$API_RESPONSE" | grep -q "OK\|healthy"; then
    success "API Health Check OK"
    info "Response: $API_RESPONSE"
    ((PASS++))
else
    error "API Health Check falhou"
    warn "Response: ${API_RESPONSE:-Sem resposta}"
    ((FAIL++))
fi

# 5. API Data Endpoint
echo ""
echo "📡 Teste 5: API Data Endpoint"
API_DATA=$(curl -s --connect-timeout 10 "http://${PUBLIC_IP}:3000/api/data" 2>/dev/null || echo "")
if echo "$API_DATA" | grep -q "academia\|estatisticas"; then
    success "API Data endpoint OK"
    ((PASS++))
else
    error "API Data endpoint falhou"
    ((FAIL++))
fi

# 6. Docker Containers (via SSH)
if [ -f "${KEY_NAME}.pem" ]; then
    echo ""
    echo "🐳 Teste 6: Docker Containers"
    
    CONTAINERS=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} \
        "docker ps --format '{{.Names}}:{{.Status}}'" 2>/dev/null || echo "")
    
    if echo "$CONTAINERS" | grep -q "academia-dashboard"; then
        success "Container dashboard rodando"
        ((PASS++))
    else
        error "Container dashboard não encontrado"
        ((FAIL++))
    fi
    
    if echo "$CONTAINERS" | grep -q "academia-data-api"; then
        success "Container API rodando"
        ((PASS++))
    else
        error "Container API não encontrado"
        ((FAIL++))
    fi
    
    # Mostrar status
    if [ -n "$CONTAINERS" ]; then
        echo ""
        info "Status dos containers:"
        echo "$CONTAINERS" | while read line; do
            echo "  • $line"
        done
    fi
fi

# 7. Recursos do Sistema (via SSH)
if [ -f "${KEY_NAME}.pem" ]; then
    echo ""
    echo "💻 Teste 7: Recursos do Sistema"
    
    # CPU
    CPU=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} \
        "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - \$1}'" 2>/dev/null || echo "N/A")
    
    if [ "$CPU" != "N/A" ]; then
        CPU_INT=${CPU%.*}
        if [ "$CPU_INT" -lt 80 ]; then
            success "CPU: ${CPU}% (OK)"
            ((PASS++))
        else
            warn "CPU: ${CPU}% (Alto)"
            ((FAIL++))
        fi
    fi
    
    # Memória
    MEM=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} \
        "free | grep Mem | awk '{print (\$3/\$2) * 100.0}'" 2>/dev/null || echo "N/A")
    
    if [ "$MEM" != "N/A" ]; then
        MEM_INT=${MEM%.*}
        if [ "$MEM_INT" -lt 80 ]; then
            success "Memória: ${MEM}% (OK)"
            ((PASS++))
        else
            warn "Memória: ${MEM}% (Alto)"
            ((FAIL++))
        fi
    fi
    
    # Disco
    DISK=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} \
        "df -h / | tail -1 | awk '{print \$5}'" 2>/dev/null || echo "N/A")
    
    if [ "$DISK" != "N/A" ]; then
        DISK_INT=${DISK%\%}
        if [ "$DISK_INT" -lt 80 ]; then
            success "Disco: ${DISK} usado (OK)"
            ((PASS++))
        else
            warn "Disco: ${DISK} usado (Alto)"
            ((FAIL++))
        fi
    fi
fi

# 8. SSL/HTTPS (se configurado)
echo ""
echo "🔒 Teste 8: HTTPS (Opcional)"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://${PUBLIC_IP}" 2>/dev/null || echo "000")
if [[ "$HTTPS_CODE" == "200" || "$HTTPS_CODE" == "301" || "$HTTPS_CODE" == "302" ]]; then
    success "HTTPS configurado e funcionando"
    ((PASS++))
else
    info "HTTPS não configurado (opcional)"
fi

# Resultado Final
echo ""
echo "═══════════════════════════════════════════════"
TOTAL=$((PASS + FAIL))
PERCENT=$((PASS * 100 / TOTAL))

if [ $PERCENT -ge 80 ]; then
    echo -e "${GREEN}✓ SAÚDE: EXCELENTE${NC}"
elif [ $PERCENT -ge 60 ]; then
    echo -e "${YELLOW}⚠ SAÚDE: BOA (alguns problemas)${NC}"
else
    echo -e "${RED}✗ SAÚDE: CRÍTICA${NC}"
fi

echo ""
echo "Testes passados: $PASS"
echo "Testes falhos: $FAIL"
echo "Porcentagem: $PERCENT%"
echo "═══════════════════════════════════════════════"

# URLs úteis
echo ""
info "URLs para acesso:"
echo "  Dashboard: http://${PUBLIC_IP}"
echo "  API: http://${PUBLIC_IP}:3000"
echo "  Health: http://${PUBLIC_IP}:3000/health"

# Exit code baseado na saúde
if [ $PERCENT -ge 70 ]; then
    exit 0
else
    exit 1
fi














