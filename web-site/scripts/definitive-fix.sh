#!/bin/bash

# ========================================
# CORREÇÃO DEFINITIVA - ACADEMIA DASHBOARD
# Resolve TODOS os problemas de uma vez
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
║   CORREÇÃO DEFINITIVA - ACADEMIA DASHBOARD  ║
║   Resolve TODOS os problemas de uma vez     ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Função para executar comandos Docker
run_docker() {
    local cmd="$1"
    if docker $cmd 2>/dev/null; then
        return 0
    else
        warn "Executando com sudo: $cmd"
        sudo docker $cmd
        return $?
    fi
}

# 1. CORRIGIR PERMISSÕES DO DOCKER
log "Corrigindo permissões do Docker..."
sudo usermod -aG docker $USER
sudo systemctl restart docker
sleep 5

# 2. PARAR E LIMPAR TUDO
log "Parando todos os containers..."
run_docker "stop $(docker ps -q)" 2>/dev/null || true
run_docker "rm $(docker ps -aq)" 2>/dev/null || true

log "Limpando sistema Docker..."
run_docker "system prune -af"
run_docker "volume prune -f"
run_docker "network prune -f"

# 3. NAVEGAR PARA O PROJETO
log "Navegando para o projeto..."
cd ~/academia-dashboard/web-site

# 4. VERIFICAR ESTRUTURA DO PROJETO
log "Verificando estrutura do projeto..."
required_files=("Dockerfile" "docker-compose.prod.yml" "docker-entrypoint.sh")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        error "Arquivo $file não encontrado!"
        exit 1
    fi
done

required_dirs=("src" "api" "config" "data")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        error "Diretório $dir não encontrado!"
        exit 1
    fi
done

# 5. CRIAR DOCKERFILE CORRIGIDO
log "Criando Dockerfile corrigido..."
cat > Dockerfile << 'EOF'
# Use uma imagem base do Nginx (leve e otimizada)
FROM nginx:alpine

# Instalar dependências necessárias
RUN apk add --no-cache \
    curl \
    jq \
    bash

# Copiar arquivos do site
COPY src/ /usr/share/nginx/html/

# Copiar configuração personalizada do Nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Criar diretório para dados
RUN mkdir -p /app/data

# Copiar script de inicialização simples
COPY docker-entrypoint-simple.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expor porta 80
EXPOSE 80

# Comando de inicialização
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF

# 6. CRIAR SCRIPT DE INICIALIZAÇÃO SIMPLES
log "Criando script de inicialização simples..."
cat > docker-entrypoint-simple.sh << 'EOF'
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
    cat > /app/data/academia_data.json << 'JSONEOF'
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
JSONEOF
fi

echo "✅ Inicialização concluída!"

# Executar o comando principal
exec "$@"
EOF

chmod +x docker-entrypoint-simple.sh

# 7. CRIAR DOCKER-COMPOSE SIMPLIFICADO
log "Criando docker-compose simplificado..."
cat > docker-compose-simple.yml << 'EOF'
version: '3.8'

services:
  academia-dashboard:
    build: .
    container_name: academia-dashboard-prod
    ports:
      - "80:80"
    volumes:
      - ./data:/app/data
      - ./logs:/var/log/nginx
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  data-api:
    image: node:18-alpine
    container_name: academia-data-api-prod
    working_dir: /app
    volumes:
      - ./api:/app
      - ./data:/app/data
    ports:
      - "3000:3000"
    command: >
      sh -c "
        npm install --production --silent &&
        node server.js
      "
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
EOF

# 8. CRIAR DADOS INICIAIS
log "Criando dados iniciais..."
mkdir -p data
cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Força Fitness",
    "endereco": "Rua das Academias, 123 - Centro",
    "telefone": "(11) 99999-9999",
    "email": "contato@forcafitness.com",
    "horario_funcionamento": "06:00 - 22:00",
    "dias_funcionamento": "Segunda a Sábado"
  },
  "estatisticas": {
    "total_membros": 150,
    "membros_ativos": 120,
    "membros_novos_mes": 8,
    "receita_mensal": 15000.00,
    "receita_anual": 180000.00,
    "aulas_realizadas": 45,
    "aulas_agendadas": 12,
    "instrutores_ativos": 6,
    "equipamentos_total": 25,
    "equipamentos_manutencao": 2
  },
  "membros": {
    "por_faixa_etaria": {
      "18-25": 35,
      "26-35": 45,
      "36-45": 40,
      "46-55": 20,
      "55+": 10
    },
    "por_plano": {
      "mensal": 80,
      "trimestral": 35,
      "semestral": 20,
      "anual": 15
    }
  },
  "aulas": {
    "musculacao": {
      "total": 20,
      "participantes_media": 8
    },
    "pilates": {
      "total": 15,
      "participantes_media": 6
    },
    "spinning": {
      "total": 10,
      "participantes_media": 12
    }
  },
  "financeiro": {
    "receitas": {
      "mensalidades": 12000.00,
      "aulas_particulares": 2000.00,
      "produtos": 1000.00
    },
    "despesas": {
      "aluguel": 3000.00,
      "funcionarios": 8000.00,
      "equipamentos": 500.00,
      "utilitarios": 800.00
    }
  },
  "metas": {
    "membros_meta": 200,
    "receita_meta": 20000.00,
    "satisfacao_meta": 4.5
  },
  "ultima_atualizacao": "2025-01-23T00:00:00Z",
  "versao": "1.0.0"
}
EOF

# 9. CRIAR DIRETÓRIO DE LOGS
log "Criando diretório de logs..."
mkdir -p logs

# 10. CORRIGIR PERMISSÕES
log "Corrigindo permissões..."
chmod +x docker-entrypoint-simple.sh
chmod 755 src/
chmod 755 api/
chmod 755 config/
chmod 755 data/
chmod 755 logs/

# 11. RECONSTRUIR IMAGEM
log "Reconstruindo imagem do zero..."
run_docker "build -t academia-dashboard:latest . --no-cache --pull"

# 12. VERIFICAR IMAGEM
log "Verificando imagens..."
run_docker "images | grep academia"

# 13. INICIAR CONTAINERS
log "Iniciando containers com docker-compose simplificado..."
run_docker "compose -f docker-compose-simple.yml up -d"

# 14. AGUARDAR INICIALIZAÇÃO
log "Aguardando 45 segundos para inicialização completa..."
sleep 45

# 15. VERIFICAR STATUS
log "Status dos containers:"
run_docker "ps"

# 16. VERIFICAR LOGS
log "Logs do dashboard:"
run_docker "logs academia-dashboard-prod --tail 20"

log "Logs da API:"
run_docker "logs academia-data-api-prod --tail 20"

# 17. TESTAR CONECTIVIDADE
log "Testando conectividade..."
sleep 10

# Testar API
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    success "✅ API está funcionando na porta 3000!"
else
    warn "⚠️  API não está respondendo na porta 3000"
    run_docker "logs academia-data-api-prod --tail 10"
fi

# Testar Dashboard
if curl -f http://localhost/health > /dev/null 2>&1; then
    success "✅ Dashboard está funcionando na porta 80!"
else
    warn "⚠️  Dashboard não está respondendo na porta 80"
    run_docker "logs academia-dashboard-prod --tail 10"
fi

# 18. VERIFICAR PORTAS
log "Verificando portas abertas..."
netstat -tlnp | grep -E ":(80|3000)" || true

# 19. MOSTRAR IP PÚBLICO
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Não disponível")
log "IP público: $PUBLIC_IP"

success "Correção definitiva finalizada!"
echo ""
log "Para monitorar logs:"
echo "  docker logs -f academia-dashboard-prod"
echo "  docker logs -f academia-data-api-prod"
echo ""
log "Para verificar status:"
echo "  docker ps"
echo ""
log "Para acessar:"
echo "  http://$PUBLIC_IP"
echo "  http://$PUBLIC_IP:3000/health"
echo ""
log "Se ainda não funcionar, execute:"
echo "  docker logs academia-dashboard-prod"
echo "  docker logs academia-data-api-prod"
echo ""
log "Para parar tudo:"
echo "  docker compose -f docker-compose-simple.yml down"
echo ""
