# 🔄 Guia de Comandos para Atualização do Sistema

## 📍 **ONDE USAR CADA COMANDO**

### **💻 LOCAL (Seu computador Windows)**

#### **PowerShell (Recomendado):**
```powershell
# Navegar para o projeto
cd "C:\Users\User\Documents\Estudo\academia-dashboard"

# Executar script de atualização completo
.\update-system.ps1

# Ou verificar status
.\check-status.bat
```

#### **Command Prompt:**
```cmd
# Navegar para o projeto
cd "C:\Users\User\Documents\Estudo\academia-dashboard"

# Executar script básico
update-system.bat
```

---

### **☁️ EC2 (Servidor AWS)**

#### **Conectar via SSH:**
```bash
# Usar o IP público da sua EC2
ssh -i "caminho/para/sua/chave.pem" ubuntu@18.230.87.151
```

#### **Comandos na EC2:**
```bash
# Navegar para o projeto
cd /home/ubuntu/academia-dashboard

# Atualizar código do GitHub
git pull origin main

# Reiniciar containers
cd web-site
docker-compose -f docker-compose.prod.yml restart

# Verificar status
docker ps
```

#### **Script automático na EC2:**
```bash
# Fazer o script executável
chmod +x /home/ubuntu/academia-dashboard/update-ec2-simple.sh

# Executar o script
./update-ec2-simple.sh
```

---

## 🚀 **FLUXO COMPLETO DE ATUALIZAÇÃO**

### **1. Atualização LOCAL (Seu computador):**
```powershell
# 1. Fazer alterações no código
# 2. Executar script de atualização
.\update-system.ps1
```

### **2. Atualização na EC2 (Servidor):**
```bash
# 1. Conectar via SSH
ssh -i "sua-chave.pem" ubuntu@18.230.87.151

# 2. Executar comandos de atualização
cd /home/ubuntu/academia-dashboard
git pull origin main
cd web-site
docker-compose -f docker-compose.prod.yml restart
```

---

## 📋 **COMANDOS ÚTEIS**

### **Verificar Status do Sistema:**
```bash
# Ver containers rodando
docker ps

# Ver logs do sistema
docker logs web-site-academia-dashboard

# Verificar se sistema está online
curl -I http://localhost
```

### **Comandos de Emergência:**
```bash
# Parar todos os containers
docker-compose -f docker-compose.prod.yml down

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d

# Ver logs em tempo real
docker logs -f web-site-academia-dashboard
```

---

## 🎯 **RESUMO RÁPIDO**

| Local | Comando | Onde usar |
|-------|---------|-----------|
| **Windows** | `.\update-system.ps1` | Seu computador |
| **EC2** | `git pull && docker restart` | Servidor AWS |

### **✅ Para atualizar:**
1. **Local:** Execute `.\update-system.ps1`
2. **EC2:** Execute os comandos SSH acima

### **🔍 Para verificar:**
- **Local:** Execute `check-status.bat`
- **EC2:** Execute `docker ps`




