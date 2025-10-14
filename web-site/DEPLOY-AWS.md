# ☁️ Deploy AWS com Terraform - Academia Dashboard

Guia completo para fazer deploy na AWS usando Terraform (100% Free Tier).

---

## ⚡ Deploy Rápido (5 minutos)

```bash
# 1. Configure suas credenciais AWS
aws configure

# 2. Entre na pasta do Terraform
cd academia-dashboard/web-site/terraform

# 3. Configure suas variáveis
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edite com suas informações

# 4. Inicialize o Terraform
terraform init

# 5. Execute o deploy
terraform apply

# 6. Aguarde 5 minutos e acesse o IP fornecido!
```

**🎉 Pronto! Seu dashboard está online!**

---

## 📋 Pré-requisitos

### 1. Conta AWS (Free Tier)
- Crie em: https://aws.amazon.com/free/
- **Gratuito** por 12 meses

### 2. Instale as Ferramentas

**Terraform:**
```bash
# Windows (Chocolatey)
choco install terraform

# Mac (Homebrew)
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**AWS CLI:**
```bash
# Windows: https://aws.amazon.com/cli/
# Mac: brew install awscli
# Linux: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#        unzip awscliv2.zip && sudo ./aws/install
```

### 3. Configure Credenciais AWS

```bash
aws configure
```

**Como obter as chaves:**
1. AWS Console → IAM → Users → Seu usuário
2. Security credentials → Create access key
3. Copie Access Key ID e Secret Access Key

### 4. Crie um Par de Chaves SSH

1. AWS Console → EC2 → Key Pairs
2. Create key pair
3. Nome: `academia-dashboard`
4. Format: `.pem`
5. Download e salve em local seguro
6. Linux/Mac: `chmod 400 academia-dashboard.pem`

---

## 🚀 Passo a Passo Detalhado

### 1️⃣ Configure as Variáveis

```bash
cd academia-dashboard/web-site/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Edite `terraform.tfvars`:**

```hcl
# Região AWS
aws_region = "us-east-1"

# Nome da chave SSH criada
key_name = "academia-dashboard"

# Seu IP público (curl ifconfig.me)
your_ip = "203.0.113.0/32"

# Repositório GitHub (opcional)
github_repo = "https://github.com/seu-usuario/academia-dashboard.git"

# Tamanho do disco (8-30 GB)
ebs_volume_size = 20
```

### 2️⃣ Inicialize o Terraform

```bash
terraform init
```

### 3️⃣ Veja o Plano

```bash
terraform plan
```

### 4️⃣ Execute o Deploy

```bash
terraform apply
```

Digite `yes` quando solicitado.

**Tempo:** ~5 minutos

### 5️⃣ Acesse o Dashboard

```
Outputs:
dashboard_url = "http://54.123.45.67"
```

**Acesse:** http://SEU-IP-PUBLICO

⏰ **Aguarde 2-3 minutos** para inicialização completa.

---

## 💰 Custos e Free Tier

### ✅ O que é GRÁTIS (12 meses)

| Recurso | Free Tier | Usado |
|---------|-----------|-------|
| EC2 t2.micro | 750h/mês | ✅ |
| EBS 20GB | 30GB | ✅ |
| Elastic IP | 1 grátis | ✅ |
| Transfer | 15GB/mês | ✅ |

### 💰 Após 12 meses
- **Total:** ~$10-12/mês

---

## 🔧 Comandos Úteis

### Ver Outputs
```bash
terraform output
terraform output public_ip
```

### Conectar via SSH
```bash
ssh -i academia-dashboard.pem ubuntu@SEU-IP
```

### Atualizar Infraestrutura
```bash
terraform apply
```

### Destruir Tudo
```bash
terraform destroy
```

---

## 📊 Gerenciar a Aplicação

### Ver Containers
```bash
ssh -i sua-chave.pem ubuntu@SEU-IP
docker ps
```

### Ver Logs
```bash
docker logs -f academia-dashboard-prod
```

### Atualizar Aplicação
```bash
sudo update-academia-dashboard
```

### Fazer Backup
```bash
sudo backup-academia-dashboard
```

---

## 🚨 Solução de Problemas

### ❌ Erro: "No valid credential sources"
```bash
aws configure
```

### ❌ Erro: "Key pair does not exist"
```bash
# Crie na AWS Console: EC2 → Key Pairs → Create
```

### ❌ Site não carrega
```bash
# Aguarde 5 minutos, então conecte via SSH
ssh -i sua-chave.pem ubuntu@SEU-IP
tail -f /var/log/user-data.log
docker ps
```

---

## 🧹 Limpar Recursos

```bash
terraform destroy
```

**⚠️ ATENÇÃO:** Todos os dados serão perdidos!

---

## 🎯 Próximos Passos (Opcional)

### 1. Configure um Domínio
- Compre domínio
- Configure DNS tipo A para seu IP

### 2. Adicione SSL/HTTPS
```bash
ssh -i sua-chave.pem ubuntu@SEU-IP
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d seu-dominio.com
```

---

## 📚 Recursos

- **Terraform**: https://www.terraform.io/docs
- **AWS Free Tier**: https://aws.amazon.com/free/
- **README Principal**: [../README.md](../README.md)

---

**🚀 Seu dashboard está na nuvem!**

**🌍 Compartilhe:** http://SEU-IP-PUBLICO

**💰 Custo:** $0 (Free Tier por 12 meses)

