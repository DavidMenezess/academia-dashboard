#!/bin/bash

# Script compacto para AWS EC2
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
sleep 2

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

# Iniciar containers
cd /home/ubuntu/academia-dashboard/web-site
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Verificar status
sleep 10
docker ps

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
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable academia-dashboard.service

log "Configuração concluída!"






