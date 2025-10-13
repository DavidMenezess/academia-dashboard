# 🎯 COMECE AQUI - Academia Dashboard Terraform

## ✨ Bem-vindo!

Você está prestes a fazer o deploy do seu Academia Dashboard na AWS usando **Infraestrutura como Código** (Terraform) com recursos do **Free Tier**.

---

## ⚡ Deploy em 3 Passos (5 minutos)

### 1️⃣ Configure suas credenciais

```powershell
# Instalar AWS CLI (Windows)
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Configurar
aws configure
```

### 2️⃣ Prepare o ambiente

```powershell
# Navegar para a pasta
cd C:\Users\User\Documents\Estudo\academia-dashboard\web-site\terraform

# Copiar arquivo de configuração
Copy-Item terraform.tfvars.example terraform.tfvars

# Editar (IMPORTANTE!)
notepad terraform.tfvars

# Descubra seu IP:
Invoke-WebRequest -Uri "https://ifconfig.me" | Select-Object -Expand Content

# Configure:
# - your_ip = "SEU.IP.AQUI/32"
# - key_name = "academia-dashboard-key"
```

### 3️⃣ Faça o deploy

```powershell
# Inicializar Terraform
terraform init

# Ver plano
terraform plan

# Aplicar (fazer deploy)
terraform apply
# Digite: yes

# Ver resultado
terraform output dashboard_url
```

**🎉 PRONTO! Acesse seu dashboard!**

---

## 📚 Documentação

### Por Sistema Operacional

- **🪟 Windows** → [WINDOWS.md](WINDOWS.md)
- **🐧 Linux** → [README.md](README.md)
- **🍎 macOS** → [README.md](README.md)

### Por Objetivo

- **Início Rápido** → [QUICK_START.md](QUICK_START.md)
- **Deploy Completo** → [DEPLOY.md](DEPLOY.md)
- **Segurança** → [SECURITY.md](SECURITY.md)
- **Navegação** → [INDEX.md](INDEX.md)

---

## 🔑 Criar Chave SSH (se não tiver)

### Windows (PowerShell)

```powershell
aws ec2 create-key-pair --key-name academia-dashboard-key --query 'KeyMaterial' --output text | Out-File -Encoding ASCII academia-dashboard-key.pem
```

### Linux/macOS

```bash
aws ec2 create-key-pair --key-name academia-dashboard-key --query 'KeyMaterial' --output text > academia-dashboard-key.pem
chmod 400 academia-dashboard-key.pem
```

---

## 🌐 Acessar Dashboard

```powershell
# Obter URL
$url = terraform output -raw dashboard_url

# Abrir no navegador
Start-Process $url
```

---

## 🛠️ Comandos Essenciais

### Terraform

```powershell
terraform init      # Inicializar
terraform validate  # Validar
terraform plan      # Planejar
terraform apply     # Aplicar
terraform output    # Ver outputs
terraform destroy   # Destruir
```

### Atalhos (Make)

```bash
make help       # Ver todos comandos
make init       # Inicializar
make plan       # Planejar
make apply      # Aplicar
make status     # Status
make connect    # SSH
make destroy    # Destruir
```

---

## 💰 Custos

### Free Tier (12 meses)
✅ **GRÁTIS** dentro dos limites:
- 750 horas/mês EC2 t2.micro
- 30GB armazenamento EBS
- 1 Elastic IP anexado
- 15GB transferência

### Fora do Free Tier
~US$ 10-15/mês (~R$ 50-75/mês)

**Monitore:** https://console.aws.amazon.com/billing/home#/freetier

---

## 🔐 Conectar via SSH

### Windows (PowerShell)

```powershell
$ip = terraform output -raw public_ip
ssh -i academia-dashboard-key.pem ubuntu@$ip
```

### Windows (PuTTY)

1. Converter .pem para .ppk (PuTTYgen)
2. Usar PuTTY com .ppk

### Linux/macOS

```bash
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)
```

---

## 📊 Verificar Status

### PowerShell

```powershell
# Status básico
terraform show

# Recursos criados
terraform state list

# IP público
terraform output public_ip

# Resumo completo
terraform output deployment_summary
```

### Scripts (Linux/macOS/Git Bash)

```bash
./scripts/status.sh        # Status completo
./scripts/health-check.sh  # Health check
```

---

## 🔄 Atualizar

### Infraestrutura

```powershell
terraform plan   # Ver mudanças
terraform apply  # Aplicar
```

### Aplicação (no servidor)

```powershell
# SSH no servidor
$ip = terraform output -raw public_ip
ssh -i academia-dashboard-key.pem ubuntu@$ip

# Atualizar
sudo update-academia-dashboard
```

---

## 🧹 Destruir

### Seguro (com confirmação)

```powershell
terraform destroy
# Digite: yes
```

### Rápido (sem confirmação)

```powershell
terraform destroy -auto-approve
```

---

## 🐛 Problemas Comuns

### "terraform não reconhecido"

```powershell
# Instalar Terraform
choco install terraform -y

# Ou baixar: https://www.terraform.io/downloads
```

### "Credenciais AWS inválidas"

```powershell
aws configure
# Inserir Access Key e Secret Key
```

### "Não consigo SSH"

```powershell
# Verificar seu IP atual
Invoke-WebRequest -Uri "https://ifconfig.me" | Select-Object -Expand Content

# Atualizar terraform.tfvars
# your_ip = "NOVO.IP.AQUI/32"

# Aplicar mudança
terraform apply
```

### "Dashboard não carrega"

```powershell
# Aguardar 2-3 minutos após deploy

# Verificar logs (SSH no servidor)
docker logs academia-dashboard-prod
docker logs academia-data-api-prod
```

---

## ✅ Checklist

- [ ] AWS CLI instalado
- [ ] Terraform instalado
- [ ] Credenciais AWS configuradas
- [ ] Chave SSH criada
- [ ] terraform.tfvars editado
- [ ] IP público configurado
- [ ] terraform init executado
- [ ] terraform apply executado
- [ ] Dashboard acessível

---

## 📖 Ler Depois

1. [SECURITY.md](SECURITY.md) - Melhorar segurança
2. [README.md](README.md) - Documentação completa
3. [DEPLOY.md](DEPLOY.md) - Opções avançadas

---

## 🎯 Próximos Passos

Após deploy bem-sucedido:

1. ✅ Configurar domínio personalizado
2. ✅ Configurar SSL/HTTPS
3. ✅ Configurar backups automáticos
4. ✅ Configurar monitoramento
5. ✅ Revisar [SECURITY.md](SECURITY.md)

---

## 🆘 Precisa de Ajuda?

### Documentação

- [INDEX.md](INDEX.md) - Navegação completa
- [README.md](README.md) - Guia completo
- [WINDOWS.md](WINDOWS.md) - Específico Windows

### Comandos

```powershell
terraform -help            # Ajuda Terraform
aws help                   # Ajuda AWS CLI
terraform output next_steps  # Próximos passos
```

---

## 🚀 Começar Agora!

**Primeiro deploy?**
1. Leia [QUICK_START.md](QUICK_START.md)
2. Siga os 3 passos acima
3. Aguarde 2-3 minutos
4. Acesse o dashboard!

**Usuário Windows?**
- Leia [WINDOWS.md](WINDOWS.md) primeiro

**Quer detalhes?**
- Leia [README.md](README.md) completo

---

**Bom deploy! 🎉**

*Desenvolvido para estudos de DevOps e AWS*

