# 🪟 Guia para Windows - Academia Dashboard Terraform

Este guia é específico para usuários Windows que desejam fazer deploy na AWS usando Terraform.

---

## 🔧 Instalação no Windows

### 1. Instalar Terraform

#### Opção A: Chocolatey (Recomendado)

```powershell
# Abrir PowerShell como Administrador
# Instalar Chocolatey se não tiver
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Instalar Terraform
choco install terraform -y
```

#### Opção B: Download Manual

1. Baixe: https://www.terraform.io/downloads
2. Extraia o arquivo `terraform.exe`
3. Adicione ao PATH do Windows:
   - Painel de Controle > Sistema > Configurações avançadas
   - Variáveis de Ambiente
   - Path > Editar > Novo > `C:\terraform`

### 2. Instalar AWS CLI

#### Opção A: MSI Installer (Recomendado)

```powershell
# PowerShell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

#### Opção B: Download Manual

1. Baixe: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Execute o instalador
3. Abra novo terminal e teste: `aws --version`

### 3. Instalar Git (se não tiver)

```powershell
# Chocolatey
choco install git -y

# Ou baixe: https://git-scm.com/download/win
```

### 4. Verificar Instalação

```powershell
terraform --version
aws --version
git --version
```

---

## ⚙️ Configuração

### 1. Configurar AWS CLI

```powershell
# PowerShell
aws configure

# Você será perguntado:
# AWS Access Key ID: [Sua Access Key]
# AWS Secret Access Key: [Sua Secret Key]  
# Default region name: us-east-1
# Default output format: json
```

**Onde obter credenciais AWS:**
1. AWS Console: https://console.aws.amazon.com/iam/
2. Usuário > Security credentials
3. Create access key

### 2. Descobrir Seu IP Público

```powershell
# PowerShell
Invoke-WebRequest -Uri "https://ifconfig.me" | Select-Object -Expand Content

# Ou use: https://ifconfig.me no navegador
```

### 3. Preparar Projeto

```powershell
# Abrir PowerShell na pasta do projeto
cd C:\Users\User\Documents\Estudo\academia-dashboard\web-site\terraform

# Copiar arquivo de exemplo
Copy-Item terraform.tfvars.example terraform.tfvars

# Editar com Notepad
notepad terraform.tfvars

# Ou VS Code
code terraform.tfvars
```

### 4. Editar terraform.tfvars

```hcl
# Substitua com seus valores

# Seu IP (descoberto no passo 2)
your_ip = "203.0.113.10/32"  # MUDE AQUI!

# Nome da chave SSH
key_name = "academia-dashboard-key"

# Região AWS
aws_region = "us-east-1"

# GitHub (opcional)
github_repo = "https://github.com/seu-usuario/academia-dashboard.git"
```

---

## 🔑 Criar Chave SSH na AWS

### Método 1: AWS CLI (PowerShell)

```powershell
# Criar chave
aws ec2 create-key-pair --key-name academia-dashboard-key --query 'KeyMaterial' --output text | Out-File -Encoding ASCII academia-dashboard-key.pem

# Verificar
Get-Item academia-dashboard-key.pem
```

### Método 2: AWS Console

1. Acesse: https://console.aws.amazon.com/ec2/
2. Menu lateral: Network & Security > Key Pairs
3. Create Key Pair
4. Nome: `academia-dashboard-key`
5. Type: RSA
6. Format: .pem
7. Create key pair
8. Salve o arquivo `.pem` na pasta terraform

---

## 🚀 Deploy

### Opção 1: PowerShell (Recomendado para Windows)

```powershell
# Navegar para pasta terraform
cd C:\Users\User\Documents\Estudo\academia-dashboard\web-site\terraform

# 1. Inicializar Terraform
terraform init

# 2. Validar configuração
terraform validate

# 3. Ver plano
terraform plan

# 4. Aplicar (fazer deploy)
terraform apply
# Digite: yes quando perguntado

# 5. Ver resultados
terraform output
```

### Opção 2: Git Bash (Se instalado)

```bash
# Abrir Git Bash na pasta terraform

# Tornar scripts executáveis
chmod +x scripts/*.sh

# Executar setup
./scripts/setup.sh
```

---

## 📊 Gerenciamento

### Ver Informações

```powershell
# IP público
terraform output public_ip

# URL do dashboard
terraform output dashboard_url

# Todos os outputs
terraform output

# Resumo completo
terraform output deployment_summary

# Próximos passos
terraform output next_steps
```

### Status da Infraestrutura

```powershell
# PowerShell
terraform show

# Listar recursos
terraform state list

# Ver recurso específico
terraform state show aws_instance.academia_dashboard
```

---

## 🔐 Conectar via SSH

### Opção 1: PuTTY (Nativo Windows)

#### Converter .pem para .ppk

1. Baixe PuTTYgen: https://www.putty.org/
2. Abra PuTTYgen
3. Load > Selecione `academia-dashboard-key.pem`
4. Save private key > `academia-dashboard-key.ppk`

#### Conectar com PuTTY

1. Abra PuTTY
2. Host Name: `ubuntu@SEU-IP-PUBLICO`
3. Port: 22
4. Connection > SSH > Auth > Browse > Selecione `.ppk`
5. Open

### Opção 2: OpenSSH (Windows 10/11)

```powershell
# Obter IP
$IP = terraform output -raw public_ip

# Conectar
ssh -i academia-dashboard-key.pem ubuntu@$IP

# Se der erro de permissões, tente:
icacls.exe academia-dashboard-key.pem /reset
icacls.exe academia-dashboard-key.pem /grant:r "$($env:USERNAME):(R)"
icacls.exe academia-dashboard-key.pem /inheritance:r
```

### Opção 3: Git Bash

```bash
# Abrir Git Bash
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)
```

---

## 🛠️ Comandos Úteis PowerShell

### Criar Aliases (Atalhos)

```powershell
# Adicionar ao seu $PROFILE
notepad $PROFILE

# Copie estas linhas:
function tf { terraform $args }
function tfi { terraform init }
function tfp { terraform plan }
function tfa { terraform apply }
function tfo { terraform output }
function tfd { terraform destroy }

# Salvar e recarregar
. $PROFILE

# Agora você pode usar:
tfi    # terraform init
tfp    # terraform plan
tfa    # terraform apply
```

### Scripts PowerShell Customizados

#### deploy.ps1

```powershell
# Criar arquivo: deploy.ps1

# Validar
terraform validate

# Planejar
terraform plan -out=tfplan

# Confirmar
$response = Read-Host "Aplicar este plano? (s/N)"
if ($response -eq 's') {
    terraform apply tfplan
    Remove-Item tfplan
    terraform output deployment_summary
} else {
    Write-Host "Deploy cancelado"
    Remove-Item tfplan
}
```

#### status.ps1

```powershell
# Criar arquivo: status.ps1

$ip = terraform output -raw public_ip

Write-Host "`n🏗️  INFRAESTRUTURA" -ForegroundColor Cyan
Write-Host "IP Público: $ip"

Write-Host "`n🌐 CONECTIVIDADE" -ForegroundColor Cyan
Test-Connection -ComputerName $ip -Count 1 -Quiet

$dashboard = Invoke-WebRequest -Uri "http://$ip" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
if ($dashboard.StatusCode -eq 200) {
    Write-Host "✓ Dashboard: OK" -ForegroundColor Green
} else {
    Write-Host "✗ Dashboard: Falhou" -ForegroundColor Red
}

$api = Invoke-WebRequest -Uri "http://$ip:3000/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
if ($api.StatusCode -eq 200) {
    Write-Host "✓ API: OK" -ForegroundColor Green
} else {
    Write-Host "✗ API: Falhou" -ForegroundColor Red
}
```

#### connect.ps1

```powershell
# Criar arquivo: connect.ps1

$ip = terraform output -raw public_ip
$key = (Get-Content terraform.tfvars | Select-String 'key_name').ToString().Split('"')[1]

Write-Host "Conectando a $ip..." -ForegroundColor Cyan
ssh -i "$key.pem" ubuntu@$ip
```

---

## 🐛 Troubleshooting Windows

### Problema: "terraform não é reconhecido"

```powershell
# Adicionar ao PATH manualmente
$env:Path += ";C:\caminho\para\terraform"

# Ou permanentemente
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\caminho\para\terraform", "User")
```

### Problema: Erro ao executar .sh

```powershell
# Instalar Git Bash
choco install git -y

# Ou usar WSL (Windows Subsystem for Linux)
wsl --install
```

### Problema: Permissão negada na chave .pem

```powershell
# Ajustar permissões
icacls.exe academia-dashboard-key.pem /reset
icacls.exe academia-dashboard-key.pem /grant:r "$($env:USERNAME):(R)"
icacls.exe academia-dashboard-key.pem /inheritance:r
```

### Problema: AWS CLI não encontrado

```powershell
# Reinstalar
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verificar PATH
$env:Path -split ';' | Select-String aws

# Adicionar manualmente se necessário
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
```

### Problema: Erro de encoding no .pem

```powershell
# Salvar com encoding correto
$content = aws ec2 create-key-pair --key-name academia-dashboard-key --query 'KeyMaterial' --output text
[System.IO.File]::WriteAllLines("academia-dashboard-key.pem", $content)
```

---

## 📱 Acessar Dashboard

### Abrir no Navegador

```powershell
# PowerShell
$ip = terraform output -raw public_ip
Start-Process "http://$ip"

# Ou criar atalho
# Criar arquivo: open-dashboard.ps1
$ip = terraform output -raw public_ip
Start-Process "http://$ip"
Start-Process "http://$ip:3000"
```

---

## 🔄 Atualização

### Atualizar Infraestrutura

```powershell
# Ver mudanças
terraform plan

# Aplicar
terraform apply
```

### Atualizar Aplicação (no servidor)

```powershell
# Conectar via SSH primeiro
$ip = terraform output -raw public_ip
ssh -i academia-dashboard-key.pem ubuntu@$ip

# No servidor
sudo update-academia-dashboard
```

---

## 🧹 Destruir Infraestrutura

```powershell
# Ver o que será destruído
terraform plan -destroy

# Destruir (cuidado!)
terraform destroy

# Ou sem confirmação
terraform destroy -auto-approve
```

---

## 📚 Ferramentas Úteis Windows

### Visual Studio Code

```powershell
# Instalar
choco install vscode -y

# Extensões recomendadas:
# - HashiCorp Terraform
# - AWS Toolkit
# - PowerShell
```

### Windows Terminal

```powershell
# Instalar
choco install microsoft-windows-terminal -y

# Ou via Microsoft Store
```

### AWS Tools for PowerShell

```powershell
# Instalar
Install-Module -Name AWSPowerShell.NetCore -Force

# Importar
Import-Module AWSPowerShell.NetCore

# Listar comandos AWS
Get-Command -Module AWSPowerShell.NetCore
```

---

## ✅ Checklist Windows

- [ ] Terraform instalado e no PATH
- [ ] AWS CLI instalado
- [ ] Git instalado (opcional)
- [ ] VS Code instalado (opcional)
- [ ] Credenciais AWS configuradas
- [ ] IP público descoberto
- [ ] terraform.tfvars editado
- [ ] Chave SSH criada
- [ ] Permissões da chave ajustadas
- [ ] Terraform inicializado
- [ ] Deploy realizado
- [ ] Dashboard acessível

---

## 🎯 Próximos Passos Windows

1. **Automatização**: Crie scripts PowerShell customizados
2. **WSL**: Use Windows Subsystem for Linux para scripts bash
3. **SSH Config**: Configure `~/.ssh/config` para acesso fácil
4. **Task Scheduler**: Agende backups automáticos
5. **VS Code**: Use Remote-SSH extension

---

## 📖 Recursos Windows

- [Terraform no Windows](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)
- [AWS CLI no Windows](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html)
- [PowerShell AWS](https://aws.amazon.com/powershell/)
- [OpenSSH no Windows](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)

---

**Desenvolvido e testado no Windows 10/11! 🪟**

