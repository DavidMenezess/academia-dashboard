#!/bin/bash

# ========================================
# CORREÇÃO DE PERMISSÕES DO DOCKER
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
║   CORREÇÃO DE PERMISSÕES DO DOCKER           ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    error "Este script não deve ser executado como root!"
    exit 1
fi

log "Corrigindo permissões do Docker..."

# 1. Adicionar usuário ao grupo docker
log "Adicionando usuário ao grupo docker..."
sudo usermod -aG docker $USER

# 2. Reiniciar serviço do Docker
log "Reiniciando serviço do Docker..."
sudo systemctl restart docker

# 3. Aguardar Docker inicializar
log "Aguardando Docker inicializar..."
sleep 5

# 4. Verificar se Docker está funcionando
log "Verificando se Docker está funcionando..."
if docker ps > /dev/null 2>&1; then
    success "Docker está funcionando corretamente!"
else
    warn "Docker ainda não está acessível. Tentando soluções alternativas..."
    
    # Tentar executar com sudo temporariamente
    log "Executando comandos Docker com sudo..."
    
    # Parar containers existentes
    sudo docker-compose -f docker-compose.prod.yml down || true
    
    # Limpar containers e volumes
    sudo docker system prune -f || true
    
    # Fazer build e iniciar containers
    sudo docker-compose -f docker-compose.prod.yml up --build -d
    
    success "Containers iniciados com sudo!"
    warn "Recomendado: faça logout e login novamente para aplicar as permissões do grupo docker"
fi

# 5. Verificar status dos containers
log "Verificando status dos containers..."
if docker ps > /dev/null 2>&1; then
    docker ps
else
    sudo docker ps
fi

success "Correção de permissões concluída!"
echo ""
warn "IMPORTANTE: Para aplicar as permissões do grupo docker completamente:"
echo "1. Faça logout: exit"
echo "2. Conecte novamente via SSH"
echo "3. Execute: docker ps (sem sudo)"
echo ""


