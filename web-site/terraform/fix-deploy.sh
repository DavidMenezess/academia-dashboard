#!/bin/bash

# ========================================
# SCRIPT DE CORREÇÃO RÁPIDA - EC2
# Academia Dashboard - Fix Deploy
# ========================================

set -e

echo "🔧 Iniciando correção do deploy..."

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1"
}

# 1. Instalar Docker se não estiver instalado
log "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    log "Docker não encontrado. Instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
    rm get-docker.sh
    log "✅ Docker instalado!"
else
    log "✅ Docker já está instalado"
fi

# 2. Instalar Docker Compose se não estiver instalado
log "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    log "Docker Compose não encontrado. Instalando..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    log "✅ Docker Compose instalado!"
else
    log "✅ Docker Compose já está instalado"
fi

# 3. Verificar se projeto existe
log "Verificando projeto..."
if [ ! -d "/home/ubuntu/academia-dashboard" ]; then
    log "Projeto não encontrado. Clonando..."
    cd /home/ubuntu
    git clone https://github.com/SEU-USUARIO/academia-dashboard.git
    log "✅ Projeto clonado!"
else
    log "✅ Projeto já existe"
fi

# 4. Entrar na pasta correta
cd /home/ubuntu/academia-dashboard
if [ -d "web-site" ]; then
    cd web-site
    log "✅ Entrando na pasta web-site"
fi

# 5. Criar diretórios necessários
log "Criando diretórios..."
mkdir -p data logs api/uploads
log "✅ Diretórios criados"

# 6. Criar dados iniciais se não existir
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

# 7. Ajustar permissões
log "Ajustando permissões..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard
log "✅ Permissões ajustadas"

# 8. Parar containers existentes
log "Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down || true
log "✅ Containers parados"

# 9. Limpar sistema Docker
log "Limpando sistema Docker..."
docker system prune -f || true
log "✅ Sistema limpo"

# 10. Build e start dos containers
log "Fazendo build dos containers..."
docker-compose -f docker-compose.prod.yml build --no-cache
log "✅ Build concluído"

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
fi

if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    log "✅ API funcionando"
else
    error "❌ API não está respondendo"
fi

# 14. Mostrar informações finais
log "========================================="
log "✅ CORREÇÃO CONCLUÍDA!"
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
