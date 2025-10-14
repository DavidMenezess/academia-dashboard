# 🏠 Deploy Local - Academia Dashboard

Guia completo para rodar o dashboard localmente no seu computador.

---

## ⚡ Deploy Rápido (2 minutos)

```bash
# 1. Entre na pasta do projeto
cd academia-dashboard/web-site

# 2. Inicie os containers
docker-compose up -d

# 3. Acesse o dashboard
# http://localhost:8080
```

**🎉 Pronto! Seu dashboard está rodando!**

---

## 📋 Pré-requisitos

Antes de começar, instale:

1. **Docker Desktop**
   - Windows/Mac: https://www.docker.com/products/docker-desktop
   - Linux: https://docs.docker.com/engine/install/

2. **Docker Compose** (já vem com Docker Desktop)
   - Linux: https://docs.docker.com/compose/install/

---

## 🚀 Passo a Passo Detalhado

### 1️⃣ Clone o Repositório (se ainda não tiver)

```bash
git clone https://github.com/SEU-USUARIO/academia-dashboard.git
cd academia-dashboard/web-site
```

### 2️⃣ Inicie os Containers

```bash
docker-compose up -d
```

**O que acontece:**
- ✅ Download das imagens Docker
- ✅ Build da aplicação
- ✅ Inicia o container do dashboard (porta 8080)
- ✅ Inicia o container da API (porta 3000)
- ✅ Cria volumes para dados persistentes

**Tempo:** ~2-3 minutos (primeira vez)

### 3️⃣ Verifique se está Rodando

```bash
# Ver containers ativos
docker ps

# Deve mostrar:
# - academia-dashboard (porta 8080)
# - academia-data-api (porta 3000)
```

### 4️⃣ Acesse o Dashboard

Abra seu navegador em:

- **Dashboard**: http://localhost:8080
- **API**: http://localhost:3000
- **Health Check**: http://localhost:8080/health

---

## ✨ Funcionalidades Disponíveis

✅ **Dashboard interativo** com estatísticas  
✅ **Upload de Excel/CSV** para atualizar dados  
✅ **API REST** para integração  
✅ **Dados persistentes** (salvos em `./data/`)  
✅ **Logs** disponíveis em `./logs/`  

---

## 📊 Como Usar o Upload

1. Acesse http://localhost:8080
2. Procure a seção **"📊 Atualizar Dados da Academia"**
3. Clique em **"📁 Escolher Arquivo"**
4. Selecione um arquivo:
   - Excel (.xlsx, .xls)
   - CSV (.csv)
5. Clique em **"🚀 Atualizar Dados"**
6. Aguarde o processamento
7. **Pronto!** Dashboard atualizado automaticamente

---

## 🔧 Comandos Úteis

### Ver Containers Rodando
```bash
docker ps
```

### Ver Logs
```bash
# Dashboard
docker logs academia-dashboard -f

# API
docker logs academia-data-api -f
```

### Parar os Containers
```bash
docker-compose down
```

### Reiniciar
```bash
docker-compose restart
```

### Reconstruir (após mudanças)
```bash
docker-compose up --build -d
```

### Limpar Tudo (incluindo volumes)
```bash
docker-compose down -v
```

---

## 📁 Estrutura de Pastas

```
web-site/
├── src/                    # Frontend (HTML/CSS/JS)
├── api/                    # Backend API
├── data/                   # Dados persistentes
├── logs/                   # Logs do Nginx
├── config/                 # Configurações
├── Dockerfile             # Imagem Docker
└── docker-compose.yml     # Orquestração
```

---

## 🚨 Solução de Problemas

### ❌ Erro: "Docker não encontrado"
```bash
# Instale o Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### ❌ Erro: "Porta 8080 já em uso"
```bash
# Pare o que está usando a porta
# Ou mude a porta no docker-compose.yml
ports:
  - "8081:80"  # Usa porta 8081
```

### ❌ Erro: "Container não inicia"
```bash
# Ver logs de erro
docker logs academia-dashboard

# Reconstruir
docker-compose up --build --force-recreate
```

---

## 🎯 Próximos Passos

1. ✅ **Deploy Local** (você está aqui!)
2. 🌐 **Deploy AWS** - Veja [DEPLOY-AWS.md](DEPLOY-AWS.md)

---

## 📞 Precisa de Ajuda?

- 📖 Veja o [README.md](../README.md) principal
- 🌐 Deploy na AWS? Veja [DEPLOY-AWS.md](DEPLOY-AWS.md)
- 🐛 Problemas? Abra uma issue no GitHub

---

**🚀 Agora você tem um dashboard profissional rodando localmente!**

