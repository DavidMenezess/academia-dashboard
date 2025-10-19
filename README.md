# 🏋️ Academia Dashboard

Dashboard moderno para gestão de academias com upload de dados via Excel/CSV e deploy automatizado na AWS usando Terraform.

> **⚠️ Projeto de Estudo** - Configurado 100% para AWS Free Tier (sem custos)

---

## 🚀 Deploy Rápido

### **Local (no seu computador)** 

```bash
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard/web-site
docker-compose up -d
```
**Pronto!** Acesse: http://localhost:8080

### **AWS (com Terraform - acesso mundial)** 

```bash
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard/web-site/terraform
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com suas informações
terraform init
terraform plan
terraform apply
```
**Aguarde 5 minutos** e acesse o IP fornecido!

📖 **Guias Detalhados:**
- [Deploy Local](web-site/DEPLOY-LOCAL.md)
- [Deploy AWS com Terraform](web-site/DEPLOY-AWS.md)

---

## ✨ Funcionalidades

✅ Dashboard responsivo e moderno  
✅ Upload de dados via Excel/CSV  
✅ API REST backend (Node.js)  
✅ Containerizado com Docker  
✅ Deploy automatizado (Terraform)  
✅ CI/CD com GitHub Actions (build, testes, deploy por OIDC)
✅ 100% AWS Free Tier  
✅ Monitoramento com health checks  

---

## 📁 Estrutura do Projeto

```
academia-dashboard/
├── .gitignore            # Ignora arquivos sensíveis e artefatos
├── .github/workflows/    # Pipelines de CI/CD
├── README.md             # Documentação principal
├── GUIA-GITHUB.md        # Tutorial para GitHub
├── ORGANIZACAO-COMPLETA.md # Resumo das melhorias
│
└── web-site/             # Aplicação principal
    ├── DEPLOY-LOCAL.md   # Guia deploy local
    ├── DEPLOY-AWS.md     # Guia deploy AWS
    ├── docker-compose.yml    # Deploy local
    ├── docker-compose.prod.yml # Deploy produção
    ├── Dockerfile        # Containerização
    │
    ├── src/              # Frontend (HTML/CSS/JS)
    ├── api/              # Backend API (Node.js)
    ├── config/           # Nginx configs
    ├── data/             # Dados persistentes
    ├── logs/             # Logs (ignorado)
    ├── scripts/          # Scripts de automação
    │
    └── terraform/        # Infraestrutura AWS
        ├── README.md     # Documentação Terraform
        ├── *.tf          # Arquivos Terraform
        ├── terraform.tfvars.example
        └── scripts/      # Scripts auxiliares

---

## 🔄 CI/CD (GitHub Actions)

### CI (automático)
- Valida Dockerfile e docker-compose
- Roda smoke test da API (`/health`)
- Valida Terraform (`fmt` e `validate`)

Arquivo: `.github/workflows/ci.yml`

### CD (manual, seguro e Free Tier)
- Build e push da imagem para GHCR
- Assume Role via OIDC e roda `terraform plan/apply/destroy`

Arquivo: `.github/workflows/cd.yml`

### Configuração necessária
- Secret `AWS_ROLE_ARN` com o ARN do Role da AWS para OIDC
- GHCR habilitado (utiliza `GITHUB_TOKEN` por padrão)
```

---

## 🛠️ Tecnologias

- **Frontend**: HTML5, CSS3, JavaScript
- **Backend**: Node.js, Express
- **Banco**: JSON (arquivo)
- **Container**: Docker, Docker Compose
- **Infraestrutura**: Terraform
- **Cloud**: AWS (EC2, EIP)
- **Servidor Web**: Nginx

---

## 💰 Custos AWS Free Tier

Este projeto foi configurado para **NÃO GERAR CUSTOS** usando o Free Tier da AWS:

✅ **750 horas/mês** de EC2 t2.micro (grátis por 12 meses)  
✅ **30 GB** de armazenamento EBS (grátis por 12 meses)  
✅ **1 Elastic IP** (grátis quando anexado à instância)  
✅ **15 GB** de transferência de dados por mês

**⚠️ Importante:** Após 12 meses, o custo será aproximadamente **$5-10/mês**.

---

## 📋 Pré-requisitos

### Para Deploy Local:
- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Para Deploy AWS:
- Conta AWS (Free Tier)
- [Terraform](https://www.terraform.io/downloads) (>= 1.0)
- [AWS CLI](https://aws.amazon.com/cli/) (configurado)
- Par de chaves SSH criado na AWS

---

## 🎯 Como Usar

### 1️⃣ Deploy Local

```bash
# Clone o repositório
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard/web-site

# Inicie os containers
docker-compose up -d

# Acesse o dashboard
# http://localhost:8080
```

### 2️⃣ Deploy AWS com Terraform

```bash
# Clone o repositório
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard

# Configure suas credenciais AWS
aws configure

# Entre na pasta do Terraform
cd web-site/terraform

# Crie o arquivo de variáveis
cp terraform.tfvars.example terraform.tfvars

# Edite com suas informações
# - your_ip: seu IP público (curl ifconfig.me)
# - key_name: nome da sua chave SSH na AWS
# - github_repo: URL do seu repositório (opcional)

# Inicialize o Terraform
terraform init

# Veja o plano de execução
terraform plan

# Execute o deploy
terraform apply

# Aguarde 5 minutos e acesse o IP fornecido!
```

### 3️⃣ Atualizar Dados da Academia

1. Acesse o dashboard
2. Procure a seção "📊 Atualizar Dados"
3. Faça upload de um arquivo Excel (.xlsx) ou CSV
4. Clique em "Atualizar Dados"
5. Pronto! Dashboard atualizado em tempo real

---

## 🔧 Comandos Úteis

### Local (Docker)
```bash
# Ver containers rodando
docker ps

# Ver logs
docker logs academia-dashboard -f

# Parar tudo
docker-compose down

# Reiniciar
docker-compose restart

# Reconstruir
docker-compose up --build -d
```

### AWS (Terraform)
```bash
# Ver outputs (IPs, URLs)
terraform output

# Atualizar infraestrutura
terraform apply

# Destruir tudo
terraform destroy

# Conectar via SSH
ssh -i sua-chave.pem ubuntu@SEU-IP
```

### AWS (na instância EC2)
```bash
# Ver containers
docker ps

# Ver logs da aplicação
docker logs -f academia-dashboard-prod

# Atualizar aplicação
sudo update-academia-dashboard

# Fazer backup
sudo backup-academia-dashboard

# Ver informações do sistema
cat ~/SYSTEM_INFO.txt
```

---

## 🚨 Solução de Problemas

### Erro: "Docker não encontrado"
```bash
# Instale o Docker Desktop
# Windows/Mac: https://www.docker.com/products/docker-desktop
```

### Erro: "Porta já em uso"
```bash
# Pare os containers
docker-compose down

# Ou altere a porta em docker-compose.yml
```

### Erro: "Terraform credenciais inválidas"
```bash
# Configure suas credenciais AWS
aws configure
# Insira: Access Key ID, Secret Access Key, região (us-east-1)
```

### Erro: "Key pair não existe"
```bash
# Crie um key pair na AWS Console:
# EC2 → Key Pairs → Create Key Pair
# Download do arquivo .pem
# Use o nome no terraform.tfvars
```

---

## 📝 Variáveis do Terraform

Crie o arquivo `terraform/terraform.tfvars`:

```hcl
# Região AWS (Free Tier disponível)
aws_region = "us-east-1"

# Nome da chave SSH (criada na AWS Console)
key_name = "sua-chave-ssh"

# Seu IP público (para acesso SSH)
your_ip = "SEU.IP.AQUI/32"

# URL do repositório GitHub (opcional)
github_repo = "https://github.com/seu-usuario/academia-dashboard.git"

# Tamanho do volume EBS (8-30 GB para Free Tier)
ebs_volume_size = 20
```

**💡 Dica:** Use `curl ifconfig.me` para descobrir seu IP público.

---

## 🔒 Segurança

✅ SSH restrito ao seu IP  
✅ Firewall UFW configurado  
✅ Fail2ban para proteção contra ataques  
✅ Security Groups bem configurados  
✅ IMDSv2 habilitado  
✅ Atualizações automáticas de segurança  

---

## 📊 Monitoramento

- **Health Check**: `http://SEU-IP/health`
- **API Status**: `http://SEU-IP:3000/health`
- **Logs**: `docker logs -f academia-dashboard-prod`
- **Backup automático**: Diariamente às 3h da manhã

---

## 🤝 Contribuindo

Este é um projeto de estudo. Fique à vontade para:

1. Fork o projeto
2. Criar uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abrir um Pull Request

---

## 📄 Licença

Este projeto é um projeto de estudo e está disponível para uso livre.

---

## 📞 Suporte

- **Documentação Local**: [DEPLOY-LOCAL.md](web-site/DEPLOY-LOCAL.md)
- **Documentação AWS**: [DEPLOY-AWS.md](web-site/DEPLOY-AWS.md)
- **Issues**: Abra uma issue no GitHub

---

## 🎓 Aprendizado

Este projeto foi desenvolvido como material de estudo para aprender:

- ✅ Docker e containerização
- ✅ Terraform e Infrastructure as Code
- ✅ AWS e Cloud Computing
- ✅ CI/CD e DevOps
- ✅ Desenvolvimento Full Stack
- ✅ Nginx e proxy reverso

---

**Desenvolvido com ❤️ para estudo e aprendizado**

🚀 **Bora codar!**

