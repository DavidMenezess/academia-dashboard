# 🏠 Deploy Local - Academia Dashboard

## 🎯 **Objetivo**: Rodar o dashboard localmente no seu computador

---

## 🚀 **Deploy Rápido (2 minutos)**

### **1. Executar Deploy**
```bash
# Na pasta web-site
cd C:\Users\User\Documents\Estudo\web-site
docker-compose up --build -d
```

### **2. Acessar Dashboard**
- **Dashboard**: http://localhost:8080
- **API**: http://localhost:3000
- **Health Check**: http://localhost:8080/health

**🎉 PRONTO! Seu dashboard está rodando localmente!**

---

## 📋 **Funcionalidades Disponíveis**

✅ **Dashboard Responsivo**: Interface moderna da academia  
✅ **Upload Excel/CSV**: Sistema de upload de arquivos  
✅ **API Backend**: Processamento de dados  
✅ **Dados Dinâmicos**: Atualização em tempo real  
✅ **Health Checks**: Monitoramento automático  

---

## 🔧 **Comandos Úteis**

```bash
# Ver containers rodando
docker ps

# Ver logs
docker logs academia-dashboard
docker logs academia-data-api

# Parar tudo
docker-compose down

# Reiniciar
docker-compose restart

# Reconstruir
docker-compose up --build -d
```

---

## 📊 **Como Usar o Upload**

1. **Acesse**: http://localhost:8080
2. **Procure pela seção**: "📊 Atualizar Dados da Academia"
3. **Clique em**: "📁 Escolher Arquivo"
4. **Selecione**: Arquivo Excel (.xlsx, .xls) ou CSV (.csv)
5. **Clique em**: "🚀 Atualizar Dados"
6. **Aguarde**: Processamento automático
7. **Pronto**: Dashboard atualizado!

---

## 🚨 **Solução de Problemas**

### **Erro: "Docker não encontrado"**
```bash
# Instalar Docker Desktop
# Windows: https://www.docker.com/products/docker-desktop
# Mac: https://www.docker.com/products/docker-desktop
```

### **Erro: "Porta já em uso"**
```bash
# Parar containers
docker-compose down

# Ou mudar porta no docker-compose.yml
```

### **Erro: "Container não inicia"**
```bash
# Ver logs
docker logs academia-dashboard

# Reconstruir
docker-compose up --build --force-recreate
```

---

## 📁 **Estrutura do Projeto**

```
web-site/
├── src/                    # Dashboard HTML/CSS/JS
├── api/                    # API backend Node.js
├── data/                   # Dados da academia
├── config/                 # Configurações Nginx
├── scripts/                # Scripts de automação
├── Dockerfile              # Containerização
├── docker-compose.yml      # Orquestração local
└── README.md               # Este guia
```

---

## 🎯 **Próximo Passo**

Para deixar acessível na internet, use o **DEPLOY-AWS.md** 🚀

