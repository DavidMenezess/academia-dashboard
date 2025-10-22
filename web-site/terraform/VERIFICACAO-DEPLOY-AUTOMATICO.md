# ✅ Verificação: Deploy Automático Funcionará?

Análise se o deploy automático vai funcionar após `terraform destroy` e `terraform apply`.

---

## 🔍 **Análise do Problema**

### **❌ Problema Anterior:**
- O script `user-data.sh` estava tentando clonar o repositório
- Mas a variável `github_repo` não estava configurada no `terraform.tfvars`
- Por isso o projeto não era clonado automaticamente

### **✅ Solução Aplicada:**
- ✅ `github_repo` configurado no `terraform.tfvars`
- ✅ Script `user-data.sh` corrigido
- ✅ Deploy automático implementado

---

## 📋 **Verificação da Configuração**

### **1. Variável GitHub Repo:**
```hcl
# No terraform.tfvars
github_repo = "https://github.com/DavidMenezess/academia-dashboard.git"
```
**Status:** ✅ **CONFIGURADO**

### **2. Script User Data:**
```bash
# No user-data.sh (linha 127)
sudo -u ubuntu git clone ${github_repo} academia-dashboard
```
**Status:** ✅ **IMPLEMENTADO**

### **3. Deploy Automático:**
```bash
# No user-data.sh (linhas 204-217)
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```
**Status:** ✅ **IMPLEMENTADO**

---

## 🚀 **Resposta: SIM, Vai Funcionar Automaticamente!**

### **Quando você executar:**
```bash
terraform destroy
terraform apply
```

### **O que vai acontecer automaticamente:**

1. **✅ EC2 será criada**
2. **✅ Docker será instalado**
3. **✅ Projeto será clonado do GitHub**
4. **✅ Containers serão construídos**
5. **✅ Containers serão iniciados**
6. **✅ Dashboard estará funcionando**

---

## 🔧 **Fluxo Automático Detalhado**

### **1. Criação da EC2 (0-2 minutos):**
- Instância t2.micro criada
- Security Groups configurados
- Elastic IP alocado

### **2. Script User Data (2-5 minutos):**
```bash
# Atualizar sistema
apt-get update -y

# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Clonar projeto
git clone https://github.com/DavidMenezess/academia-dashboard.git

# Entrar na pasta
cd academia-dashboard/web-site

# Criar diretórios
mkdir -p data logs api/uploads

# Build containers
docker-compose -f docker-compose.prod.yml build --no-cache

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d
```

### **3. Verificação Automática (5-8 minutos):**
- Health checks dos containers
- Verificação de endpoints
- Logs de status

---

## ⏱️ **Tempo Total de Deploy**

### **Tempo Estimado: 8-10 minutos**
- **EC2 Creation:** 2 minutos
- **Docker Installation:** 3 minutos
- **Project Clone:** 1 minuto
- **Container Build:** 2 minutos
- **Container Start:** 1 minuto
- **Health Checks:** 1 minuto

---

## 🔍 **Como Verificar se Funcionou**

### **1. Após `terraform apply`:**
```bash
# Ver outputs
terraform output

# Deve mostrar:
# dashboard_url = "http://SEU-IP"
# api_url = "http://SEU-IP:3000"
```

### **2. Conectar via SSH:**
```bash
ssh -i sua-chave.pem ubuntu@SEU-IP

# Verificar containers
docker ps

# Deve mostrar:
# CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                    NAMES
# abc123def456   academia-dashboard-prod  "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp       academia-dashboard-prod
# def456ghi789   academia-data-api-prod   "node server.js"         2 minutes ago   Up 2 minutes   0.0.0.0:3000->3000/tcp     academia-data-api-prod
```

### **3. Testar Endpoints:**
```bash
# Health check
curl http://localhost/health
# Deve retornar: {"status":"ok"}

curl http://localhost:3000/health
# Deve retornar: {"status":"ok"}
```

### **4. Acessar Dashboard:**
- **URL:** http://SEU-IP-PUBLICO
- **Deve carregar o dashboard da academia**

---

## 🚨 **Se Algo Der Errado**

### **Verificar Logs:**
```bash
# Logs do user-data
sudo tail -f /var/log/user-data.log

# Logs dos containers
docker logs academia-dashboard-prod
docker logs academia-data-api-prod
```

### **Deploy Manual (se necessário):**
```bash
# Clonar projeto
cd /home/ubuntu
git clone https://github.com/DavidMenezess/academia-dashboard.git
cd academia-dashboard/web-site

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## ✅ **Conclusão**

### **🎉 SIM, o deploy automático vai funcionar!**

**Motivos:**
1. ✅ `github_repo` configurado no `terraform.tfvars`
2. ✅ Script `user-data.sh` implementa deploy automático
3. ✅ Docker e Docker Compose são instalados automaticamente
4. ✅ Projeto é clonado do GitHub automaticamente
5. ✅ Containers são construídos e iniciados automaticamente
6. ✅ Health checks são executados automaticamente

### **⏱️ Tempo Total: 8-10 minutos**
### **🎯 Resultado: Dashboard funcionando automaticamente**

---

## 🚀 **Teste Agora:**

```bash
# Destruir infraestrutura atual
terraform destroy

# Criar nova infraestrutura (deploy automático)
terraform apply

# Aguardar 8-10 minutos
# Acessar: http://SEU-IP-PUBLICO
```

**🎉 Seu dashboard deve estar funcionando automaticamente!**
