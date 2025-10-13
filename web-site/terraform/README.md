# 🏗️ Infraestrutura como Código - Academia Dashboard

Este projeto contém a infraestrutura completa para deploy do Academia Dashboard na AWS usando **apenas recursos do Free Tier**.

## 📋 Índice

- [Pré-requisitos](#-pré-requisitos)
- [Recursos AWS Utilizados](#-recursos-aws-utilizados)
- [Custos (Free Tier)](#-custos-free-tier)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [Deploy](#-deploy)
- [Comandos Úteis](#-comandos-úteis)
- [Manutenção](#-manutenção)
- [Troubleshooting](#-troubleshooting)
- [Limpeza](#-limpeza)

---

## 🔧 Pré-requisitos

### 1. Conta AWS
- ✅ Conta AWS ativa
- ✅ Acesso ao Free Tier (12 meses após criar a conta)
- ✅ Credenciais AWS configuradas

### 2. Ferramentas Instaladas

```bash
# Terraform (versão >= 1.0)
# Windows (usando Chocolatey)
choco install terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# AWS CLI (versão >= 2.0)
# Windows
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
brew install awscli
```

### 3. Verificar Instalação

```bash
terraform --version
aws --version
```

---

## 🏛️ Recursos AWS Utilizados

### Free Tier Elegíveis

| Recurso | Especificação | Free Tier | Custo Mensal* |
|---------|---------------|-----------|---------------|
| **EC2** | t2.micro | 750 horas/mês | R$ 0,00 |
| **EBS** | 20GB gp2 | 30GB/mês | R$ 0,00 |
| **Elastic IP** | 1 IP | 1 IP anexado | R$ 0,00 |
| **Data Transfer** | Saída | 1GB/mês | R$ 0,00 |
| **VPC** | Default | Ilimitado | R$ 0,00 |
| **Security Groups** | Padrão | Ilimitado | R$ 0,00 |

*Dentro do Free Tier por 12 meses

### Arquitetura

```
Internet
    │
    ├─── Elastic IP (Público)
    │
    ├─── Security Group
    │    ├── SSH (22)     - Seu IP
    │    ├── HTTP (80)    - 0.0.0.0/0
    │    ├── HTTPS (443)  - 0.0.0.0/0
    │    └── API (3000)   - 0.0.0.0/0
    │
    └─── EC2 t2.micro (Ubuntu 22.04)
         ├── Docker
         ├── Docker Compose
         ├── Nginx (Dashboard)
         └── Node.js (API)
```

---

## 💰 Custos (Free Tier)

### Dentro do Free Tier (12 meses)
✅ **GRÁTIS** - Enquanto permanecer dentro dos limites:
- 750 horas/mês de t2.micro (uma instância 24/7)
- 30GB de armazenamento EBS
- 1 Elastic IP anexado à instância
- 15GB de transferência de dados (primeiros 12 meses)

### Após Free Tier ou Exceder Limites
Se exceder o Free Tier, custos aproximados:
- EC2 t2.micro: ~US$ 8,50/mês (~R$ 45/mês)
- EBS 20GB: ~US$ 2,00/mês (~R$ 10/mês)
- Transferência: ~US$ 0,09/GB

**Total estimado:** US$ 10-15/mês (~R$ 50-75/mês)

---

## 📥 Instalação

### 1. Clonar o Repositório

```bash
cd academia-dashboard/web-site/terraform
```

### 2. Configurar AWS CLI

```bash
# Configurar credenciais AWS
aws configure

# Será solicitado:
# AWS Access Key ID: [Sua Access Key]
# AWS Secret Access Key: [Sua Secret Key]
# Default region name: us-east-1
# Default output format: json
```

### 3. Criar Chave SSH na AWS

```bash
# Opção 1: Pelo AWS Console
# 1. Acesse: https://console.aws.amazon.com/ec2/
# 2. Navegue: EC2 > Network & Security > Key Pairs
# 3. Clique em "Create Key Pair"
# 4. Nome: academia-dashboard-key
# 5. Type: RSA
# 6. Format: .pem
# 7. Download e salve em local seguro

# Opção 2: Via AWS CLI
aws ec2 create-key-pair \
    --key-name academia-dashboard-key \
    --query 'KeyMaterial' \
    --output text > academia-dashboard-key.pem

# Ajustar permissões (Linux/macOS)
chmod 400 academia-dashboard-key.pem
```

---

## ⚙️ Configuração

### 1. Copiar Arquivo de Variáveis

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar terraform.tfvars

```bash
# Windows
notepad terraform.tfvars

# Linux/macOS
nano terraform.tfvars
# ou
vim terraform.tfvars
```

### 3. Configurações Obrigatórias

```hcl
# Descubra seu IP
# Windows: Invoke-WebRequest -Uri "https://ifconfig.me" | Select-Object -Expand Content
# Linux/macOS: curl ifconfig.me

your_ip = "SEU.IP.PUBLICO.AQUI/32"  # IMPORTANTE!
key_name = "academia-dashboard-key"  # Nome da chave criada

# Opcional mas recomendado
github_repo = "https://github.com/seu-usuario/academia-dashboard.git"
```

### 4. Configurações Opcionais

```hcl
# Região AWS (escolha a mais próxima)
aws_region = "us-east-1"  # N. Virginia
# aws_region = "sa-east-1"  # São Paulo (mais caro)

# Tamanho do volume (8-30GB para Free Tier)
ebs_volume_size = 20

# Tags personalizadas
tags = {
  Owner = "Seu Nome"
  Email = "seu-email@exemplo.com"
}
```

---

## 🚀 Deploy

### 1. Inicializar Terraform

```bash
terraform init
```

### 2. Validar Configuração

```bash
terraform validate
```

### 3. Planejar Deploy (Preview)

```bash
terraform plan
```

### 4. Aplicar Infraestrutura

```bash
terraform apply

# Ou sem confirmação
terraform apply -auto-approve
```

### 5. Aguardar Conclusão

⏱️ **Tempo estimado:** 3-5 minutos
- Criação de recursos: ~1 min
- User Data (instalação): ~2-4 min

### 6. Obter Informações

```bash
# Ver todos os outputs
terraform output

# Ver output específico
terraform output public_ip
terraform output dashboard_url
terraform output ssh_command

# Ver resumo completo
terraform output deployment_summary

# Ver próximos passos
terraform output next_steps
```

---

## 🎯 Acessar o Dashboard

Após o deploy, aguarde 2-3 minutos e acesse:

```bash
# Dashboard
http://SEU-IP-PUBLICO

# API
http://SEU-IP-PUBLICO:3000

# Health Check
http://SEU-IP-PUBLICO/health
```

---

## 🔐 Conectar via SSH

```bash
# Comando será exibido no output
ssh -i academia-dashboard-key.pem ubuntu@SEU-IP-PUBLICO

# Ver informações do sistema
cat ~/SYSTEM_INFO.txt

# Ver logs de instalação
tail -f /var/log/user-data.log
```

---

## 🛠️ Comandos Úteis

### Terraform

```bash
# Ver estado atual
terraform show

# Ver outputs
terraform output

# Atualizar infraestrutura
terraform apply

# Destruir infraestrutura
terraform destroy

# Formatar código
terraform fmt

# Validar configuração
terraform validate

# Ver plano sem aplicar
terraform plan

# Importar recurso existente
terraform import aws_instance.academia_dashboard i-1234567890abcdef0
```

### Docker (no servidor)

```bash
# SSH no servidor primeiro
ssh -i academia-dashboard-key.pem ubuntu@SEU-IP-PUBLICO

# Ver containers
docker ps

# Ver logs do dashboard
docker logs -f academia-dashboard-prod

# Ver logs da API
docker logs -f academia-data-api-prod

# Reiniciar containers
cd ~/academia-dashboard
docker-compose -f docker-compose.prod.yml restart

# Parar containers
docker-compose -f docker-compose.prod.yml stop

# Iniciar containers
docker-compose -f docker-compose.prod.yml start

# Rebuild containers
docker-compose -f docker-compose.prod.yml up -d --build
```

### Scripts Personalizados (no servidor)

```bash
# Atualizar aplicação do GitHub
sudo update-academia-dashboard

# Fazer backup
sudo backup-academia-dashboard

# Ver backups
ls -lh ~/backups/

# Restaurar backup
cd ~/academia-dashboard
tar -xzf ~/backups/backup_YYYYMMDD_HHMMSS.tar.gz
```

---

## 🔄 Manutenção

### Atualizar Código

```bash
# Método 1: Script automático (no servidor)
ssh -i academia-dashboard-key.pem ubuntu@SEU-IP-PUBLICO
sudo update-academia-dashboard

# Método 2: Manual (no servidor)
cd ~/academia-dashboard
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

### Backup Manual

```bash
# No servidor
sudo backup-academia-dashboard

# Ou manual
cd ~/academia-dashboard
tar -czf ~/backup-$(date +%Y%m%d-%H%M%S).tar.gz data/ logs/
```

### Monitoramento

```bash
# Status dos containers
docker ps

# Uso de recursos
htop

# Espaço em disco
df -h

# Logs do sistema
journalctl -u docker -f

# Logs da aplicação
tail -f ~/academia-dashboard/logs/*.log
```

### Atualizar Infraestrutura

```bash
# 1. Modificar arquivos .tf
# 2. Ver mudanças
terraform plan

# 3. Aplicar mudanças
terraform apply
```

---

## 🐛 Troubleshooting

### Problema: Terraform não encontra credenciais

```bash
# Verificar credenciais
aws sts get-caller-identity

# Reconfigurar
aws configure
```

### Problema: Erro ao criar chave SSH

```bash
# Listar chaves existentes
aws ec2 describe-key-pairs

# Deletar chave antiga
aws ec2 delete-key-pair --key-name academia-dashboard-key

# Criar nova
aws ec2 create-key-pair --key-name academia-dashboard-key --query 'KeyMaterial' --output text > academia-dashboard-key.pem
chmod 400 academia-dashboard-key.pem
```

### Problema: Não consigo acessar via SSH

```bash
# Verificar security group
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)

# Verificar seu IP atual
curl ifconfig.me

# Atualizar your_ip no terraform.tfvars e aplicar
terraform apply
```

### Problema: Dashboard não carrega

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@SEU-IP-PUBLICO

# Verificar containers
docker ps

# Ver logs
docker logs academia-dashboard-prod
docker logs academia-data-api-prod

# Verificar user-data completou
cat /var/log/user-data-complete

# Ver log de instalação
tail -100 /var/log/user-data.log
```

### Problema: Erro de Free Tier

```bash
# Verificar limites do Free Tier
# AWS Console > Billing > Free Tier

# Ver custos atuais
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity MONTHLY \
    --metrics BlendedCost
```

### Problema: Instância não inicia

```bash
# Ver logs da instância
aws ec2 get-console-output --instance-id $(terraform output -raw instance_id)

# Verificar estado
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)

# Reiniciar instância
aws ec2 reboot-instances --instance-ids $(terraform output -raw instance_id)
```

---

## 🧹 Limpeza

### Destruir Infraestrutura Completa

```bash
# Ver o que será destruído
terraform plan -destroy

# Destruir tudo
terraform destroy

# Ou sem confirmação
terraform destroy -auto-approve
```

### Limpeza Parcial

```bash
# Remover apenas um recurso
terraform destroy -target=aws_instance.academia_dashboard

# Remover Elastic IP
terraform destroy -target=aws_eip.academia_dashboard
```

### Limpeza Manual (AWS Console)

1. EC2 > Instances > Terminar instância
2. EC2 > Elastic IPs > Liberar endereço
3. EC2 > Security Groups > Deletar (se não usado)
4. EC2 > Key Pairs > Deletar (se não usado)

### Limpeza Completa AWS

```bash
# Listar todos os recursos da região
aws resourcegroupstaggingapi get-resources \
    --tag-filters Key=Project,Values="Academia Dashboard"

# Deletar manualmente cada recurso
```

---

## 📚 Referências

### Documentação

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Docker Documentation](https://docs.docker.com/)

### Arquivos do Projeto

- `variables.tf` - Variáveis de configuração
- `provider.tf` - Configuração do provider AWS
- `security-groups.tf` - Regras de firewall
- `ec2.tf` - Configuração da instância EC2
- `user-data.sh` - Script de inicialização
- `outputs.tf` - Outputs do deployment
- `terraform.tfvars` - Valores das variáveis (criar)

---

## 🤝 Contribuindo

Para contribuir com melhorias:

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/melhoria`
3. Commit: `git commit -m 'Adiciona melhoria X'`
4. Push: `git push origin feature/melhoria`
5. Abra um Pull Request

---

## 📝 Licença

Este projeto é fornecido "como está" para fins educacionais.

---

## ⚠️ Avisos Importantes

1. **Segurança**: Sempre use seu IP específico para SSH (`your_ip`)
2. **Custos**: Monitore o AWS Free Tier para evitar cobranças
3. **Backups**: Configure backups automáticos dos dados
4. **SSL/HTTPS**: Configure certificado SSL para produção
5. **Domínio**: Use um domínio personalizado para produção
6. **Monitoramento**: Configure CloudWatch para alertas

---

## 🎯 Próximos Passos

Após o deploy bem-sucedido:

1. ✅ Configure um domínio personalizado
2. ✅ Configure SSL/HTTPS com Let's Encrypt
3. ✅ Configure backups automáticos para S3
4. ✅ Configure CloudWatch para monitoramento
5. ✅ Configure Auto Scaling (sairá do Free Tier)
6. ✅ Configure Load Balancer (sairá do Free Tier)

---

**Desenvolvido com ❤️ para estudos de DevOps e AWS**

