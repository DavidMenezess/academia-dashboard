# Terraform - Academia Dashboard (AWS Free Tier)

Infraestrutura como código (IaC) para deploy do Academia Dashboard na AWS usando **100% Free Tier**.

---

## ⚡ Quick Start

```bash
# 1. Configure AWS
aws configure

# 2. Configure variáveis
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edite com suas informações

# 3. Deploy
terraform init
terraform plan
terraform apply
```

**Aguarde 5 minutos e acesse o IP fornecido!**

---

## 📋 Pré-requisitos

1. **Conta AWS** (Free Tier)
2. **Terraform** >= 1.0
3. **AWS CLI** configurado
4. **Key pair** criado na AWS Console

---

## 📁 Arquivos

```
terraform/
├── provider.tf              # Configuração AWS provider
├── variables.tf             # Variáveis do projeto
├── ec2.tf                   # Instância EC2 + Elastic IP
├── security-groups.tf       # Regras de firewall
├── outputs.tf               # Outputs após deploy
├── user-data.sh            # Script de inicialização
├── terraform.tfvars.example # Exemplo de variáveis
└── scripts/                 # Scripts auxiliares
```

---

## ⚙️ Configuração

### 1. Copie o arquivo de exemplo

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edite `terraform.tfvars`

```hcl
# Região AWS (Free Tier disponível)
aws_region = "us-east-1"

# Nome da chave SSH (criada na AWS Console)
key_name = "sua-chave"

# Seu IP público (para SSH)
# Descubra: curl ifconfig.me
your_ip = "203.0.113.0/32"

# Repositório GitHub (opcional)
github_repo = "https://github.com/seu-usuario/academia-dashboard.git"

# Tamanho do disco EBS (8-30 GB)
ebs_volume_size = 20
```

---

## 🚀 Deploy

```bash
# Inicializar
terraform init

# Planejar (ver o que será criado)
terraform plan

# Aplicar (criar recursos)
terraform apply

# Confirme com: yes
```

---

## 📊 Recursos Criados

| Recurso | Tipo | Free Tier | Custo |
|---------|------|-----------|-------|
| EC2 | t2.micro | ✅ 750h/mês | $0 |
| EBS | 20 GB gp2 | ✅ 30GB | $0 |
| Elastic IP | 1 IP | ✅ 1 grátis | $0 |
| Security Group | Custom | ✅ Ilimitado | $0 |

**Total: $0/mês** (nos primeiros 12 meses)

---

## 🔧 Comandos Úteis

### Ver outputs (IPs, URLs)
```bash
terraform output
```

### Ver IP público
```bash
terraform output public_ip
```

### Ver comando SSH
```bash
terraform output ssh_command
```

### Atualizar infraestrutura
```bash
terraform plan
terraform apply
```

### Destruir tudo
```bash
terraform destroy
```

---

## 🔒 Security Groups (Portas Abertas)

| Porta | Serviço | Origem | Descrição |
|-------|---------|--------|-----------|
| 22 | SSH | Seu IP | Acesso SSH restrito |
| 80 | HTTP | 0.0.0.0/0 | Dashboard público |
| 443 | HTTPS | 0.0.0.0/0 | SSL (futuro) |
| 3000 | API | 0.0.0.0/0 | API REST |

---

## 📋 User Data Script

O script `user-data.sh` executa automaticamente na inicialização da EC2:

1. ✅ Atualiza o sistema
2. ✅ Instala Docker + Docker Compose
3. ✅ Configura firewall (UFW)
4. ✅ Instala Fail2ban
5. ✅ Clona repositório GitHub (se fornecido)
6. ✅ Inicia a aplicação
7. ✅ Configura backups automáticos
8. ✅ Cria scripts de gerenciamento

---

## 🔍 Verificar Deploy

### Via Terraform
```bash
# Ver estado
terraform show

# Listar recursos
terraform state list

# Ver output específico
terraform output dashboard_url
```

### Via AWS CLI
```bash
# Ver instância
aws ec2 describe-instances --filters "Name=tag:Name,Values=academia-dashboard-prod"

# Ver IP público
aws ec2 describe-addresses
```

### Via SSH
```bash
# Conectar
ssh -i sua-chave.pem ubuntu@$(terraform output -raw public_ip)

# Ver status da aplicação
docker ps
cat ~/SYSTEM_INFO.txt
```

---

## 📊 Outputs Disponíveis

Após o `terraform apply`, você terá:

- `public_ip` - IP público do servidor
- `dashboard_url` - URL do dashboard
- `api_url` - URL da API
- `ssh_command` - Comando para SSH
- `instance_id` - ID da instância EC2
- `deployment_summary` - Resumo completo
- `next_steps` - Próximos passos

---

## 🔄 Atualizar Aplicação

### Método 1: Na instância EC2
```bash
# Conecte via SSH
ssh -i sua-chave.pem ubuntu@SEU-IP

# Execute script de atualização
sudo update-academia-dashboard
```

### Método 2: Recriar instância
```bash
# Marca para recriação
terraform taint aws_instance.academia_dashboard

# Aplica (recria com código novo)
terraform apply
```

---

## 🚨 Solução de Problemas

### Erro: "No valid credential sources"
```bash
# Configure AWS CLI
aws configure
```

### Erro: "Key pair does not exist"
```bash
# Crie key pair na AWS Console:
# EC2 → Key Pairs → Create key pair
```

### Site não carrega
```bash
# 1. Aguarde 5 minutos (aplicação inicializando)

# 2. Verifique logs via SSH
ssh -i sua-chave.pem ubuntu@$(terraform output -raw public_ip)
tail -f /var/log/user-data.log
```

### SSH não conecta
```bash
# Verifique se seu IP está correto
curl ifconfig.me

# Atualize terraform.tfvars
your_ip = "NOVO_IP/32"

# Reaplique
terraform apply
```

---

## 💡 Scripts Auxiliares

A pasta `scripts/` contém scripts úteis:

### `setup.sh`
Inicialização rápida do Terraform

### `deploy.sh`
Deploy automatizado

### `destroy.sh`
Destruição com confirmação

### `status.sh`
Verifica status dos recursos

### `health-check.sh`
Verifica saúde da aplicação

### `connect.sh`
Conecta via SSH automaticamente

### `backup-state.sh`
Backup do estado do Terraform

### `update.sh`
Atualiza infraestrutura

---

## 📚 Variáveis Importantes

### Obrigatórias
- `key_name` - Nome do key pair na AWS
- `your_ip` - Seu IP público (/32)

### Opcionais
- `aws_region` - Região AWS (default: us-east-1)
- `project_name` - Nome do projeto (default: academia-dashboard)
- `instance_type` - Tipo EC2 (default: t2.micro)
- `ebs_volume_size` - Tamanho disco (default: 20GB)
- `github_repo` - URL do repositório
- `environment` - Ambiente (default: prod)

---

## 💰 Controle de Custos

### ✅ Mantém no Free Tier
- Tipo: `t2.micro` (fixo)
- EBS: 20GB (limite 30GB)
- Monitoring: desabilitado
- Elastic IP: 1 anexado

### ⚠️ Evite custos extras
- ❌ Não mude para t2.small+
- ❌ Não aumente EBS > 30GB
- ❌ Não crie múltiplas instâncias
- ❌ Não ative monitoring detalhado

---

## 🧹 Limpar Recursos

```bash
# Destruir tudo
terraform destroy

# Confirme com: yes
```

**⚠️ Isso remove:**
- Instância EC2
- Elastic IP
- Security Group
- Volume EBS
- **Todos os dados!**

---

## 📖 Documentação Completa

- **Guia Deploy AWS**: [../DEPLOY-AWS.md](../DEPLOY-AWS.md)
- **Guia Deploy Local**: [../DEPLOY-LOCAL.md](../DEPLOY-LOCAL.md)
- **README Principal**: [../../README.md](../../README.md)

---

## 📞 Suporte

- **Terraform Docs**: https://www.terraform.io/docs
- **AWS Free Tier**: https://aws.amazon.com/free/
- **Issues**: GitHub Issues

---

**✅ Terraform configurado para 100% Free Tier da AWS**

**💰 Custo estimado: $0/mês (primeiros 12 meses)**
