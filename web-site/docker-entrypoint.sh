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
    cat > /app/data/academia_data.json << EOF
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
    "ultima_atualizacao": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
fi

# Executar scripts de inicialização se existirem
if [ -d "/app/scripts" ]; then
    echo "🔧 Executando scripts de inicialização..."
    for script in /app/scripts/*.sh; do
        if [ -f "$script" ]; then
            echo "Executando: $script"
            bash "$script"
        fi
    done
fi

echo "✅ Inicialização concluída!"

# Executar o comando principal
exec "$@"

