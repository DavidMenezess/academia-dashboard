# 🚀 Quick Fix - Docker não instalado na EC2

## ⚡ Solução Rápida (5 minutos)

### **1. Conectar na EC2:**
```bash
ssh -i sua-chave.pem ubuntu@SEU-IP
```

### **2. Executar Script de Correção:**
```bash
# Baixar e executar script de correção
curl -sSL https://raw.githubusercontent.com/SEU-USUARIO/academia-dashboard/main/web-site/terraform/fix-deploy.sh | bash
```

### **3. Ou executar comandos manuais:**

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clonar projeto
cd /home/ubuntu
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard/web-site

# Criar diretórios
mkdir -p data logs api/uploads

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d --build

# Verificar
docker ps
```

### **4. Testar:**
```bash
# Health check
curl http://localhost/health

# Deve retornar: {"status":"ok"}
```

### **5. Acessar:**
- **Dashboard:** http://SEU-IP
- **API:** http://SEU-IP:3000

---

## 🔧 Se ainda não funcionar:

### **Verificar logs:**
```bash
# Logs do dashboard
docker logs academia-dashboard-prod

# Logs da API
docker logs academia-data-api-prod

# Logs do sistema
tail -f /var/log/user-data.log
```

### **Reiniciar tudo:**
```bash
cd /home/ubuntu/academia-dashboard/web-site
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

### **Verificar portas:**
```bash
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :3000
```

---

## ✅ Resultado Esperado

Após executar os comandos, você deve ver:

```bash
ubuntu@ip-172-31-0-191:~$ docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                    NAMES
abc123def456   academia-dashboard-prod  "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp       academia-dashboard-prod
def456ghi789   academia-data-api-prod   "node server.js"         2 minutes ago   Up 2 minutes   0.0.0.0:3000->3000/tcp     academia-data-api-prod
```

E os endpoints devem responder:
- `curl http://localhost/health` → `{"status":"ok"}`
- `curl http://localhost:3000/health` → `{"status":"ok"}`

---

**🎉 Pronto! Seu dashboard deve estar funcionando!**

**🌐 Acesse:** http://SEU-IP-PUBLICO
