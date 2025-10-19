#!/bin/bash

# ========================================
# SCRIPT DE DESTRUIÇÃO - TERRAFORM
# Academia Dashboard - AWS Free Tier
# ========================================

set -e

# Cores
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1"; }

# Banner
echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   ACADEMIA DASHBOARD - DESTRUIR INFRAESTRUTURA║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

warn "ATENÇÃO: Esta ação irá DESTRUIR TODA a infraestrutura!"
warn "Isso inclui:"
echo "  - Instância EC2"
echo "  - Elastic IP"
echo "  - Security Groups"
echo "  - Todos os dados no servidor"
echo ""

read -p "Tem certeza que deseja continuar? (digite 'sim' para confirmar): " CONFIRM

if [ "$CONFIRM" != "sim" ]; then
    echo "Operação cancelada"
    exit 0
fi

echo ""
warn "Última chance! Destruir infraestrutura?"
read -p "Digite 'DESTRUIR' para confirmar: " FINAL_CONFIRM

if [ "$FINAL_CONFIRM" != "DESTRUIR" ]; then
    echo "Operação cancelada"
    exit 0
fi

echo ""
error "Destruindo infraestrutura..."
terraform destroy -auto-approve

echo ""
error "Infraestrutura destruída!"
warn "Não esqueça de verificar no AWS Console se tudo foi removido"










