#!/bin/bash

echo "🔧 CORREÇÃO RÁPIDA DOS CONTAINERS"
echo "=================================="

# Ir para a pasta correta
if [ -d "academia-dashboard/web-site" ]; then
    cd academia-dashboard/web-site
elif [ -d "web-site" ]; then
    cd web-site
fi

echo "📂 Pasta atual: $(pwd)"

# Parar containers
echo "🛑 Parando containers..."
docker-compose -f docker-compose.prod.yml down || true

# Limpar tudo
echo "🧹 Limpando containers e volumes..."
docker system prune -f || true

# Build e start
echo "🚀 Fazendo build e iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d --build

# Aguardar
echo "⏳ Aguardando 30 segundos..."
sleep 30

# Verificar
echo "📊 Status dos containers:"
docker ps

echo "🧪 Testando aplicação..."
if curl -s http://localhost > /dev/null; then
    echo "✅ APLICAÇÃO FUNCIONANDO!"
else
    echo "❌ Aplicação não está respondendo"
    echo "📋 Logs dos containers:"
    docker-compose -f docker-compose.prod.yml logs
fi

echo "=================================="
echo "✅ CORREÇÃO CONCLUÍDA"


