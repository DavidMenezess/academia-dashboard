#!/bin/bash
set -e

# Log simples
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

# Redirecionar output
exec > >(tee -a /var/log/user-data.log) 2>&1

log "Iniciando configuração..."

# Atualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Instalar dependências essenciais
apt-get install -y curl wget git unzip

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configurar usuário docker
usermod -aG docker ubuntu
sleep 5

# Clonar repositório
cd /home/ubuntu
git clone https://github.com/DavidMenezess/academia-dashboard.git
chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard

# Configurar variáveis de ambiente
cat > /home/ubuntu/academia-dashboard/web-site/.env << EOF
DATABASE_TYPE=dynamodb
AWS_REGION=${aws_region}
DYNAMODB_TABLE=academia-dashboard-prod
AWS_USE_IAM_ROLE=true
EOF

# Configurar permissões
chown ubuntu:ubuntu /home/ubuntu/academia-dashboard/web-site/.env

# Navegar para o projeto
cd /home/ubuntu/academia-dashboard/web-site

# Criar diretórios necessários
mkdir -p data logs api/uploads

# Criar dados iniciais
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

# Instalar dependências da API
if [ -d "api" ]; then
    cd api
    npm install --production
    cd ..
fi

# Limpar containers
docker system prune -f || true

# Usar docker-compose.prod.yml (arquivo original)
COMPOSE_FILE="docker-compose.prod.yml"

log "Usando arquivo: $COMPOSE_FILE"

# Fazer build e iniciar containers
docker-compose -f $COMPOSE_FILE down || true
docker-compose -f $COMPOSE_FILE build --no-cache
docker-compose -f $COMPOSE_FILE up -d

# Aguardar inicialização
log "Aguardando containers iniciarem..."
sleep 60

# Verificar status
log "Status dos containers:"
docker ps

# Verificar e reiniciar se necessário
for i in {1..3}; do
    log "Verificação $i/3..."
    
    dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
    api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")
    
    if [ "$dashboard_running" = "no" ]; then
        log "Dashboard não está rodando, reiniciando..."
        docker-compose -f $COMPOSE_FILE restart academia-dashboard
        sleep 30
    fi
    
    if [ "$api_running" = "no" ]; then
        log "API não está rodando, reiniciando..."
        docker-compose -f $COMPOSE_FILE restart data-api
        sleep 30
    fi
    
    # Se ambos estão rodando, sair do loop
    if [ "$dashboard_running" = "yes" ] && [ "$api_running" = "yes" ]; then
        log "Todos os containers estão rodando!"
        break
    fi
    
    sleep 15
done

# Testar conectividade
log "Testando conectividade..."
sleep 20

if curl -s http://localhost > /dev/null; then
    log "✅ Dashboard funcionando!"
else
    log "⚠️ Dashboard não respondeu"
    docker logs academia-dashboard-prod --tail 10
fi

if curl -s http://localhost:3000/health > /dev/null; then
    log "✅ API funcionando!"
else
    log "⚠️ API não respondeu"
    docker logs academia-data-api-prod --tail 10
fi

# Criar serviço systemd
cat > /etc/systemd/system/academia-dashboard.service << EOF
[Unit]
Description=Academia Dashboard
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/academia-dashboard/web-site
ExecStart=/usr/local/bin/docker-compose -f $COMPOSE_FILE up -d
ExecStop=/usr/local/bin/docker-compose -f $COMPOSE_FILE down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable academia-dashboard.service

log "Configuração concluída!"
