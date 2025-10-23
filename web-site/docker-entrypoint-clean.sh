#!/bin/bash
set -e

echo "🚀 Iniciando Academia Dashboard..."

# Verificar se o diretório de dados existe
if [ ! -d "/app/data" ]; then
    echo "📁 Criando diretório de dados..."
    mkdir -p /app/data
fi

# Inicializar dados se não existirem
if [ ! -f "/app/data/academia_data.json" ]; then
    echo "📊 Inicializando dados da academia..."
    cat > /app/data/academia_data.json << 'EOF'
{
    "academia": {
        "nome": "Academia Força Fitness",
        "endereco": "Rua das Academias, 123",
        "telefone": "(11) 99999-9999",
        "email": "contato@forcafitness.com"
    },
    "estatisticas": {
        "total_membros": 0,
        "membros_ativos": 0,
        "receita_mensal": 0,
        "aulas_realizadas": 0
    },
    "ultima_atualizacao": "2025-01-23T00:00:00Z",
    "versao": "1.0.0"
}
EOF
fi

echo "✅ Inicialização concluída!"

# Executar o comando principal
exec "$@"
