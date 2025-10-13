# 🚀 Guia de Deploy - Academia Dashboard com Terraform

## 📋 Resumo

Este guia mostra como fazer deploy do Academia Dashboard na AWS usando Terraform e recursos do **Free Tier**.

---

## 🎯 Opções de Deploy

### Opção 1: Script Automático (Recomendado) 🤖

**Tempo:** ~5 minutos

```bash
cd academia-dashboard/web-site/terraform

# Linux/macOS
chmod +x scripts/*.sh
./scripts/setup.sh

# Ou usando Make
make setup
```

### Opção 2: Manual Passo a Passo 📝

**Tempo:** ~10 minutos

#### Passo 1: Instalar Ferramentas

```bash
# Verificar instalação
terraform --version  # Deve ser >= 1.0
aws --version        # Deve ser >= 2.0
```

#### Passo 2: Configurar AWS

```bash
aws configure
# AWS Access Key ID: [sua access key]
# AWS Secret Access Key: [sua secret key]
# Default region: us-east-1
# Default output format: json
```

#### Passo 3: Preparar Terraform

```bash
cd academia-dashboard/web-site/terraform

# Copiar exemplo
cp terraform.tfvars.example terraform.tfvars

# Editar (OBRIGATÓRIO!)
nano terraform.tfvars  # ou notepad terraform.tfvars (Windows)
```

#### Passo 4: Configurar Variáveis

Edite `terraform.tfvars`:

```hcl
# 1. Descubra seu IP: curl ifconfig.me
your_ip = "203.0.113.10/32"  # MUDE PARA SEU IP!

# 2. Nome da chave SSH (crie se não tiver)
key_name = "academia-dashboard-key"

# 3. Região AWS (opcional)
aws_region = "us-east-1"

# 4. GitHub (opcional mas recomendado)
github_repo = "https://github.com/seu-usuario/academia-dashboard.git"
```

#### Passo 5: Criar Chave SSH

```bash
# Criar na AWS
aws ec2 create-key-pair \
    --key-name academia-dashboard-key \
    --query 'KeyMaterial' \
    --output text > academia-dashboard-key.pem

# Linux/macOS: ajustar permissões
chmod 400 academia-dashboard-key.pem

# Windows: usar o AWS Console
# https://console.aws.amazon.com/ec2/ > Key Pairs > Create
```

#### Passo 6: Deploy

```bash
# Inicializar
terraform init

# Validar
terraform validate

# Ver plano
terraform plan

# Aplicar
terraform apply
# Digite: yes

# Ou usando Make
make init
make plan
make apply
```

#### Passo 7: Aguardar

⏱️ **Aguarde 3-5 minutos** para:
- ✅ Criação de recursos AWS (~1 min)
- ✅ User Data (instalação) (~2-4 min)

#### Passo 8: Verificar

```bash
# Ver IP público
terraform output public_ip

# Ver URL do dashboard
terraform output dashboard_url

# Ver resumo completo
terraform output deployment_summary

# Ou
make output
```

---

## 🌐 Acessar Dashboard

```bash
# Obter URL
PUBLIC_IP=$(terraform output -raw public_ip)
echo "Dashboard: http://$PUBLIC_IP"
echo "API: http://$PUBLIC_IP:3000"

# Abrir no navegador
# Linux
xdg-open "http://$PUBLIC_IP"
# macOS
open "http://$PUBLIC_IP"
# Windows
start "http://$PUBLIC_IP"
```

---

## 🔐 Conectar via SSH

```bash
# Usando script
./scripts/connect.sh

# Ou manual
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Ver informações do sistema
cat ~/SYSTEM_INFO.txt

# Ver logs de instalação
tail -f /var/log/user-data.log
```

---

## 🛠️ Comandos Úteis

### Terraform

```bash
# Ver outputs
terraform output                    # Todos
terraform output public_ip          # Específico
terraform output -json              # Formato JSON

# Ver estado
terraform show                      # Detalhado
terraform state list                # Lista recursos

# Atualizar
terraform plan                      # Ver mudanças
terraform apply                     # Aplicar

# Destruir
terraform destroy                   # Remove tudo
```

### Make (atalhos)

```bash
make help       # Ver todos os comandos
make init       # Inicializar
make plan       # Planejar
make apply      # Deploy
make status     # Ver status
make connect    # SSH
make update     # Atualizar
make destroy    # Destruir
```

### Scripts

```bash
./scripts/setup.sh      # Setup inicial
./scripts/deploy.sh     # Deploy
./scripts/status.sh     # Status
./scripts/connect.sh    # SSH
./scripts/update.sh     # Atualizar
./scripts/destroy.sh    # Destruir
```

---

## 📊 Monitoramento

### Status Local

```bash
# Usando script
./scripts/status.sh

# Ou Make
make status

# Ver resources
terraform state list
```

### Status no Servidor

```bash
# SSH primeiro
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Ver containers
docker ps

# Ver logs do dashboard
docker logs -f academia-dashboard-prod

# Ver logs da API
docker logs -f academia-data-api-prod

# Ver uso de recursos
htop
df -h
free -h
```

---

## 🔄 Atualização

### Atualizar Infraestrutura

```bash
# 1. Modificar arquivos .tf
# 2. Ver mudanças
terraform plan

# 3. Aplicar
terraform apply
```

### Atualizar Aplicação

```bash
# Opção 1: Script automático
./scripts/update.sh

# Opção 2: No servidor via SSH
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)
sudo update-academia-dashboard

# Opção 3: Manual no servidor
cd ~/academia-dashboard
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## 🐛 Troubleshooting

### Problema: Erro nas credenciais AWS

```bash
# Verificar
aws sts get-caller-identity

# Reconfigurar
aws configure
```

### Problema: Chave SSH não encontrada

```bash
# Verificar chaves existentes
aws ec2 describe-key-pairs

# Criar nova
aws ec2 create-key-pair \
    --key-name academia-dashboard-key \
    --query 'KeyMaterial' \
    --output text > academia-dashboard-key.pem
chmod 400 academia-dashboard-key.pem
```

### Problema: Não consigo SSH

```bash
# 1. Verificar seu IP atual
curl ifconfig.me

# 2. Atualizar terraform.tfvars
your_ip = "SEU.NOVO.IP.AQUI/32"

# 3. Aplicar mudança
terraform apply
```

### Problema: Dashboard não carrega

```bash
# 1. Verificar se UserData completou
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)
cat /var/log/user-data-complete

# 2. Ver logs
tail -100 /var/log/user-data.log

# 3. Verificar containers
docker ps

# 4. Ver logs dos containers
docker logs academia-dashboard-prod
docker logs academia-data-api-prod
```

### Problema: Terraform state lock

```bash
# Se houver lock travado
terraform force-unlock LOCK_ID

# Ver locks
aws dynamodb describe-table --table-name terraform-state-lock
```

---

## 🧹 Destruir Infraestrutura

### Método 1: Script (Seguro)

```bash
./scripts/destroy.sh
# Confirmação dupla
```

### Método 2: Terraform

```bash
# Ver o que será destruído
terraform plan -destroy

# Destruir
terraform destroy

# Ou sem confirmação (cuidado!)
terraform destroy -auto-approve
```

### Método 3: Make

```bash
make destroy
```

### Verificar Remoção

```bash
# AWS CLI
aws ec2 describe-instances --filters "Name=tag:Project,Values=Academia Dashboard"

# Ou no Console
# https://console.aws.amazon.com/ec2/
```

---

## 💰 Custos

### Free Tier (12 meses)

✅ **GRÁTIS** se dentro dos limites:
- 750 horas/mês EC2 t2.micro
- 30GB armazenamento EBS
- 1 Elastic IP anexado
- 15GB transferência dados (primeiros 12 meses)

### Fora do Free Tier

Custos aproximados (região us-east-1):
- EC2 t2.micro: US$ 8.50/mês
- EBS 20GB: US$ 2.00/mês
- Transferência: US$ 0.09/GB

**Total:** ~US$ 10-15/mês (~R$ 50-75/mês)

### Monitorar Custos

```bash
# AWS Console
# https://console.aws.amazon.com/billing/home#/freetier

# AWS CLI
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity MONTHLY \
    --metrics BlendedCost
```

---

## 📚 Arquivos Importantes

```
terraform/
├── variables.tf              # Variáveis
├── provider.tf               # Provider AWS
├── security-groups.tf        # Firewall
├── ec2.tf                    # Instância EC2
├── outputs.tf                # Outputs
├── user-data.sh              # Script de inicialização
├── terraform.tfvars.example  # Exemplo de config
├── terraform.tfvars          # Config (criar)
├── .gitignore                # Ignorar arquivos sensíveis
├── README.md                 # Documentação completa
├── QUICK_START.md            # Início rápido
├── DEPLOY.md                 # Este arquivo
├── Makefile                  # Atalhos Make
└── scripts/
    ├── setup.sh              # Setup automático
    ├── deploy.sh             # Deploy
    ├── destroy.sh            # Destruir
    ├── update.sh             # Atualizar
    ├── connect.sh            # SSH
    ├── status.sh             # Status
    └── backup-state.sh       # Backup do state
```

---

## 🎯 Próximos Passos

Após deploy bem-sucedido:

1. ✅ **Testar Dashboard**: Acesse e faça upload de arquivo
2. ✅ **Configurar Domínio**: Route53 ou outro DNS
3. ✅ **Configurar SSL**: Let's Encrypt
4. ✅ **Backup Automático**: S3 ou outro serviço
5. ✅ **Monitoramento**: CloudWatch
6. ✅ **CI/CD**: GitHub Actions

---

## 🤝 Suporte

### Documentação

- [README.md](README.md) - Guia completo
- [QUICK_START.md](QUICK_START.md) - Início rápido
- [Terraform AWS Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)

### Comandos de Ajuda

```bash
make help                       # Ver todos comandos Make
terraform -help                 # Ajuda Terraform
terraform output next_steps     # Próximos passos
./scripts/status.sh            # Ver status atual
```

---

**Bom deploy! 🚀**

*Desenvolvido para estudos de DevOps, IaC e AWS*

