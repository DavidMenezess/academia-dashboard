#!/bin/bash

# ========================================
# SCRIPT DE ATUALIZAÇÃO - TERRAFORM
# Academia Dashboard - AWS Free Tier
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
success() { echo -e "${BLUE}[SUCESSO]${NC} $1"; }

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   ACADEMIA DASHBOARD - ATUALIZAR              ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar o que mudou
log "Verificando mudanças..."
if ! terraform plan -detailed-exitcode > /dev/null 2>&1; then
    log "Mudanças detectadas na infraestrutura"
    
    terraform plan
    
    echo ""
    read -p "Aplicar estas mudanças? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        terraform apply -auto-approve
        success "Infraestrutura atualizada!"
    else
        log "Atualização cancelada"
    fi
else
    success "Nenhuma mudança detectada na infraestrutura"
fi

# Perguntar se quer atualizar código no servidor
echo ""
read -p "Deseja atualizar o código da aplicação no servidor? (s/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    PUBLIC_IP=$(terraform output -raw public_ip)
    KEY_NAME=$(grep 'key_name' terraform.tfvars | cut -d'"' -f2)
    
    log "Conectando ao servidor..."
    ssh -i "${KEY_NAME}.pem" ubuntu@${PUBLIC_IP} << 'ENDSSH'
        echo "Atualizando aplicação..."
        sudo update-academia-dashboard
        echo "Atualização concluída!"
ENDSSH
    
    success "Código atualizado no servidor!"
    echo "Dashboard: http://${PUBLIC_IP}"
fi














