#!/bin/bash

# ========================================
# SCRIPT DE SETUP - TERRAFORM
# Academia Dashboard - AWS Free Tier
# ========================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

success() {
    echo -e "${BLUE}[SUCESSO]${NC} $1"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════╗
║   ACADEMIA DASHBOARD - SETUP TERRAFORM        ║
║   Infraestrutura como Código - AWS Free Tier  ║
╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar pré-requisitos
log "Verificando pré-requisitos..."

# Verificar Terraform
if ! command -v terraform &> /dev/null; then
    error "Terraform não está instalado!"
    echo "Instale o Terraform: https://www.terraform.io/downloads"
    exit 1
fi
success "Terraform $(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4) encontrado"

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    error "AWS CLI não está instalado!"
    echo "Instale o AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi
success "AWS CLI $(aws --version | cut -d' ' -f1 | cut -d'/' -f2) encontrado"

# Verificar credenciais AWS
log "Verificando credenciais AWS..."
if ! aws sts get-caller-identity &> /dev/null; then
    error "Credenciais AWS não configuradas!"
    echo ""
    echo "Configure com: aws configure"
    echo "Você precisará de:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Default region (ex: us-east-1)"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_USER=$(aws sts get-caller-identity --query Arn --output text | cut -d'/' -f2)
AWS_REGION=$(aws configure get region)

success "Credenciais configuradas:"
echo "  - Conta AWS: $AWS_ACCOUNT"
echo "  - Usuário: $AWS_USER"
echo "  - Região: $AWS_REGION"

# Verificar se terraform.tfvars existe
if [ ! -f terraform.tfvars ]; then
    warn "Arquivo terraform.tfvars não encontrado"
    
    read -p "Deseja criar a partir do exemplo? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        cp terraform.tfvars.example terraform.tfvars
        success "Arquivo terraform.tfvars criado"
        warn "IMPORTANTE: Edite terraform.tfvars antes de continuar!"
        
        # Perguntar dados básicos
        echo ""
        log "Vamos configurar alguns valores básicos..."
        
        # Descobrir IP público
        PUBLIC_IP=$(curl -s ifconfig.me)
        if [ -n "$PUBLIC_IP" ]; then
            log "Seu IP público detectado: $PUBLIC_IP"
            read -p "Usar este IP para SSH? (S/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                sed -i.bak "s|your_ip = \"0.0.0.0/32\"|your_ip = \"$PUBLIC_IP/32\"|" terraform.tfvars
                success "IP configurado em terraform.tfvars"
            fi
        fi
        
        # Nome da chave SSH
        read -p "Nome da chave SSH AWS (padrão: academia-dashboard-key): " KEY_NAME
        KEY_NAME=${KEY_NAME:-academia-dashboard-key}
        sed -i.bak "s|key_name = \"academia-dashboard-key\"|key_name = \"$KEY_NAME\"|" terraform.tfvars
        
        # Região AWS
        read -p "Região AWS (padrão: us-east-1): " REGION
        REGION=${REGION:-us-east-1}
        sed -i.bak "s|aws_region = \"us-east-1\"|aws_region = \"$REGION\"|" terraform.tfvars
        
        # URL do GitHub (opcional)
        read -p "URL do repositório GitHub (opcional, Enter para pular): " GITHUB_URL
        if [ -n "$GITHUB_URL" ]; then
            sed -i.bak "s|github_repo = \"\"|github_repo = \"$GITHUB_URL\"|" terraform.tfvars
        fi
        
        rm -f terraform.tfvars.bak
        success "Configuração inicial concluída!"
    else
        error "Você precisa criar terraform.tfvars antes de continuar"
        exit 1
    fi
else
    success "Arquivo terraform.tfvars encontrado"
fi

# Verificar/criar chave SSH
KEY_NAME=$(grep 'key_name' terraform.tfvars | cut -d'"' -f2)
log "Verificando chave SSH: $KEY_NAME"

if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
    warn "Chave SSH '$KEY_NAME' não encontrada na AWS"
    
    read -p "Deseja criar esta chave agora? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        aws ec2 create-key-pair \
            --key-name "$KEY_NAME" \
            --query 'KeyMaterial' \
            --output text > "${KEY_NAME}.pem"
        
        chmod 400 "${KEY_NAME}.pem"
        success "Chave SSH criada: ${KEY_NAME}.pem"
        warn "IMPORTANTE: Guarde este arquivo em local seguro!"
    else
        error "Você precisa criar a chave SSH '$KEY_NAME' antes de continuar"
        echo "Crie em: https://console.aws.amazon.com/ec2/ > Key Pairs"
        exit 1
    fi
else
    success "Chave SSH '$KEY_NAME' encontrada na AWS"
fi

# Inicializar Terraform
log "Inicializando Terraform..."
terraform init
success "Terraform inicializado!"

# Validar configuração
log "Validando configuração..."
if terraform validate; then
    success "Configuração válida!"
else
    error "Erro na configuração. Corrija e tente novamente."
    exit 1
fi

# Formatar código
log "Formatando código Terraform..."
terraform fmt -recursive

# Verificar Free Tier
echo ""
warn "ATENÇÃO: Verifique seus limites do Free Tier antes de continuar!"
echo "Acesse: https://console.aws.amazon.com/billing/home#/freetier"
echo ""
echo "Recursos que serão criados:"
echo "  ✓ EC2 t2.micro (750 horas/mês grátis)"
echo "  ✓ EBS 20GB (30GB/mês grátis)"
echo "  ✓ 1 Elastic IP (grátis quando anexado)"
echo "  ✓ VPC/Security Group (grátis)"
echo ""

# Planejar deployment
read -p "Deseja ver o plano de deployment? (S/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    terraform plan
fi

# Confirmar deploy
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Pronto para fazer o deploy!                  ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo ""
read -p "Deseja aplicar a infraestrutura agora? (s/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[SsYy]$ ]]; then
    log "Iniciando deployment..."
    terraform apply -auto-approve
    
    echo ""
    success "╔═══════════════════════════════════════════════╗"
    success "║  DEPLOY CONCLUÍDO COM SUCESSO!                ║"
    success "╚═══════════════════════════════════════════════╝"
    echo ""
    
    # Mostrar informações importantes
    PUBLIC_IP=$(terraform output -raw public_ip 2>/dev/null || echo "N/A")
    DASHBOARD_URL=$(terraform output -raw dashboard_url 2>/dev/null || echo "N/A")
    
    echo -e "${GREEN}Informações importantes:${NC}"
    echo "  IP Público: $PUBLIC_IP"
    echo "  Dashboard: $DASHBOARD_URL"
    echo "  SSH: ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
    echo ""
    warn "Aguarde 2-3 minutos para a aplicação inicializar completamente"
    echo ""
    echo "Para ver todos os outputs:"
    echo "  terraform output"
    echo ""
    echo "Para conectar via SSH:"
    echo "  terraform output ssh_command"
else
    log "Deploy cancelado pelo usuário"
    echo ""
    echo "Para fazer o deploy manualmente:"
    echo "  terraform apply"
fi

echo ""
success "Setup concluído!"










