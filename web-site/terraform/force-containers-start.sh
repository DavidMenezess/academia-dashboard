#!/bin/bash
# Script para forçar início dos containers

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

log "=== FORÇANDO INÍCIO DOS CONTAINERS ==="

# Navegar para o diretório do projeto
cd /home/ubuntu/academia-dashboard/web-site

# Parar todos os containers
log "Parando todos os containers..."
docker-compose -f docker-compose.prod.yml down || true

# Limpar sistema Docker
log "Limpando sistema Docker..."
docker system prune -f || true

# Aguardar Docker estar pronto
log "Aguardando Docker estar pronto..."
sleep 15

# Reconstruir imagens
log "Reconstruindo imagens..."
docker-compose -f docker-compose.prod.yml build --no-cache

# Iniciar containers
log "Iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar inicialização
log "Aguardando containers iniciarem..."
sleep 90

# Verificar status
log "Status dos containers:"
docker ps

# Verificar se ambos estão rodando
dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")

log "Dashboard: $dashboard_running, API: $api_running"

# Se algum não estiver rodando, tentar reiniciar
if [ "$dashboard_running" = "no" ] || [ "$api_running" = "no" ]; then
    log "Alguns containers não estão rodando, reiniciando..."
    
    if [ "$dashboard_running" = "no" ]; then
        log "Reiniciando dashboard..."
        docker-compose -f docker-compose.prod.yml restart academia-dashboard || true
    fi
    
    if [ "$api_running" = "no" ]; then
        log "Reiniciando API..."
        docker-compose -f docker-compose.prod.yml restart data-api || true
    fi
    
    sleep 45
    
    # Verificar novamente
    dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
    api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")
    
    log "Status após reinicialização - Dashboard: $dashboard_running, API: $api_running"
fi

# Testar conectividade
log "Testando conectividade..."
sleep 30

# Testar dashboard
if curl -s http://localhost > /dev/null; then
    log "✅ Dashboard funcionando!"
else
    log "⚠️ Dashboard não respondeu"
    docker logs academia-dashboard-prod --tail 10 || true
fi

# Testar API
if curl -s http://localhost:3000/health > /dev/null; then
    log "✅ API funcionando!"
else
    log "⚠️ API não respondeu"
    docker logs academia-data-api-prod --tail 10 || true
fi

# Garantir que o serviço systemd está ativo
log "Verificando serviço systemd..."
systemctl is-active academia-dashboard.service || {
    log "Serviço não está ativo, iniciando..."
    systemctl start academia-dashboard.service
}

systemctl is-enabled academia-dashboard.service || {
    log "Serviço não está habilitado, habilitando..."
    systemctl enable academia-dashboard.service
}

# Status final
log "=== STATUS FINAL ==="
docker ps
systemctl status academia-dashboard.service --no-pager

log "=== CONTAINERS FORÇADOS A INICIAR ==="
