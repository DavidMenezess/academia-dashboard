#!/bin/bash

# ========================================
# SCRIPT PARA CLONAR E INICIAR PROJETO
# Academia Dashboard - Clone and Start
# ========================================

set -e

echo "🚀 Clonando e iniciando Academia Dashboard..."

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1"
}

# 1. Verificar se Git está instalado
log "Verificando Git..."
if ! command -v git &> /dev/null; then
    log "Git não encontrado. Instalando..."
    sudo apt update
    sudo apt install git -y
    log "✅ Git instalado!"
else
    log "✅ Git já está instalado"
fi

# 2. Ir para pasta home
log "Indo para pasta home..."
cd /home/ubuntu

# 3. Verificar se projeto já existe
if [ -d "academia-dashboard" ]; then
    log "Projeto já existe. Removendo versão antiga..."
    rm -rf academia-dashboard
fi

# 4. Clonar projeto
log "Clonando projeto do GitHub..."
git clone https://github.com/DavidMenezess/academia-dashboard.git
if [ $? -eq 0 ]; then
    log "✅ Projeto clonado com sucesso!"
else
    error "Falha ao clonar projeto"
    exit 1
fi

# 5. Entrar na pasta correta
log "Entrando na pasta web-site..."
cd academia-dashboard/web-site

# 6. Verificar se arquivos existem
if [ ! -f "docker-compose.prod.yml" ]; then
    error "docker-compose.prod.yml não encontrado!"
    log "Verificando arquivos disponíveis..."
    ls -la
    exit 1
fi

if [ ! -f "Dockerfile" ]; then
    error "Dockerfile não encontrado!"
    exit 1
fi

log "✅ Arquivos necessários encontrados"

# 7. Criar diretórios necessários
log "Criando diretórios..."
mkdir -p data logs api/uploads
log "✅ Diretórios criados"

# 8. Criar dados iniciais
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

# 9. Ajustar permissões
log "Ajustando permissões..."
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard
sudo chmod -R 755 /home/ubuntu/academia-dashboard
log "✅ Permissões ajustadas"

# 10. Parar containers existentes
log "Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down || true
log "✅ Containers parados"

# 11. Limpar sistema Docker
log "Limpando sistema Docker..."
docker system prune -f || true
log "✅ Sistema limpo"

# 12. Build dos containers
log "Fazendo build dos containers..."
docker-compose -f docker-compose.prod.yml build --no-cache
if [ $? -eq 0 ]; then
    log "✅ Build concluído com sucesso!"
else
    error "Falha no build dos containers"
    exit 1
fi

# 13. Iniciar containers
log "Iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d
if [ $? -eq 0 ]; then
    log "✅ Containers iniciados com sucesso!"
else
    error "Falha ao iniciar containers"
    exit 1
fi

# 14. Aguardar containers iniciarem
log "Aguardando containers iniciarem..."
sleep 30

# 15. Verificar status
log "Verificando status dos containers..."
docker ps

# 16. Testar endpoints
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

# 17. Mostrar informações finais
log "========================================="
log "✅ PROJETO CLONADO E CONTAINERS INICIADOS!"
log "========================================="
log ""
log "📋 Informações:"
log "- Projeto: /home/ubuntu/academia-dashboard"
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
log "📁 Estrutura do projeto:"
log "- /home/ubuntu/academia-dashboard/web-site/"
log "- data/ (dados da academia)"
log "- logs/ (logs da aplicação)"
log "- api/ (backend Node.js)"
log ""
log "========================================="

exit 0
