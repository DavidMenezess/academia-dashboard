#!/bin/bash

# ========================================
# SCRIPT PARA INICIAR CONTAINERS
# Academia Dashboard - Start Containers
# ========================================

set -e

echo "🚀 Iniciando containers do Academia Dashboard..."

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1"
}

# 1. Verificar se projeto existe
log "Verificando projeto..."
if [ ! -d "/home/ubuntu/academia-dashboard" ]; then
    error "Projeto não encontrado em /home/ubuntu/academia-dashboard"
    log "Clonando projeto..."
    cd /home/ubuntu
    git clone https://github.com/DavidMenezess/academia-dashboard.git
    log "✅ Projeto clonado!"
else
    log "✅ Projeto encontrado"
fi

# 2. Entrar na pasta correta
cd /home/ubuntu/academia-dashboard
if [ -d "web-site" ]; then
    cd web-site
    log "✅ Entrando na pasta web-site"
fi

# 3. Criar diretórios necessários
log "Criando diretórios..."
mkdir -p data logs api/uploads
log "✅ Diretórios criados"

# 4. Criar dados iniciais se não existir
if [ ! -f "data/academia_data.json" ]; then
    log "Criando dados iniciais..."
    cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Dashboard",
    "endereco": "Configurar no admin"
  },
  "estatisticas": {
    "total_membros": 0,
    "membros_ativos": 0,
    "receita_mensal": 0,
    "aulas_realizadas": 0,
    "instrutores_ativos": 0
  },
  "versao": "1.0.0",
  "ultima_atualizacao": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    log "✅ Dados iniciais criados"
fi

# 5. Ajustar permissões
log "Ajustando permissões..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard
log "✅ Permissões ajustadas"

# 6. Verificar se docker-compose.prod.yml existe
if [ ! -f "docker-compose.prod.yml" ]; then
    error "docker-compose.prod.yml não encontrado!"
    log "Verificando arquivos disponíveis..."
    ls -la
    exit 1
fi

# 7. Parar containers existentes
log "Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down || true
log "✅ Containers parados"

# 8. Limpar sistema Docker
log "Limpando sistema Docker..."
docker system prune -f || true
log "✅ Sistema limpo"

# 9. Build dos containers
log "Fazendo build dos containers..."
docker-compose -f docker-compose.prod.yml build --no-cache
log "✅ Build concluído"

# 10. Iniciar containers
log "Iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d
log "✅ Containers iniciados"

# 11. Aguardar containers iniciarem
log "Aguardando containers iniciarem..."
sleep 30

# 12. Verificar status
log "Verificando status dos containers..."
docker ps

# 13. Testar endpoints
log "Testando endpoints..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    log "✅ Dashboard funcionando"
else
    error "❌ Dashboard não está respondendo"
    log "Verificando logs do dashboard..."
    docker logs academia-dashboard-prod
fi

if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    log "✅ API funcionando"
else
    error "❌ API não está respondendo"
    log "Verificando logs da API..."
    docker logs academia-data-api-prod
fi

# 14. Mostrar informações finais
log "========================================="
log "✅ CONTAINERS INICIADOS COM SUCESSO!"
log "========================================="
log ""
log "📋 Informações:"
log "- Dashboard: http://$(curl -s ifconfig.me)"
log "- API: http://$(curl -s ifconfig.me):3000"
log "- Health: http://$(curl -s ifconfig.me)/health"
log ""
log "🔧 Comandos úteis:"
log "- Ver containers: docker ps"
log "- Ver logs: docker logs academia-dashboard-prod"
log "- Reiniciar: docker-compose -f docker-compose.prod.yml restart"
log "- Parar: docker-compose -f docker-compose.prod.yml down"
log ""
log "========================================="

exit 0
