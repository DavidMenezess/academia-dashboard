# 🔒 Guia de Segurança - Academia Dashboard

Este documento contém recomendações de segurança para sua infraestrutura AWS.

---

## 🛡️ Segurança Implementada

### Configurações Atuais

✅ **Security Group**
- SSH restrito ao seu IP
- Firewall configurado (UFW)
- Fail2ban para proteção contra brute force

✅ **EC2 Instance**
- IMDSv2 habilitado (metadados seguros)
- User data com instalação automática
- Elastic IP fixo

✅ **Rede**
- VPC padrão (isolamento básico)
- Security Groups específicos
- Portas mínimas abertas

---

## ⚠️ Recomendações Críticas

### 1. SSH - Acesso Restrito

**NUNCA use `0.0.0.0/0` para SSH!**

```hcl
# ❌ ERRADO
your_ip = "0.0.0.0/32"

# ✅ CORRETO
your_ip = "203.0.113.10/32"  # Seu IP específico
```

**Descobrir seu IP:**
```bash
curl ifconfig.me
```

**IP dinâmico? Use security group dinâmico:**
```bash
# Atualizar quando IP mudar
NEW_IP=$(curl -s ifconfig.me)
sed -i "s/your_ip = .*/your_ip = \"$NEW_IP\/32\"/" terraform.tfvars
terraform apply
```

### 2. Chaves SSH

**Proteger chave privada:**

```bash
# Permissões corretas
chmod 400 academia-dashboard-key.pem

# NUNCA commitar no Git
echo "*.pem" >> .gitignore
echo "*.key" >> .gitignore

# Backup seguro
cp academia-dashboard-key.pem ~/backup-seguro/
```

**Trocar chave comprometida:**

```bash
# 1. Criar nova chave
aws ec2 create-key-pair --key-name academia-new-key \
  --query 'KeyMaterial' --output text > academia-new-key.pem

# 2. Atualizar terraform.tfvars
key_name = "academia-new-key"

# 3. Aplicar (vai recriar instância)
terraform apply

# 4. Deletar chave antiga
aws ec2 delete-key-pair --key-name academia-dashboard-key
```

### 3. Credenciais AWS

**Proteger credenciais:**

```bash
# NUNCA commitar terraform.tfvars
echo "terraform.tfvars" >> .gitignore

# Usar AWS CLI com MFA
aws configure set mfa_serial arn:aws:iam::ACCOUNT:mfa/USER

# Rotacionar access keys (a cada 90 dias)
aws iam create-access-key --user-name SEU-USER
aws configure  # Atualizar com novas keys
aws iam delete-access-key --access-key-id OLD-KEY --user-name SEU-USER
```

**Usuário IAM com permissões mínimas:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "autoscaling:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

### 4. Terraform State

**State contém informações sensíveis!**

```bash
# NUNCA commitar state
echo "terraform.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore

# Usar backend remoto com criptografia
# Ver: backend.tf.example

# Backup do state
./scripts/backup-state.sh
```

---

## 🔐 Configurações Adicionais

### SSL/HTTPS com Let's Encrypt

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Instalar Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

# Obter certificado (com domínio)
sudo certbot --nginx -d seu-dominio.com -d www.seu-dominio.com

# Auto-renovação
sudo crontab -e
# Adicionar: 0 3 * * * certbot renew --quiet
```

### Firewall Avançado (UFW)

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Regras específicas
sudo ufw allow from SEU.IP.AQUI to any port 22
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Limitar tentativas SSH
sudo ufw limit 22/tcp

# Logs
sudo ufw logging on
sudo tail -f /var/log/ufw.log
```

### Fail2ban

```bash
# Já instalado via user-data

# Verificar status
sudo systemctl status fail2ban

# Ver banimentos
sudo fail2ban-client status sshd

# Desbanir IP
sudo fail2ban-client set sshd unbanip IP.BANIDO.AQUI
```

### Atualizações Automáticas

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Instalar unattended-upgrades
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades

# Configurar
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
# Habilitar: security updates
```

### Hardening do SSH

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Editar config SSH
sudo nano /etc/ssh/sshd_config

# Configurações recomendadas:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Reiniciar SSH
sudo systemctl restart sshd
```

---

## 📊 Monitoramento de Segurança

### CloudWatch Alarms (opcional, pode gerar custos)

```hcl
# Adicionar em um novo arquivo: monitoring.tf

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU acima de 80%"
  
  dimensions = {
    InstanceId = aws_instance.academia_dashboard.id
  }
}
```

### Logs Centralizados

```bash
# SSH no servidor
ssh -i academia-dashboard-key.pem ubuntu@$(terraform output -raw public_ip)

# Instalar CloudWatch Agent (opcional)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configurar
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

### Security Scanning

```bash
# Lynis - Security audit
sudo apt install lynis -y
sudo lynis audit system

# ClamAV - Antivírus
sudo apt install clamav clamav-daemon -y
sudo freshclam
sudo clamscan -r /home

# rkhunter - Rootkit detection
sudo apt install rkhunter -y
sudo rkhunter --check
```

---

## 🚨 Resposta a Incidentes

### IP Suspeito Tentando SSH

```bash
# Ver tentativas
sudo grep "Failed password" /var/log/auth.log

# Banir IP
sudo fail2ban-client set sshd banip IP.SUSPEITO.AQUI

# Ou via UFW
sudo ufw deny from IP.SUSPEITO.AQUI
```

### Chave Comprometida

```bash
# 1. Criar nova chave imediatamente
aws ec2 create-key-pair --key-name academia-emergency-key \
  --query 'KeyMaterial' --output text > academia-emergency-key.pem
chmod 400 academia-emergency-key.pem

# 2. Atualizar terraform.tfvars
key_name = "academia-emergency-key"

# 3. Aplicar (recria instância)
terraform apply -auto-approve

# 4. Deletar chave comprometida
aws ec2 delete-key-pair --key-name academia-dashboard-key

# 5. Investigar acesso
sudo last
sudo lastlog
sudo grep -r "COMMAND" /var/log/auth.log
```

### Credenciais AWS Expostas

```bash
# 1. Deletar credenciais comprometidas
aws iam delete-access-key --access-key-id AKIAXXXXXXXXXXXXXXXX

# 2. Criar novas credenciais
aws iam create-access-key --user-name SEU-USER

# 3. Atualizar AWS CLI
aws configure

# 4. Verificar uso não autorizado
aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=SEU-USER

# 5. Revisar recursos criados
aws ec2 describe-instances --region us-east-1
aws s3 ls
```

---

## ✅ Checklist de Segurança

### Inicial (Obrigatório)

- [ ] SSH restrito ao seu IP (`your_ip` configurado)
- [ ] Chave SSH com permissões 400
- [ ] `.gitignore` configurado (state, keys, tfvars)
- [ ] Credenciais AWS com MFA
- [ ] Free Tier monitorado

### Recomendado

- [ ] SSL/HTTPS configurado
- [ ] Domínio personalizado
- [ ] Firewall UFW ativo
- [ ] Fail2ban configurado
- [ ] Atualizações automáticas
- [ ] SSH hardening
- [ ] Backups automáticos

### Avançado

- [ ] Backend remoto S3 criptografado
- [ ] CloudWatch alarms
- [ ] VPC customizada
- [ ] WAF (Web Application Firewall)
- [ ] Security Hub
- [ ] GuardDuty

---

## 📚 Recursos

### Ferramentas

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Terraform Security](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html#security)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Comandos Úteis

```bash
# Verificar portas abertas
sudo netstat -tulpn

# Processos rodando
sudo ps aux

# Usuários logados
who

# Histórico de comandos
history

# Conexões ativas
sudo ss -tunap

# Logs de segurança
sudo tail -f /var/log/auth.log
```

---

## ⚠️ Importante

1. **Backups**: Sempre faça backup antes de mudanças
2. **Testes**: Teste mudanças em ambiente de dev primeiro
3. **Documentação**: Documente todas as alterações
4. **Monitoramento**: Configure alertas para atividades suspeitas
5. **Atualizações**: Mantenha sistema e apps atualizados

---

**A segurança é um processo contínuo, não um estado final! 🔐**




