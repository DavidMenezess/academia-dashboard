#!/bin/bash

# ========================================
# SCRIPT DE DEPLOY - TERRAFORM
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
║   ACADEMIA DASHBOARD - DEPLOY                 ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se terraform está inicializado
if [ ! -d ".terraform" ]; then
    log "Inicializando Terraform..."
    terraform init
fi

# Validar configuração
log "Validando configuração..."
terraform validate

# Ver plano
log "Gerando plano de deployment..."
terraform plan -out=tfplan

echo ""
read -p "Deseja aplicar este plano? (s/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    log "Aplicando infraestrutura..."
    terraform apply tfplan
    rm tfplan
    
    echo ""
    success "Deploy concluído!"
    echo ""
    
    # Mostrar outputs
    terraform output deployment_summary
    
    echo ""
    warn "Aguarde 2-3 minutos para inicialização completa"
else
    log "Deploy cancelado"
    rm tfplan
fi

