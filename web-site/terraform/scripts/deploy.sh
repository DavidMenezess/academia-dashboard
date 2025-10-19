#!/usr/bin/env bash

# ========================================
# SCRIPT DE DEPLOY - TERRAFORM
# Academia Dashboard - AWS Free Tier
# ========================================

set -euo pipefail

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

ACTION="${1:-apply}"
export TF_IN_AUTOMATION=1

# Inicializar terraform
log "Inicializando Terraform..."
terraform init -input=false

# Validar configuração
log "Validando configuração..."
terraform validate -no-color

case "$ACTION" in
  plan)
    log "Gerando plano..."
    terraform plan -input=false -out=tfplan
    ;;
  apply)
    log "Gerando plano e aplicando..."
    terraform plan -input=false -out=tfplan
    terraform apply -auto-approve tfplan
    rm -f tfplan || true
    success "Deploy concluído!"
    terraform output || true
    ;;
  destroy)
    warn "Destruindo recursos..."
    terraform destroy -auto-approve
    ;;
  *)
    echo "Ação inválida: $ACTION (use: plan|apply|destroy)" >&2
    exit 1
    ;;
esac









