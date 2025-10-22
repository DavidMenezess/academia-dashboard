#!/bin/bash

# ========================================
# SCRIPT SIMPLES DE ATUALIZACAO EC2
# ========================================

echo "🔄 Atualizando sistema na EC2..."

# Navegar para o projeto
cd /home/ubuntu/academia-dashboard

# Atualizar código
echo "📥 Baixando alterações do GitHub..."
git pull origin main

# Reiniciar containers
echo "🔄 Reiniciando containers..."
cd web-site
docker-compose -f docker-compose.prod.yml restart

# Verificar status
echo "✅ Atualização concluída!"
echo "🌐 Sistema disponível em: http://$(curl -s ifconfig.me)"
echo "📊 Status dos containers:"
docker ps


