#!/bin/bash

# ========================================
# SCRIPT DE CORREÇÃO DOS CONTAINERS
# Academia Dashboard - Diagnóstico e Correção
# ========================================

set -e

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1"
}

warning() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] AVISO: $1"
}

log "========================================="
log "DIAGNÓSTICO E CORREÇÃO DOS CONTAINERS"
log "========================================="

# Verificar se estamos na pasta correta
if [ ! -f "docker-compose.prod.yml" ]; then
    if [ -d "academia-dashboard" ]; then
        log "Mudando para pasta academia-dashboard..."
        cd academia-dashboard
    fi
    
    if [ -d "web-site" ]; then
        log "Mudando para pasta web-site..."
        cd web-site
    fi
fi

# Verificar se docker-compose.prod.yml existe
if [ ! -f "docker-compose.prod.yml" ]; then
    error "docker-compose.prod.yml não encontrado!"
    log "Procurando arquivos docker-compose..."
    find . -name "docker-compose*.yml" 2>/dev/null || true
    exit 1
fi

log "✅ docker-compose.prod.yml encontrado"

# Verificar Docker
log "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado!"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose não está instalado!"
    exit 1
fi

log "✅ Docker e Docker Compose estão instalados"

# Parar todos os containers
log "Parando todos os containers..."
docker-compose -f docker-compose.prod.yml down || true
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Limpar volumes e redes órfãos
log "Limpando volumes e redes órfãos..."
docker system prune -f || true
docker volume prune -f || true
docker network prune -f || true

# Verificar arquivos necessários
log "Verificando estrutura de arquivos..."
if [ ! -d "api" ]; then
    error "Pasta api não encontrada!"
    exit 1
fi

if [ ! -f "api/package.json" ]; then
    error "api/package.json não encontrado!"
    exit 1
fi

log "✅ Estrutura de arquivos OK"

# Criar diretórios necessários
log "Criando diretórios necessários..."
mkdir -p data logs api/uploads
chmod 755 data logs api/uploads

# Instalar dependências da API
log "Instalando dependências da API..."
cd api
if [ -f "package-lock.json" ]; then
    npm ci --no-audit --no-fund || npm install --no-audit --no-fund
else
    npm install --no-audit --no-fund
fi
cd ..

# Configurar variáveis de ambiente
log "Configurando variáveis de ambiente..."
export DATABASE_TYPE=dynamodb
export AWS_REGION=us-east-1
export DYNAMODB_TABLE=academia-dashboard-prod
export AWS_USE_IAM_ROLE=true

# Verificar permissões
log "Verificando permissões..."
chown -R ubuntu:ubuntu . 2>/dev/null || true
chmod -R 755 .

# Fazer build dos containers
log "Fazendo build dos containers..."
docker-compose -f docker-compose.prod.yml build --no-cache

# Iniciar containers
log "Iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar containers iniciarem
log "Aguardando containers iniciarem..."
sleep 30

# Verificar status dos containers
log "Verificando status dos containers..."
docker ps

# Verificar logs se necessário
if ! docker ps | grep -q "academia-dashboard-prod"; then
    warning "⚠️ Dashboard container não está rodando"
    log "Verificando logs do dashboard..."
    docker logs academia-dashboard-prod || true
    
    log "Tentando reiniciar dashboard..."
    docker-compose -f docker-compose.prod.yml restart academia-dashboard
    sleep 10
fi

if ! docker ps | grep -q "academia-data-api-prod"; then
    warning "⚠️ API container não está rodando"
    log "Verificando logs da API..."
    docker logs academia-data-api-prod || true
    
    log "Tentando reiniciar API..."
    docker-compose -f docker-compose.prod.yml restart data-api
    sleep 10
fi

# Verificação final
log "🎯 STATUS FINAL DOS CONTAINERS:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Testar aplicação
log "🧪 TESTANDO APLICAÇÃO..."
sleep 5

if curl -s http://localhost > /dev/null; then
    log "✅ APLICAÇÃO RESPONDENDO EM http://localhost"
else
    warning "⚠️ Aplicação não está respondendo"
    log "Verificando logs dos containers..."
    docker-compose -f docker-compose.prod.yml logs
fi

log "========================================="
log "✅ DIAGNÓSTICO E CORREÇÃO CONCLUÍDOS"
log "========================================="

log "Comandos úteis:"
log "- Ver containers: docker ps"
log "- Ver logs: docker-compose -f docker-compose.prod.yml logs"
log "- Reiniciar: docker-compose -f docker-compose.prod.yml restart"
log "- Parar: docker-compose -f docker-compose.prod.yml down"
log "========================================="


