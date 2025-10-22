#!/bin/bash

# ========================================
# SCRIPT DE CONFIGURAÇÃO SSL/HTTPS
# Academia Dashboard - Let's Encrypt
# ========================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🔒 CONFIGURAÇÃO SSL                      ║"
echo "║                   Let's Encrypt + Nginx                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se está rodando como root
if [ "$EUID" -eq 0 ]; then
    error "Não execute como root. Use: sudo su - ubuntu"
    exit 1
fi

# Solicitar domínio
echo -e "${YELLOW}"
echo "📝 Digite seu domínio (ex: seudominio.com):"
echo -e "${NC}"
read -p "Domínio: " DOMAIN

if [ -z "$DOMAIN" ]; then
    error "Domínio é obrigatório!"
    exit 1
fi

log "Configurando SSL para: $DOMAIN"

# Atualizar sistema
log "Atualizando sistema..."
sudo apt update -y

# Instalar Certbot
log "Instalando Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Parar nginx temporariamente
log "Parando nginx..."
sudo systemctl stop nginx

# Configurar nginx para o domínio
log "Configurando nginx para $DOMAIN..."
sudo tee /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Dashboard
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Ativar configuração
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração nginx
sudo nginx -t

# Iniciar nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Obter certificado SSL
log "Obtendo certificado SSL do Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Configurar renovação automática
log "Configurando renovação automática..."
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

# Configurar nginx com SSL
log "Configurando nginx com SSL..."
sudo tee /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Dashboard
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Testar configuração
sudo nginx -t

# Recarregar nginx
sudo systemctl reload nginx

# Configurar firewall
log "Configurando firewall..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Verificar status
log "Verificando status do SSL..."
sudo systemctl status nginx
sudo certbot certificates

# Finalizar
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🎉 SSL CONFIGURADO! 🎉                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

success "SSL configurado com sucesso!"
log "🌐 Acesse seu site: https://$DOMAIN"
log "🔒 Certificado válido por 90 dias"
log "🔄 Renovação automática configurada"

log "📋 Comandos úteis:"
echo "  - Ver certificados: sudo certbot certificates"
echo "  - Renovar manualmente: sudo certbot renew"
echo "  - Ver logs: sudo tail -f /var/log/nginx/error.log"
echo "  - Testar SSL: curl -I https://$DOMAIN"

success "Seu site agora é seguro com HTTPS! 🔒"




