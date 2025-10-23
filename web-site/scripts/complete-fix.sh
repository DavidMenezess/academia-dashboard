#!/bin/bash

# ========================================
# CORREÇÃO COMPLETA DO SISTEMA
# Academia Dashboard - AWS EC2
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
║   CORREÇÃO COMPLETA DO SISTEMA              ║
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

# 1. PARAR TUDO E LIMPAR COMPLETAMENTE
log "Parando todos os containers..."
run_docker "stop $(docker ps -q)" 2>/dev/null || true
run_docker "rm $(docker ps -aq)" 2>/dev/null || true

log "Limpando sistema Docker completamente..."
run_docker "system prune -af"
run_docker "volume prune -f"
run_docker "network prune -f"

# 2. VERIFICAR E CORRIGIR ARQUIVOS
log "Verificando estrutura do projeto..."
cd ~/academia-dashboard/web-site

# Verificar se todos os arquivos essenciais existem
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

# 3. CORRIGIR PERMISSÕES
log "Corrigindo permissões..."
chmod +x docker-entrypoint.sh
chmod +x scripts/*.sh 2>/dev/null || true
chmod 755 src/
chmod 755 api/
chmod 755 config/
chmod 755 data/

# 4. VERIFICAR CONTEÚDO DOS ARQUIVOS CRÍTICOS
log "Verificando Dockerfile..."
if ! grep -q "FROM nginx:alpine" Dockerfile; then
    error "Dockerfile não está correto!"
    cat Dockerfile
    exit 1
fi

log "Verificando docker-entrypoint.sh..."
if [ ! -x "docker-entrypoint.sh" ]; then
    error "docker-entrypoint.sh não é executável!"
    exit 1
fi

# 5. CRIAR ARQUIVOS FALTANTES SE NECESSÁRIO
log "Verificando arquivos de configuração..."

# Verificar se nginx.conf existe
if [ ! -f "config/nginx.conf" ]; then
    warn "nginx.conf não encontrado, criando..."
    mkdir -p config
    cat > config/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html index.htm;

        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        location / {
            try_files $uri $uri/ /index.html;
        }

        location /api/ {
            proxy_pass http://localhost:3000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
fi

# 6. CRIAR DADOS INICIAIS SE NECESSÁRIO
log "Verificando dados iniciais..."
if [ ! -f "data/academia_data.json" ]; then
    warn "Criando dados iniciais..."
    mkdir -p data
    cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Força Fitness",
    "endereco": "Rua das Academias, 123 - Centro",
    "telefone": "(11) 99999-9999",
    "email": "contato@forcafitness.com"
  },
  "estatisticas": {
    "total_membros": 150,
    "membros_ativos": 120,
    "receita_mensal": 15000.00,
    "aulas_realizadas": 45,
    "instrutores_ativos": 6
  },
  "ultima_atualizacao": "2025-01-23T00:00:00Z",
  "versao": "1.0.0"
}
EOF
fi

# 7. RECONSTRUIR IMAGEM DO ZERO
log "Reconstruindo imagem do zero..."
run_docker "build -t academia-dashboard:latest . --no-cache --pull"

# 8. VERIFICAR SE A IMAGEM FOI CRIADA
log "Verificando imagens..."
run_docker "images | grep academia"

# 9. INICIAR CONTAINERS MANUALMENTE (SEM DOCKER-COMPOSE)
log "Iniciando containers manualmente..."

# Parar qualquer container existente
run_docker "stop academia-dashboard-prod academia-data-api-prod" 2>/dev/null || true
run_docker "rm academia-dashboard-prod academia-data-api-prod" 2>/dev/null || true

# Iniciar API primeiro
log "Iniciando API..."
run_docker "run -d --name academia-data-api-prod \
  -p 3000:3000 \
  -v $(pwd)/api:/app \
  -v $(pwd)/data:/app/data \
  -e NODE_ENV=production \
  -e PORT=3000 \
  node:18-alpine \
  sh -c 'cd /app && npm install --production --silent && node server.js'"

# Aguardar API inicializar
log "Aguardando API inicializar..."
sleep 20

# Verificar se API está funcionando
if run_docker "logs academia-data-api-prod --tail 10" | grep -q "API da Academia rodando"; then
    success "API iniciada com sucesso!"
else
    warn "API pode não estar funcionando. Verificando logs..."
    run_docker "logs academia-data-api-prod --tail 20"
fi

# Iniciar Dashboard
log "Iniciando Dashboard..."
run_docker "run -d --name academia-dashboard-prod \
  -p 80:80 \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/logs:/var/log/nginx \
  -e NGINX_HOST=localhost \
  -e NGINX_PORT=80 \
  -e NODE_ENV=production \
  academia-dashboard:latest"

# Aguardar dashboard inicializar
log "Aguardando dashboard inicializar..."
sleep 20

# 10. VERIFICAR STATUS FINAL
log "Status final dos containers:"
run_docker "ps"

# 11. VERIFICAR LOGS
log "Logs do dashboard:"
run_docker "logs academia-dashboard-prod --tail 15"

log "Logs da API:"
run_docker "logs academia-data-api-prod --tail 15"

# 12. TESTAR CONECTIVIDADE
log "Testando conectividade..."
sleep 10

# Testar API
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    success "✅ API está funcionando na porta 3000!"
else
    warn "⚠️  API não está respondendo na porta 3000"
fi

# Testar Dashboard
if curl -f http://localhost/health > /dev/null 2>&1; then
    success "✅ Dashboard está funcionando na porta 80!"
else
    warn "⚠️  Dashboard não está respondendo na porta 80"
fi

# 13. VERIFICAR PORTAS ABERTAS
log "Verificando portas abertas..."
netstat -tlnp | grep -E ":(80|3000)" || true

# 14. MOSTRAR IP PÚBLICO
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Não disponível")
log "IP público: $PUBLIC_IP"

success "Correção completa finalizada!"
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
