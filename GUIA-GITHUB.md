# 📦 Guia para Subir no GitHub

Tutorial passo a passo para fazer upload do projeto Academia Dashboard no GitHub.

---

## ⚡ Setup Rápido (5 minutos)

```bash
# 1. Entre na pasta do projeto
cd academia-dashboard

# 2. Inicialize o Git
git init

# 3. Adicione todos os arquivos
git add .

# 4. Faça o primeiro commit
git commit -m "🎉 Primeiro commit - Academia Dashboard"

# 5. Crie repositório no GitHub
# Vá para: https://github.com/new

# 6. Conecte e envie
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/academia-dashboard.git
git push -u origin main
```

**🎉 Pronto! Seu projeto está no GitHub!**

---

## 📋 Pré-requisitos

1. **Git instalado**
   ```bash
   # Verificar
   git --version
   
   # Instalar se necessário
   # Windows: https://git-scm.com/download/win
   # Mac: brew install git
   # Linux: sudo apt install git
   ```

2. **Conta no GitHub**
   - Crie em: https://github.com/signup
   - Gratuito e ilimitado para projetos públicos

---

## 🚀 Passo a Passo Detalhado

### 1️⃣ Configure o Git (primeira vez)

```bash
# Seu nome
git config --global user.name "Seu Nome"

# Seu email
git config --global user.email "seu-email@exemplo.com"

# Verificar
git config --global --list
```

### 2️⃣ Inicialize o Repositório Local

```bash
# Entre na pasta do projeto
cd academia-dashboard

# Inicialize o Git
git init
```

### 3️⃣ Adicione os Arquivos

```bash
# Ver status
git status

# Adicionar todos os arquivos
git add .

# Ou adicionar específicos
git add README.md
git add web-site/
```

### 4️⃣ Faça o Primeiro Commit

```bash
git commit -m "🎉 Primeiro commit - Academia Dashboard organizado"
```

### 5️⃣ Crie o Repositório no GitHub

1. **Acesse**: https://github.com/new
2. **Repository name**: `academia-dashboard`
3. **Description**: `Dashboard moderno para gestão de academias com Terraform AWS (Free Tier)`
4. **Public** ✅
5. **NÃO marque**: Initialize with README (já temos um)
6. **Create repository**

### 6️⃣ Conecte ao GitHub

```bash
# Renomeie branch para main
git branch -M main

# Adicione o remote
git remote add origin https://github.com/SEU-USUARIO/academia-dashboard.git

# Verifique
git remote -v
```

### 7️⃣ Envie para o GitHub

```bash
# Primeira vez (com -u)
git push -u origin main

# Das próximas vezes (mais simples)
git push
```

**🎉 Pronto! Seu projeto está no GitHub!**

Acesse: `https://github.com/SEU-USUARIO/academia-dashboard`

---

## 🔐 Autenticação GitHub

### Método 1: Personal Access Token (Recomendado)

1. **Crie o token**: https://github.com/settings/tokens/new
2. **Scopes**: Marque `repo`
3. **Generate token**
4. **Copie o token** (você não verá novamente!)

**Ao fazer push:**
```bash
git push

# Username: seu-usuario
# Password: cole-o-token-aqui (não sua senha!)
```

### Método 2: SSH (Mais seguro)

```bash
# Gerar chave SSH
ssh-keygen -t ed25519 -C "seu-email@exemplo.com"

# Copiar chave pública
cat ~/.ssh/id_ed25519.pub

# Adicionar no GitHub:
# https://github.com/settings/ssh/new

# Mudar remote para SSH
git remote set-url origin git@github.com:SEU-USUARIO/academia-dashboard.git

# Push
git push
```

---

## 📝 Comandos Git Úteis

### Ver Status
```bash
git status
```

### Ver Histórico
```bash
git log
git log --oneline
```

### Adicionar Novos Arquivos
```bash
git add arquivo.txt
git add pasta/
git add .  # Todos
```

### Commit
```bash
git commit -m "Mensagem descritiva"
```

### Push (enviar)
```bash
git push
```

### Pull (baixar)
```bash
git pull
```

### Ver Diferenças
```bash
git diff
```

### Desfazer Mudanças
```bash
# Desfazer arquivo não commitado
git checkout -- arquivo.txt

# Desfazer último commit (mantém mudanças)
git reset --soft HEAD~1

# Desfazer último commit (remove mudanças)
git reset --hard HEAD~1
```

---

## 🌿 Workflow Recomendado

### Após Fazer Mudanças

```bash
# 1. Ver o que mudou
git status

# 2. Adicionar arquivos
git add .

# 3. Commit com mensagem clara
git commit -m "Descrição da mudança"

# 4. Enviar para GitHub
git push
```

### Trabalhando com Branches

```bash
# Criar branch
git checkout -b feature/nova-funcionalidade

# Fazer mudanças...
git add .
git commit -m "Adiciona nova funcionalidade"

# Push da branch
git push -u origin feature/nova-funcionalidade

# Voltar para main
git checkout main

# Merge (juntar) branch
git merge feature/nova-funcionalidade
```

---

## 🎨 Mensagens de Commit

### Padrão Recomendado

```bash
# Novos recursos
git commit -m "✨ Adiciona upload de Excel"

# Correções
git commit -m "🐛 Corrige bug no login"

# Documentação
git commit -m "📝 Atualiza README"

# Estilo/Formatação
git commit -m "💄 Melhora layout do dashboard"

# Refatoração
git commit -m "♻️ Refatora código da API"

# Performance
git commit -m "⚡ Otimiza queries do banco"

# Testes
git commit -m "✅ Adiciona testes unitários"

# Configuração
git commit -m "🔧 Atualiza config do Terraform"
```

---

## 📁 Arquivo .gitignore

Já criado e configurado para ignorar:

✅ `node_modules/` - Dependências Node.js  
✅ `logs/` - Arquivos de log  
✅ `data/*.backup.*` - Backups  
✅ `.terraform/` - Cache do Terraform  
✅ `terraform.tfstate` - Estado do Terraform  
✅ `*.tfvars` - Variáveis sensíveis  
✅ `*.pem` - Chaves SSH  
✅ `.env` - Variáveis de ambiente  

---

## 🔒 Segurança

### ⚠️ NUNCA faça commit de:

- ❌ Chaves SSH (`.pem`, `.key`)
- ❌ Credenciais AWS
- ❌ Tokens e senhas
- ❌ Arquivos `.env`
- ❌ `terraform.tfvars` (use `.example`)

### ✅ Se acidentalmente commitou algo sensível:

```bash
# Remover do histórico
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch arquivo-secreto.txt' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (cuidado!)
git push origin --force --all

# MELHOR: Considere criar novo repositório
```

---

## 🚨 Solução de Problemas

### ❌ Erro: "Permission denied"
```bash
# Use token de acesso ou SSH
# Veja seção "Autenticação GitHub"
```

### ❌ Erro: "Remote already exists"
```bash
# Remova e adicione novamente
git remote remove origin
git remote add origin https://github.com/SEU-USUARIO/academia-dashboard.git
```

### ❌ Erro: "Merge conflict"
```bash
# 1. Veja os arquivos em conflito
git status

# 2. Edite os arquivos manualmente
# 3. Marque como resolvido
git add arquivo-conflito.txt

# 4. Complete o merge
git commit
```

### ❌ Arquivos grandes (> 100MB)
```bash
# GitHub não aceita arquivos > 100MB
# Solução: Use Git LFS ou remova o arquivo

# Instalar Git LFS
git lfs install

# Adicionar tipo de arquivo ao LFS
git lfs track "*.zip"

# Commit e push
git add .gitattributes
git commit -m "Configura Git LFS"
git push
```

---

## 📊 Estrutura do Projeto no GitHub

```
academia-dashboard/
├── .gitignore                  # Arquivos ignorados
├── README.md                   # Documentação principal
├── GUIA-GITHUB.md             # Este guia
└── web-site/
    ├── DEPLOY-LOCAL.md        # Guia deploy local
    ├── DEPLOY-AWS.md          # Guia deploy AWS
    ├── docker-compose.yml     # Config Docker
    ├── docker-compose.prod.yml
    ├── Dockerfile
    ├── src/                   # Frontend
    ├── api/                   # Backend
    ├── config/                # Configs
    ├── scripts/               # Scripts
    ├── data/                  # Dados (ignorado backups)
    ├── logs/                  # Logs (ignorado)
    └── terraform/             # Infraestrutura
        ├── README.md
        ├── *.tf               # Arquivos Terraform
        ├── terraform.tfvars.example
        └── scripts/
```

---

## 🎯 Próximos Passos

1. ✅ **Push para GitHub** (você está aqui!)
2. 📝 **Adicione descrição** no repositório
3. 🏷️ **Adicione topics**: `terraform`, `aws`, `docker`, `dashboard`
4. 📄 **Configure GitHub Pages** (se tiver docs)
5. 🤖 **Configure GitHub Actions** para CI/CD
6. ⭐ **Adicione estrela** no próprio projeto (por que não? 😄)

---

## 🚀 Como Usar o Projeto (Nova Estrutura)

Após fazer o clone do repositório, aqui estão os comandos atualizados para a nova estrutura:

### 🏠 **Deploy Local**

```bash
# Clone o repositório
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard

# Entre na pasta web-site
cd web-site

# Inicie os containers
docker-compose up -d

# Acesse o dashboard
# http://localhost:8080
```

### ☁️ **Deploy AWS com Terraform**

```bash
# Clone o repositório
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard

# Configure suas credenciais AWS
aws configure

# Entre na pasta do Terraform
cd web-site/terraform

# Configure suas variáveis
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edite com suas informações

# Execute o deploy
terraform init
terraform plan
terraform apply

# Aguarde 5 minutos e acesse o IP fornecido!
```

### 📖 **Guias Detalhados**

- **Deploy Local**: Veja `web-site/DEPLOY-LOCAL.md`
- **Deploy AWS**: Veja `web-site/DEPLOY-AWS.md`
- **Terraform**: Veja `web-site/terraform/README.md`

---

## 🤝 Colaboração

### Convidar Colaboradores

1. Repositório → Settings → Collaborators
2. Add people → Digite username
3. Envie convite

### Pull Requests

```bash
# 1. Fork o repositório
# 2. Clone seu fork
git clone https://github.com/SEU-USUARIO/academia-dashboard.git

# 3. Crie uma branch
git checkout -b minha-feature

# 4. Faça mudanças e commit
git add .
git commit -m "Minha contribuição"

# 5. Push
git push origin minha-feature

# 6. Abra Pull Request no GitHub
```

---

## 📱 GitHub Mobile

Baixe o app GitHub para iOS/Android:
- Ver repositórios
- Fazer commits
- Revisar pull requests
- Gerenciar issues

---

## 💡 Dicas Pro

### Aliases Úteis
```bash
# Adicione ao ~/.gitconfig

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    pl = pull
    ps = push
    lg = log --oneline --graph --decorate
```

### Uso:
```bash
git st     # ao invés de git status
git ci -m  # ao invés de git commit -m
```

---

## 📚 Recursos de Aprendizado

- **Git**: https://git-scm.com/doc
- **GitHub Docs**: https://docs.github.com/
- **Git Cheat Sheet**: https://training.github.com/
- **Learn Git Branching**: https://learngitbranching.js.org/

---

## 📞 Suporte

- **Git**: https://git-scm.com/community
- **GitHub**: https://support.github.com/
- **Stack Overflow**: Tag `git` ou `github`

---

**🎉 Parabéns! Seu projeto está profissional e versionado no GitHub!**

**🔗 Compartilhe:** `https://github.com/SEU-USUARIO/academia-dashboard`

**⭐ Estrelas são bem-vindas!**

