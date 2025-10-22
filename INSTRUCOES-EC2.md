# 🚀 Instruções para Atualização Automática na EC2

## 📋 **PRÉ-REQUISITOS**

### **1. Conectar na EC2:**
```bash
ssh -i "sua-chave.pem" ubuntu@18.230.87.151
```

### **2. Clonar o projeto (se não existir):**
```bash
cd /home/ubuntu
git clone https://github.com/DavidMenezess/academia-dashboard.git
```

---

## 🔧 **SCRIPTS DISPONÍVEIS**

### **1. 🚀 Atualização Rápida (Recomendado):**
```bash
cd /home/ubuntu/academia-dashboard
chmod +x quick-update-ec2.sh
./quick-update-ec2.sh
```

### **2. 👁️ Monitoramento em Tempo Real:**
```bash
cd /home/ubuntu/academia-dashboard
chmod +x watch-update-ec2.sh
./watch-update-ec2.sh
```

### **3. 🎛️ Sistema Completo (Menu Interativo):**
```bash
cd /home/ubuntu/academia-dashboard
chmod +x auto-update-ec2.sh
./auto-update-ec2.sh
```

---

## 🎯 **COMO USAR PARA TESTE EM TEMPO REAL**

### **Método 1: Atualização Manual Rápida**
```bash
# 1. Conectar na EC2
ssh -i "chave.pem" ubuntu@18.230.87.151

# 2. Executar atualização
cd /home/ubuntu/academia-dashboard
./quick-update-ec2.sh

# 3. Testar no navegador
# http://18.230.87.151/login.html
```

### **Método 2: Monitoramento Automático**
```bash
# 1. Conectar na EC2
ssh -i "chave.pem" ubuntu@18.230.87.151

# 2. Iniciar monitoramento
cd /home/ubuntu/academia-dashboard
./watch-update-ec2.sh

# 3. O sistema irá verificar alterações a cada 15 segundos
# 4. Testar no navegador após cada atualização
```

### **Método 3: Sistema Completo**
```bash
# 1. Conectar na EC2
ssh -i "chave.pem" ubuntu@18.230.87.151

# 2. Executar sistema completo
cd /home/ubuntu/academia-dashboard
./auto-update-ec2.sh

# 3. Escolher opção 5 para monitoramento automático
# 4. Testar no navegador
```

---

## 🔄 **FLUXO DE TESTE EM TEMPO REAL**

### **1. No seu computador (LOCAL):**
```powershell
# Fazer alterações no código
# Executar script de atualização
.\update-system.ps1
```

### **2. Na EC2 (SERVIDOR):**
```bash
# Executar script de monitoramento
./watch-update-ec2.sh

# O sistema irá detectar alterações automaticamente
# E atualizar o sistema em tempo real
```

### **3. Testar no navegador:**
```
http://18.230.87.151/login.html
http://18.230.87.151/admin.html
http://18.230.87.151/cashier.html
```

---

## 📊 **COMANDOS ÚTEIS**

### **Verificar Status:**
```bash
docker ps                    # Ver containers
docker logs web-site-academia-dashboard  # Ver logs
curl -I http://localhost     # Testar sistema
```

### **Comandos de Emergência:**
```bash
# Parar tudo
docker-compose -f docker-compose.prod.yml down

# Iniciar tudo
docker-compose -f docker-compose.prod.yml up -d

# Ver logs em tempo real
docker logs -f web-site-academia-dashboard
```

### **Limpar Sistema:**
```bash
# Limpar containers órfãos
docker container prune -f

# Limpar imagens não utilizadas
docker image prune -f

# Limpar volumes não utilizados
docker volume prune -f
```

---

## 🎯 **RESUMO RÁPIDO**

| **Script** | **Uso** | **Comando** |
|------------|---------|-------------|
| **quick-update-ec2.sh** | Atualização rápida | `./quick-update-ec2.sh` |
| **watch-update-ec2.sh** | Monitoramento automático | `./watch-update-ec2.sh` |
| **auto-update-ec2.sh** | Sistema completo | `./auto-update-ec2.sh` |

### **✅ Para teste em tempo real:**
1. **Local:** Execute `.\update-system.ps1`
2. **EC2:** Execute `./watch-update-ec2.sh`
3. **Teste:** Acesse as URLs do sistema

### **🔍 Para verificar:**
- **Status:** `docker ps`
- **Logs:** `docker logs web-site-academia-dashboard`
- **Sistema:** `curl -I http://localhost`

---

## 🚨 **SOLUÇÃO DE PROBLEMAS**

### **Container não inicia:**
```bash
# Ver logs
docker logs web-site-academia-dashboard

# Reiniciar
docker-compose -f docker-compose.prod.yml restart
```

### **Sistema não responde:**
```bash
# Verificar containers
docker ps

# Verificar portas
netstat -tlnp | grep :80
```

### **Git pull falha:**
```bash
# Verificar status
git status

# Fazer stash
git stash

# Tentar novamente
git pull origin main
```

---

## 🎉 **PRONTO!**

Agora você pode testar em tempo real sem esperar! Os scripts irão detectar alterações automaticamente e atualizar o sistema.


