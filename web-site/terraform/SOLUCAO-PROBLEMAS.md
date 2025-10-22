# 🚨 Solução de Problemas - Deploy AWS

Guia para resolver problemas comuns no deploy da Academia Dashboard na AWS.

---

## ❌ Problema: Docker não instalado na EC2

### **Sintomas:**
```bash
ubuntu@ip-172-31-0-191:~$ docker ps
Command 'docker' not found, but can be installed with:
```

### **Causa:**
O script `user-data.sh` não executou corretamente ou falhou na instalação do Docker.

### **Solução 1: Instalar Docker Manualmente**

```bash
# Conecte via SSH
ssh -i sua-chave.pem ubuntu@SEU-IP

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker-compose --version
```

### **Solução 2: Verificar Logs do User Data**

```bash
# Ver logs do script de inicialização
sudo tail -f /var/log/user-data.log

# Ver se o script executou
ls -la /var/log/user-data-complete

# Ver logs do cloud-init
sudo tail -f /var/log/cloud-init-output.log
```

### **Solução 3: Reexecutar o Deploy**

```bash
# No seu computador, destrua e recrie
cd academia-dashboard/web-site/terraform
terraform destroy
terraform apply
```

---

## ❌ Problema: Containers não iniciam

### **Sintomas:**
```bash
docker ps
# Nenhum container rodando
```

### **Solução:**

```bash
# Entrar na pasta do projeto
cd /home/ubuntu/academia-dashboard

# Se tem web-site/, entrar nele
if [ -d "web-site" ]; then
    cd web-site
fi

# Verificar se docker-compose.prod.yml existe
ls -la docker-compose.prod.yml

# Criar diretórios necessários
mkdir -p data logs api/uploads

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d --build

# Verificar status
docker ps
```

---

## ❌ Problema: Repositório não clonado

### **Sintomas:**
```bash
ls -la /home/ubuntu/
# Não tem pasta academia-dashboard
```

### **Solução:**

```bash
# Clonar manualmente
cd /home/ubuntu
git clone https://github.com/SEU-USUARIO/academia-dashboard.git

# Entrar na pasta
cd academia-dashboard

# Se tem web-site/, entrar nele
if [ -d "web-site" ]; then
    cd web-site
fi

# Criar diretórios
mkdir -p data logs api/uploads

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## ❌ Problema: Portas não abertas

### **Sintomas:**
- Site não carrega
- Timeout na conexão

### **Solução:**

```bash
# Verificar firewall
sudo ufw status

# Abrir portas se necessário
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp

# Verificar se containers estão usando as portas
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :3000
```

---

## ❌ Problema: Terraform não aplica

### **Sintomas:**
```bash
terraform apply
# Erro de credenciais ou recursos
```

### **Solução:**

```bash
# Verificar credenciais AWS
aws sts get-caller-identity

# Se não funcionar, configurar
aws configure

# Verificar região
aws ec2 describe-regions --region us-east-1

# Limpar estado se necessário
terraform destroy
rm -rf .terraform
terraform init
terraform apply
```

---

## 🔧 Comandos de Diagnóstico

### **Verificar Status Geral:**
```bash
# Conectar via SSH
ssh -i sua-chave.pem ubuntu@SEU-IP

# Ver informações do sistema
cat ~/SYSTEM_INFO.txt

# Ver logs do deploy
tail -f /var/log/user-data.log

# Ver containers
docker ps

# Ver logs dos containers
docker logs academia-dashboard-prod
docker logs academia-data-api-prod
```

### **Verificar Recursos AWS:**
```bash
# No seu computador
cd academia-dashboard/web-site/terraform

# Ver outputs
terraform output

# Ver estado
terraform show

# Ver recursos criados
terraform state list
```

### **Verificar Conectividade:**
```bash
# Testar HTTP
curl http://localhost/health

# Testar API
curl http://localhost:3000/health

# Verificar portas
sudo netstat -tlnp
```

---

## 🚀 Deploy Manual Completo

Se o deploy automático falhar, faça manualmente:

### **1. Conectar na EC2:**
```bash
ssh -i sua-chave.pem ubuntu@SEU-IP
```

### **2. Instalar Docker:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
```

### **3. Instalar Docker Compose:**
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### **4. Clonar Projeto:**
```bash
cd /home/ubuntu
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard/web-site
```

### **5. Configurar Projeto:**
```bash
# Criar diretórios
mkdir -p data logs api/uploads

# Criar dados iniciais
cat > data/academia_data.json << 'EOF'
{
  "academia": {
    "nome": "Academia Dashboard",
    "endereco": "Configurar no admin"
  },
  "estatisticas": {
    "total_membros": 0,
    "membros_ativos": 0,
    "receita_mensal": 0,
    "aulas_realizadas": 0,
    "instrutores_ativos": 0
  },
  "versao": "1.0.0",
  "ultima_atualizacao": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

### **6. Iniciar Containers:**
```bash
# Build e start
docker-compose -f docker-compose.prod.yml up -d --build

# Verificar
docker ps
```

### **7. Testar:**
```bash
# Health check
curl http://localhost/health

# Ver logs
docker logs academia-dashboard-prod
```

---

## 📞 Suporte Adicional

### **Logs Importantes:**
- `/var/log/user-data.log` - Script de inicialização
- `/var/log/cloud-init-output.log` - Cloud-init
- `docker logs academia-dashboard-prod` - Dashboard
- `docker logs academia-data-api-prod` - API

### **Comandos Úteis:**
```bash
# Reiniciar tudo
docker-compose -f docker-compose.prod.yml restart

# Rebuild completo
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# Ver uso de recursos
docker stats

# Limpar sistema Docker
docker system prune -f
```

### **Verificar se está funcionando:**
```bash
# Dashboard
curl http://SEU-IP/health

# API
curl http://SEU-IP:3000/health

# Deve retornar: {"status":"ok"}
```

---

**✅ Com esses passos, seu deploy deve funcionar perfeitamente!**

**🚀 Se ainda tiver problemas, verifique os logs e siga o deploy manual completo.**
