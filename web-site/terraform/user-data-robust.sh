#!/bin/bash
set -e

# Log detalhado
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

# Redirecionar output
exec > >(tee -a /var/log/user-data.log) 2>&1

log "=== INICIANDO CONFIGURAÇÃO ROBUSTA ==="

# Atualizar sistema
export DEBIAN_FRONTEND=noninteractive
log "Atualizando sistema..."
apt-get update -y
apt-get upgrade -y

# Instalar dependências essenciais
log "Instalando dependências..."
apt-get install -y curl wget git unzip htop

# Instalar Docker
log "Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Instalar Docker Compose
log "Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configurar usuário docker
usermod -aG docker ubuntu
sleep 10

# Clonar repositório
log "Clonando repositório..."
cd /home/ubuntu
git clone https://github.com/DavidMenezess/academia-dashboard.git
chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard

# Configurar variáveis de ambiente
log "Configurando variáveis de ambiente..."
cat > /home/ubuntu/academia-dashboard/web-site/.env << EOF
DATABASE_TYPE=dynamodb
AWS_REGION=${aws_region}
DYNAMODB_TABLE=academia-dashboard-prod
AWS_USE_IAM_ROLE=true
EOF

chown ubuntu:ubuntu /home/ubuntu/academia-dashboard/web-site/.env

# Navegar para o projeto
cd /home/ubuntu/academia-dashboard/web-site

# Criar diretórios necessários
log "Criando diretórios..."
mkdir -p data logs api/uploads
chown -R ubuntu:ubuntu data logs api/uploads

# Criar dados iniciais
log "Criando dados iniciais..."
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
log "Instalando dependências da API..."
if [ -d "api" ]; then
    cd api
    npm install --production
    cd ..
fi

# Limpar containers existentes
log "Limpando containers existentes..."
docker system prune -f || true
docker-compose -f docker-compose.prod.yml down || true

# Aguardar Docker estar pronto
log "Aguardando Docker estar pronto..."
sleep 15

# Fazer build e iniciar containers
log "Fazendo build dos containers..."
docker-compose -f docker-compose.prod.yml build --no-cache

log "Iniciando containers..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar inicialização
log "Aguardando containers iniciarem..."
sleep 90

# Verificar status inicial
log "Status inicial dos containers:"
docker ps

# Função para verificar e reiniciar containers
check_and_restart_containers() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Verificação $attempt/$max_attempts..."
        
        # Verificar se containers estão rodando
        dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
        api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")
        
        log "Dashboard: $dashboard_running, API: $api_running"
        
        # Reiniciar se necessário
        if [ "$dashboard_running" = "no" ]; then
            log "Dashboard não está rodando, reiniciando..."
            docker-compose -f docker-compose.prod.yml restart academia-dashboard || true
            sleep 30
        fi
        
        if [ "$api_running" = "no" ]; then
            log "API não está rodando, reiniciando..."
            docker-compose -f docker-compose.prod.yml restart data-api || true
            sleep 30
        fi
        
        # Verificar novamente
        dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
        api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")
        
        # Se ambos estão rodando, sair do loop
        if [ "$dashboard_running" = "yes" ] && [ "$api_running" = "yes" ]; then
            log "✅ Todos os containers estão rodando!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 20
    done
    
    log "⚠️ Alguns containers não conseguiram iniciar após $max_attempts tentativas"
    return 1
}

# Executar verificação
check_and_restart_containers

# Testar conectividade
log "Testando conectividade..."
sleep 30

# Testar dashboard
if curl -s http://localhost > /dev/null; then
    log "✅ Dashboard funcionando!"
else
    log "⚠️ Dashboard não respondeu"
    docker logs academia-dashboard-prod --tail 20 || true
fi

# Testar API
if curl -s http://localhost:3000/health > /dev/null; then
    log "✅ API funcionando!"
else
    log "⚠️ API não respondeu"
    docker logs academia-data-api-prod --tail 20 || true
fi

# Criar serviço systemd para reinicialização automática
log "Criando serviço systemd..."
cat > /etc/systemd/system/academia-dashboard.service << EOF
[Unit]
Description=Academia Dashboard
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/academia-dashboard/web-site
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
User=ubuntu
Group=ubuntu
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Criar script de monitoramento
cat > /home/ubuntu/academia-dashboard/web-site/monitor-containers.sh << 'EOF'
#!/bin/bash
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

cd /home/ubuntu/academia-dashboard/web-site

# Verificar containers
dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")

if [ "$dashboard_running" = "no" ] || [ "$api_running" = "no" ]; then
    log "Containers não estão rodando, reiniciando..."
    docker-compose -f docker-compose.prod.yml up -d
    sleep 30
fi
EOF

chmod +x /home/ubuntu/academia-dashboard/web-site/monitor-containers.sh
chown ubuntu:ubuntu /home/ubuntu/academia-dashboard/web-site/monitor-containers.sh

# Configurar cron job para monitoramento
echo "*/5 * * * * /home/ubuntu/academia-dashboard/web-site/monitor-containers.sh >> /var/log/container-monitor.log 2>&1" | crontab -u ubuntu -

# Habilitar e iniciar serviço
systemctl daemon-reload
systemctl enable academia-dashboard.service
systemctl start academia-dashboard.service

# Status final
log "=== STATUS FINAL ==="
docker ps
log "Configuração robusta concluída!"

# Criar script de diagnóstico
cat > /home/ubuntu/academia-dashboard/web-site/diagnose.sh << 'EOF'
#!/bin/bash
echo "=== DIAGNÓSTICO ACADEMIA DASHBOARD ==="
echo "Data: $(date)"
echo ""
echo "=== DOCKER STATUS ==="
docker ps -a
echo ""
echo "=== DOCKER COMPOSE STATUS ==="
cd /home/ubuntu/academia-dashboard/web-site
docker-compose -f docker-compose.prod.yml ps
echo ""
echo "=== SYSTEMD STATUS ==="
systemctl status academia-dashboard.service
echo ""
echo "=== LOGS DASHBOARD ==="
docker logs academia-dashboard-prod --tail 10
echo ""
echo "=== LOGS API ==="
docker logs academia-data-api-prod --tail 10
echo ""
echo "=== CONECTIVIDADE ==="
curl -s http://localhost > /dev/null && echo "Dashboard: OK" || echo "Dashboard: FALHA"
curl -s http://localhost:3000/health > /dev/null && echo "API: OK" || echo "API: FALHA"
EOF

chmod +x /home/ubuntu/academia-dashboard/web-site/diagnose.sh
chown ubuntu:ubuntu /home/ubuntu/academia-dashboard/web-site/diagnose.sh

log "=== CONFIGURAÇÃO ROBUSTA CONCLUÍDA ==="