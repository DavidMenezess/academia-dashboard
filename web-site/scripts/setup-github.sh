#!/bin/bash

# 📤 Script para Configurar GitHub - Academia Dashboard
# Automatiza o processo de upload para GitHub

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para log
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
echo "║                    📤 SETUP GITHUB                           ║"
echo "║                Academia Dashboard Upload                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se Git está instalado
if ! command -v git &> /dev/null; then
    error "Git não está instalado!"
    echo "Instale Git primeiro:"
    echo "Windows: https://git-scm.com/download/win"
    echo "Mac: brew install git"
    echo "Linux: sudo apt install git"
    exit 1
fi

success "Git está instalado"

# Verificar se estamos no diretório correto
if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.yml" ]; then
    error "Execute este script na pasta web-site do projeto!"
    echo "Navegue para: cd web-site"
    exit 1
fi

# Solicitar informações do usuário
echo -e "${YELLOW}"
echo "📝 Preciso de algumas informações para configurar o GitHub:"
echo -e "${NC}"

read -p "Seu nome completo: " USER_NAME
read -p "Seu email do GitHub: " USER_EMAIL
read -p "Seu username do GitHub: " GITHUB_USERNAME
read -p "Nome do repositório [academia-dashboard]: " REPO_NAME
REPO_NAME=${REPO_NAME:-academia-dashboard}

# Configurar Git
log "Configurando Git..."
git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"
success "Git configurado"

# Inicializar repositório se não existir
if [ ! -d ".git" ]; then
    log "Inicializando repositório Git..."
    git init
    success "Repositório Git inicializado"
fi

# Criar .gitignore se não existir
if [ ! -f ".gitignore" ]; then
    log "Criando .gitignore..."
    cat > .gitignore << 'EOF'
# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory
coverage/

# Dependency directories
node_modules/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test
.env.production

# Docker
.dockerignore
docker-compose.override.yml

# Backup files
*.backup
*.bak
*.tmp

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# SSL certificates
ssl/
*.pem
*.key
*.crt

# Data files (manter apenas exemplo)
data/*.json
!data/academia_data.json.example

# Uploads temporários
uploads/
temp/
EOF
    success ".gitignore criado"
fi

# Criar README principal se não existir
if [ ! -f "../README.md" ]; then
    log "Criando README principal..."
    cat > ../README.md << EOF
# 🏋️ Academia Dashboard

Dashboard moderno para gestão de academia com dados em tempo real, containerizado e pronto para produção.

## 🚀 Características

- ✅ **Interface Moderna**: Dashboard responsivo com design profissional
- ✅ **Containerizado**: Deploy fácil com Docker
- ✅ **Upload de Dados**: Sistema de upload de arquivos Excel/CSV
- ✅ **Acesso Externo**: Configurado para acesso via internet
- ✅ **Performance**: Otimizado com Nginx e cache
- ✅ **Monitoramento**: Health checks e logs

## 📁 Estrutura do Projeto

\`\`\`
academia-dashboard/
├── web-site/                    # Projeto principal
│   ├── src/                    # Código fonte
│   ├── api/                    # API backend
│   ├── data/                   # Dados da academia
│   ├── config/                 # Configurações
│   ├── scripts/                # Scripts de automação
│   ├── Dockerfile              # Containerização
│   ├── docker-compose.yml      # Desenvolvimento
│   ├── docker-compose.aws.yml  # Produção AWS
│   └── README.md               # Documentação
└── README.md                   # Este arquivo
\`\`\`

## 🛠️ Como Usar

### 1. Desenvolvimento Local

\`\`\`bash
cd web-site
docker-compose up --build -d
\`\`\`

### 2. Deploy na AWS

\`\`\`bash
# Deploy automatizado
curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/scripts/deploy-aws.sh | bash
\`\`\`

### 3. Upload de Dados

- Acesse o dashboard
- Use a seção "📊 Atualizar Dados da Academia"
- Faça upload de arquivos Excel (.xlsx, .xls) ou CSV (.csv)
- Dados são atualizados automaticamente

## 📊 Funcionalidades

- **Dashboard Responsivo**: Interface moderna e intuitiva
- **Upload de Arquivos**: Excel e CSV com processamento automático
- **API RESTful**: Backend robusto para processamento de dados
- **Containerização**: Docker para fácil deploy
- **Monitoramento**: Health checks e logs detalhados
- **Segurança**: Headers de segurança e validação
- **Escalabilidade**: Pronto para crescimento

## 🌐 Deploy

### AWS (Free Tier)
- EC2 t2.micro
- Docker containers
- Nginx proxy
- SSL com Let's Encrypt
- Monitoramento automático

### Kubernetes
- Deploy via k3d/k3s
- Configurações YAML inclusas
- Load balancing
- Auto scaling

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs: \`docker logs academia-dashboard\`
2. Teste o health check: \`curl http://localhost/health\`
3. Consulte a documentação em \`web-site/README.md\`

---

**Desenvolvido com ❤️ para gestão de academias**

## 📄 Licença

MIT License - veja o arquivo LICENSE para detalhes.
EOF
    success "README principal criado"
fi

# Adicionar todos os arquivos
log "Adicionando arquivos ao Git..."
git add .
success "Arquivos adicionados"

# Fazer commit inicial
log "Fazendo commit inicial..."
git commit -m "Initial commit: Academia Dashboard completo

- Dashboard responsivo com interface moderna
- Sistema de upload de Excel/CSV
- API backend em Node.js
- Containerização com Docker
- Configurações para AWS (Free Tier)
- Scripts de deploy automatizado
- Monitoramento e backup
- Documentação completa

Funcionalidades:
✅ Upload de arquivos Excel/CSV
✅ Processamento automático de dados
✅ Dashboard em tempo real
✅ Deploy automatizado na AWS
✅ SSL/HTTPS configurável
✅ Monitoramento 24/7"
success "Commit inicial realizado"

# Mostrar status
log "Status do repositório:"
git status

echo -e "${YELLOW}"
echo "📋 Próximos passos:"
echo "1. Acesse: https://github.com/new"
echo "2. Crie um repositório chamado: $REPO_NAME"
echo "3. Execute os comandos abaixo:"
echo -e "${NC}"

echo -e "${GREEN}"
echo "# Conectar com GitHub:"
echo "git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo "git branch -M main"
echo "git push -u origin main"
echo -e "${NC}"

echo -e "${BLUE}"
echo "🎯 Após fazer o push, você poderá usar:"
echo "curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/scripts/deploy-aws.sh | bash"
echo -e "${NC}"

# Criar script de push automático
cat > push-to-github.sh << EOF
#!/bin/bash
# Script para fazer push para GitHub

echo "🚀 Fazendo push para GitHub..."

# Verificar se remote existe
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "❌ Remote origin não configurado!"
    echo "Execute primeiro:"
    echo "git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    exit 1
fi

# Fazer push
git push origin main

echo "✅ Push concluído!"
echo "🌐 Repositório: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
EOF

chmod +x push-to-github.sh
success "Script de push criado: ./push-to-github.sh"

# Criar script para atualizações futuras
cat > update-github.sh << EOF
#!/bin/bash
# Script para atualizar o repositório GitHub

echo "🔄 Atualizando repositório GitHub..."

# Adicionar mudanças
git add .

# Commit com data/hora
git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')"

# Push
git push origin main

echo "✅ Atualização concluída!"
EOF

chmod +x update-github.sh
success "Script de atualização criado: ./update-github.sh"

# Mostrar resumo
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🎉 SETUP CONCLUÍDO! 🎉                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

success "Configuração do GitHub concluída!"
log "📁 Arquivos preparados para upload"
log "📝 Commit inicial realizado"
log "🔧 Scripts de automação criados"

echo -e "${YELLOW}"
echo "📋 Checklist final:"
echo "1. ✅ Git configurado"
echo "2. ✅ Repositório inicializado"
echo "3. ✅ Arquivos commitados"
echo "4. ⏳ Criar repositório no GitHub"
echo "5. ⏳ Fazer push dos arquivos"
echo -e "${NC}"

echo -e "${BLUE}"
echo "🚀 Comandos para executar agora:"
echo "1. Acesse: https://github.com/new"
echo "2. Crie repositório: $REPO_NAME"
echo "3. Execute: ./push-to-github.sh"
echo -e "${NC}"

log "Script concluído com sucesso!"

