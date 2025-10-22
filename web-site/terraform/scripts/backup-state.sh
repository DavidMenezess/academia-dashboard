#!/bin/bash

# ========================================
# SCRIPT DE BACKUP DO STATE - TERRAFORM
# Academia Dashboard
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
success() { echo -e "${BLUE}[SUCESSO]${NC} $1"; }

# Diretório de backup
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Criar diretório se não existir
mkdir -p $BACKUP_DIR

# Backup do tfstate
if [ -f terraform.tfstate ]; then
    log "Fazendo backup do terraform.tfstate..."
    cp terraform.tfstate "$BACKUP_DIR/terraform.tfstate.$TIMESTAMP"
    success "Backup salvo: $BACKUP_DIR/terraform.tfstate.$TIMESTAMP"
fi

# Backup do tfstate.backup
if [ -f terraform.tfstate.backup ]; then
    log "Fazendo backup do terraform.tfstate.backup..."
    cp terraform.tfstate.backup "$BACKUP_DIR/terraform.tfstate.backup.$TIMESTAMP"
fi

# Backup do tfvars
if [ -f terraform.tfvars ]; then
    log "Fazendo backup do terraform.tfvars..."
    cp terraform.tfvars "$BACKUP_DIR/terraform.tfvars.$TIMESTAMP"
fi

# Compactar backups antigos (mais de 30 dias)
find $BACKUP_DIR -name "terraform.tfstate.*" -mtime +30 -type f -exec gzip {} \;

# Manter apenas últimos 10 backups
ls -t $BACKUP_DIR/terraform.tfstate.* 2>/dev/null | tail -n +11 | xargs -r rm

success "Backup concluído!"
echo ""
echo "Backups disponíveis:"
ls -lh $BACKUP_DIR/ | grep terraform.tfstate

















