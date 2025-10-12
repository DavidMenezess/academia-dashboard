# ☁️ Deploy AWS - Academia Dashboard

## 🎯 **Objetivo**: Deixar o dashboard acessível para qualquer pessoa na internet via AWS

---

## 🚀 **Deploy Automatizado (10 minutos)**

### **Passo 1: Upload para GitHub** (3 min)

```bash
# Na pasta web-site
cd C:\Users\User\Documents\Estudo\web-site

# Executar script automático
chmod +x scripts/setup-github.sh
./scripts/setup-github.sh
```

**O script vai perguntar:**
- Seu nome completo
- Seu email do GitHub
- Seu username do GitHub

### **Passo 2: Criar Repositório GitHub** (2 min)

1. **Acesse**: https://github.com/new
2. **Repository name**: `academia-dashboard`
3. **Public** ✅
4. **Create repository**

### **Passo 3: Fazer Push** (1 min)

```bash
# Execute os comandos que o script mostrará:
git remote add origin https://github.com/SEU-USERNAME/academia-dashboard.git
git push -u origin main
```

### **Passo 4: Criar Instância AWS** (3 min)

1. **AWS Console** → EC2 → Launch Instance
2. **AMI**: Ubuntu Server 22.04 LTS
3. **Instance Type**: t2.micro (Free Tier)
4. **Security Group**: 
   - SSH (22): My IP
   - HTTP (80): Anywhere (0.0.0.0/0)
   - HTTPS (443): Anywhere (0.0.0.0/0)
   - Custom TCP (3000): Anywhere (0.0.0.0/0)
5. **Launch** → Download key pair (.pem)

### **Passo 5: Deploy Automatizado** (1 min)

```bash
# Conectar à instância AWS
ssh -i "sua-chave.pem" ubuntu@SEU-IP-AWS

# Deploy automatizado via GitHub
curl -sSL https://raw.githubusercontent.com/SEU-USERNAME/academia-dashboard/main/scripts/deploy-github.sh | bash
```

**🎉 PRONTO! Dashboard online e acessível para o mundo!**

---

## 🌐 **Acessar Dashboard**

- **URL**: http://SEU-IP-PUBLICO
- **Upload**: Funcional via interface
- **API**: http://SEU-IP-PUBLICO:3000

---

## 💰 **Custos (AWS Free Tier)**

### **Gratuito por 12 meses:**
- ✅ **750 horas/mês** de t2.micro
- ✅ **30 GB** de armazenamento
- ✅ **15 GB** de transferência

### **Se exceder Free Tier:**
- 💰 **~$5-10/mês** (muito barato!)

---

## 🔧 **Comandos Úteis (na instância AWS)**

```bash
# Ver containers
docker ps

# Ver logs
docker logs academia-dashboard-aws

# Atualizar projeto
cd academia-dashboard && git pull && docker-compose -f docker-compose.aws.yml up --build -d

# Backup
/home/ubuntu/backup-dashboard.sh

# Reiniciar
docker-compose -f docker-compose.aws.yml restart
```

---

## 🔒 **Configurar Domínio (Opcional)**

### **1. Registrar Domínio**
- GoDaddy, Namecheap, Registro.br
- Custo: ~R$ 30/ano

### **2. Configurar DNS**
- Aponte para IP da EC2
- Tipo: A Record

### **3. SSL Gratuito**
```bash
# Na instância AWS
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d seu-dominio.com
```

---

## 🚨 **Solução de Problemas**

### **Erro: "Git não encontrado"**
```bash
# Instalar Git
sudo apt install git -y
```

### **Erro: "Docker não encontrado"**
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### **Erro: "Site não carrega"**
```bash
# Verificar containers
docker ps

# Verificar firewall
sudo ufw status

# Verificar logs
docker logs academia-dashboard-aws
```

### **Erro: "GitHub não encontrado"**
- Verifique se o repositório existe
- Confirme o username
- Teste: https://github.com/SEU-USERNAME/academia-dashboard

---

## 📊 **Funcionalidades Online**

✅ **Dashboard Responsivo**: Acessível de qualquer dispositivo  
✅ **Upload Excel/CSV**: Sistema completo de upload  
✅ **API RESTful**: Backend robusto  
✅ **SSL/HTTPS**: Configurável  
✅ **Monitoramento**: 24/7  
✅ **Backup**: Automático  
✅ **Escalável**: Pronto para crescimento  

---

## 🎯 **Resultado Final**

**🌍 Qualquer pessoa no mundo pode acessar seu dashboard da academia!**

- **URL**: http://SEU-IP-PUBLICO
- **Upload**: Excel/CSV funcionando
- **Mobile**: Responsivo
- **Gratuito**: Free Tier AWS
- **Profissional**: Sistema completo

---

## 🚀 **Próximos Passos**

1. ✅ **Deploy AWS** (você está aqui!)
2. 🔄 **Domínio personalizado**
3. 🔒 **SSL/HTTPS**
4. 📊 **Monitoramento avançado**
5. 🔄 **Auto Scaling**

**🎉 Sua academia agora tem um sistema profissional online!**

