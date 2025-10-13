# 🚀 Guia de Início Rápido - Terraform

Deploy do Academia Dashboard na AWS em **5 minutos**!

## ⚡ Setup Rápido

### 1. Pré-requisitos

```bash
# Instalar Terraform
# Windows: choco install terraform
# Linux: ver README.md
# macOS: brew install terraform

# Instalar AWS CLI
# Windows: msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
# Linux/macOS: ver README.md

# Configurar AWS
aws configure
```

### 2. Setup Automático

```bash
# Entre na pasta terraform
cd academia-dashboard/web-site/terraform

# Execute o script de setup (Linux/macOS)
chmod +x scripts/*.sh
./scripts/setup.sh

# Windows (PowerShell)
# Siga o processo manual abaixo
```

### 3. Setup Manual (Windows ou se preferir)

```bash
# 1. Copiar arquivo de configuração
cp terraform.tfvars.example terraform.tfvars

# 2. Editar terraform.tfvars
# Descubra seu IP: curl ifconfig.me (ou https://ifconfig.me no navegador)
notepad terraform.tfvars  # Windows
nano terraform.tfvars     # Linux/macOS

# 3. Mínimo necessário em terraform.tfvars:
#    - your_ip = "SEU.IP.AQUI/32"
#    - key_name = "academia-dashboard-key"

# 4. Criar chave SSH na AWS (se não tiver)
aws ec2 create-key-pair --key-name academia-dashboard-key --query 'KeyMaterial' --output text > academia-dashboard-key.pem

# Linux/macOS: ajustar permissões
chmod 400 academia-dashboard-key.pem

# 5. Inicializar Terraform
terraform init

# 6. Ver o plano
terraform plan

# 7. Aplicar
terraform apply
```

## 📊 Comandos Essenciais

### Deploy

```bash
# Script automático (Linux/macOS)
./scripts/deploy.sh

# Manual
terraform apply
```

### Ver Informações

```bash
# IP público
terraform output public_ip

# URL do dashboard
terraform output dashboard_url

# Comando SSH
terraform output ssh_command

# Tudo
terraform output
```

### Conectar SSH

```bash
# Script automático (Linux/macOS)
./scripts/connect.sh

# Manual
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)
```

### Status

```bash
# Script automático (Linux/macOS)
./scripts/status.sh

# Ver estado
terraform show

# Ver recursos
terraform state list
```

### Atualizar

```bash
# Script automático (Linux/macOS)
./scripts/update.sh

# Manual
terraform plan
terraform apply
```

### Destruir

```bash
# Script automático (Linux/macOS)
./scripts/destroy.sh

# Manual
terraform destroy
```

## 🌐 Acessar Dashboard

Após deploy (aguarde 2-3 minutos):

```bash
# Obter URL
terraform output dashboard_url

# Ou manualmente
# http://SEU-IP-PUBLICO
```

## 📝 Checklist Rápido

- [ ] AWS CLI instalado e configurado
- [ ] Terraform instalado
- [ ] Arquivo terraform.tfvars criado e editado
- [ ] Chave SSH criada na AWS
- [ ] Seu IP configurado em `your_ip`
- [ ] `terraform init` executado
- [ ] `terraform apply` executado
- [ ] Aguardou 2-3 minutos
- [ ] Acessou dashboard no navegador

## ⚠️ Problemas Comuns

### Não consigo fazer SSH

```bash
# Verificar security group
terraform output security_group_id

# Atualizar seu IP
# 1. Descubra seu IP: curl ifconfig.me
# 2. Atualize terraform.tfvars
# 3. Execute: terraform apply
```

### Dashboard não carrega

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Ver logs
tail -f /var/log/user-data.log

# Ver containers
docker ps

# Ver informações
cat ~/SYSTEM_INFO.txt
```

### Erro de credenciais AWS

```bash
# Reconfigurar
aws configure

# Testar
aws sts get-caller-identity
```

## 💡 Dicas

1. **Região AWS**: Use `us-east-1` (mais barata)
2. **Free Tier**: Não exceda 750 horas/mês
3. **Backup**: Use `./scripts/status.sh` para monitorar
4. **Logs**: SSH e veja `/var/log/user-data.log`
5. **Atualizar app**: SSH e execute `sudo update-academia-dashboard`

## 📚 Mais Informações

- [README.md](README.md) - Documentação completa
- [terraform.tfvars.example](terraform.tfvars.example) - Exemplo de configuração
- [Scripts](scripts/) - Scripts auxiliares

## 🆘 Ajuda

```bash
# Documentação completa
cat README.md

# Ver outputs disponíveis
terraform output

# Ver próximos passos
terraform output next_steps

# Estado atual
terraform show
```

---

**Bom deploy! 🚀**

