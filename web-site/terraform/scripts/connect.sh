#!/bin/bash

# ========================================
# SCRIPT DE CONEXÃO SSH - TERRAFORM
# Academia Dashboard - AWS Free Tier
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
success() { echo -e "${BLUE}[SUCESSO]${NC} $1"; }

# Obter informações do Terraform
PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null)
KEY_NAME=$(grep 'key_name' terraform.tfvars | cut -d'"' -f2)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "" ]; then
    echo "Erro: Não foi possível obter o IP público"
    echo "Certifique-se de que a infraestrutura está deployada"
    exit 1
fi

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   CONECTANDO AO SERVIDOR                      ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log "IP Público: $PUBLIC_IP"
log "Chave SSH: ${KEY_NAME}.pem"
echo ""

# Verificar se chave existe
if [ ! -f "${KEY_NAME}.pem" ]; then
    echo "Erro: Chave SSH ${KEY_NAME}.pem não encontrada"
    echo "Coloque a chave SSH no diretório atual"
    exit 1
fi

# Verificar permissões da chave
if [ "$(stat -f %Lp "${KEY_NAME}.pem" 2>/dev/null || stat -c %a "${KEY_NAME}.pem" 2>/dev/null)" != "400" ]; then
    log "Ajustando permissões da chave SSH..."
    chmod 400 "${KEY_NAME}.pem"
fi

success "Conectando ao servidor..."
echo ""

ssh -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP}













