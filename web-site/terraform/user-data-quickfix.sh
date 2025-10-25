#!/bin/bash
set -e

# Log detalhado
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

# Redirecionar output
exec > >(tee -a /var/log/user-data.log) 2>&1

log "=== INICIANDO CONFIGURAÇÃO COM QUICK-FIX ==="

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
sleep 15

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
cd /home/ubuntu/academia-dashboard

# Tornar o script quick-fix.sh executável
log "Configurando script quick-fix.sh..."
chmod +x quick-fix.sh

# Executar o script quick-fix.sh
log "Executando quick-fix.sh..."
./quick-fix.sh

# Aguardar um pouco mais para garantir que tudo está funcionando
log "Aguardando estabilização..."
sleep 30

# Verificar status final
log "Status final dos containers:"
docker ps

# Testar conectividade
log "Testando conectividade..."
if curl -s http://localhost > /dev/null; then
    log "✅ Dashboard funcionando!"
else
    log "⚠️ Dashboard não respondeu"
    docker logs academia-dashboard-prod --tail 10 || true
fi

if curl -s http://localhost:3000/health > /dev/null; then
    log "✅ API funcionando!"
else
    log "⚠️ API não respondeu"
    docker logs academia-data-api-prod --tail 10 || true
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
WorkingDirectory=/home/ubuntu/academia-dashboard
ExecStart=/home/ubuntu/academia-dashboard/quick-fix.sh
ExecStop=/usr/local/bin/docker-compose -f /home/ubuntu/academia-dashboard/web-site/docker-compose.prod.yml down
User=ubuntu
Group=ubuntu
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Criar script de monitoramento
cat > /home/ubuntu/academia-dashboard/monitor-containers.sh << 'EOF'
#!/bin/bash
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

cd /home/ubuntu/academia-dashboard

# Verificar containers
dashboard_running=$(docker ps | grep -q "academia-dashboard-prod" && echo "yes" || echo "no")
api_running=$(docker ps | grep -q "academia-data-api-prod" && echo "yes" || echo "no")

if [ "$dashboard_running" = "no" ] || [ "$api_running" = "no" ]; then
    log "Containers não estão rodando, executando quick-fix.sh..."
    ./quick-fix.sh
    sleep 30
fi
EOF

chmod +x /home/ubuntu/academia-dashboard/monitor-containers.sh
chown ubuntu:ubuntu /home/ubuntu/academia-dashboard/monitor-containers.sh

# Configurar cron job para monitoramento
echo "*/5 * * * * /home/ubuntu/academia-dashboard/monitor-containers.sh >> /var/log/container-monitor.log 2>&1" | crontab -u ubuntu -

# Habilitar e iniciar serviço
systemctl daemon-reload
systemctl enable academia-dashboard.service
systemctl start academia-dashboard.service

# Status final
log "=== STATUS FINAL ==="
docker ps
log "Configuração com quick-fix concluída!"

# Criar script de diagnóstico
cat > /home/ubuntu/academia-dashboard/diagnose.sh << 'EOF'
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

chmod +x /home/ubuntu/academia-dashboard/diagnose.sh
chown ubuntu:ubuntu /home/ubuntu/academia-dashboard/diagnose.sh

log "=== CONFIGURAÇÃO COM QUICK-FIX CONCLUÍDA ==="
