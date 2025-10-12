# 🏋️ Academia Dashboard

Dashboard moderno para gestão de academia com upload de Excel/CSV e deploy automatizado.

## 🚀 **Deploy Rápido**

### **Local (seu computador)**
```bash
cd web-site
docker-compose up --build -d
# Acesse: http://localhost:8080
```

### **AWS (acesso mundial)**
```bash
# 1. Upload para GitHub
./scripts/setup-github.sh

# 2. Deploy automatizado na AWS
curl -sSL https://raw.githubusercontent.com/SEU-USERNAME/academia-dashboard/main/scripts/deploy-github.sh | bash
```

## 📋 **Funcionalidades**

✅ **Dashboard Responsivo**: Interface moderna  
✅ **Upload Excel/CSV**: Sistema completo  
✅ **API Backend**: Processamento de dados  
✅ **Containerizado**: Docker  
✅ **Deploy Automatizado**: AWS via GitHub  
✅ **Monitoramento**: Health checks  
✅ **Gratuito**: AWS Free Tier  

## 📁 **Estrutura**

```
web-site/
├── src/                    # Dashboard HTML/CSS/JS
├── api/                    # API backend Node.js
├── data/                   # Dados da academia
├── config/                 # Configurações Nginx
├── scripts/                # Scripts de automação
├── Dockerfile              # Containerização
├── docker-compose.yml      # Local
├── docker-compose.aws.yml  # AWS
├── DEPLOY-LOCAL.md         # Guia deploy local
└── DEPLOY-AWS.md           # Guia deploy AWS
```

## 🎯 **Guias**

- **[DEPLOY-LOCAL.md](DEPLOY-LOCAL.md)** - Rodar localmente
- **[DEPLOY-AWS.md](DEPLOY-AWS.md)** - Deploy na AWS

## 🌐 **URLs**

- **Local**: http://localhost:8080
- **AWS**: http://SEU-IP-PUBLICO
- **GitHub**: https://github.com/SEU-USERNAME/academia-dashboard

---

**Desenvolvido com ❤️ para gestão de academias**