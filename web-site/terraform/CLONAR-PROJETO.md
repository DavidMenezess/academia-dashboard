# 📥 Clonar Projeto - Academia Dashboard

Guia para clonar o projeto na EC2 e iniciar os containers.

---

## 🚨 Problema Identificado

O projeto `academia-dashboard` não está sendo clonado na EC2, por isso os containers não iniciam.

---

## ⚡ Solução Rápida (3 minutos)

### **1. Clonar o projeto manualmente:**
```bash
# Entrar na pasta home
cd /home/ubuntu

# Clonar o projeto
git clone https://github.com/DavidMenezess/academia-dashboard.git

# Verificar se foi clonado
ls -la academia-dashboard/
```

### **2. Entrar na pasta correta:**
```bash
cd academia-dashboard/web-site
```

### **3. Criar diretórios necessários:**
```bash
mkdir -p data logs api/uploads
```

### **4. Criar dados iniciais:**
```bash
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

### **5. Iniciar containers:**
```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

### **6. Verificar se estão rodando:**
```bash
docker ps
```

---

## 🔧 Comandos Detalhados

### **Verificar Estrutura Atual:**
```bash
# Ver o que tem na pasta home
ls -la /home/ubuntu/

# Ver se já existe algum projeto
ls -la /home/ubuntu/ | grep academia
```

### **Clonar Projeto:**
```bash
# Ir para pasta home
cd /home/ubuntu

# Clonar o repositório
git clone https://github.com/DavidMenezess/academia-dashboard.git

# Verificar se foi clonado
ls -la academia-dashboard/
ls -la academia-dashboard/web-site/
```

### **Configurar Projeto:**
```bash
# Entrar na pasta correta
cd academia-dashboard/web-site

# Verificar se tem os arquivos necessários
ls -la docker-compose.prod.yml
ls -la Dockerfile

# Criar diretórios
mkdir -p data logs api/uploads

# Ajustar permissões
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard
```

### **Iniciar Containers:**
```bash
# Parar containers existentes (se houver)
docker-compose -f docker-compose.prod.yml down || true

# Build e start
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Aguardar
sleep 30
```

### **Verificar Status:**
```bash
# Ver containers
docker ps

# Deve mostrar algo como:
# CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                    NAMES
# abc123def456   academia-dashboard-prod  "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp       academia-dashboard-prod
# def456ghi789   academia-data-api-prod   "node server.js"         2 minutes ago   Up 2 minutes   0.0.0.0:3000->3000/tcp     academia-data-api-prod

# Testar endpoints
curl http://localhost/health
curl http://localhost:3000/health
```

---

## 🚨 Solução de Problemas

### **Erro: "git command not found"**
```bash
# Instalar Git
sudo apt update
sudo apt install git -y
```

### **Erro: "Permission denied"**
```bash
# Ajustar permissões
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard
sudo chmod -R 755 /home/ubuntu/academia-dashboard
```

### **Erro: "Repository not found"**
```bash
# Verificar URL do repositório
git clone https://github.com/DavidMenezess/academia-dashboard.git

# Se não funcionar, verificar se o repositório é público
```

### **Erro: "docker-compose.prod.yml not found"**
```bash
# Verificar se está na pasta correta
pwd
ls -la

# Deve estar em: /home/ubuntu/academia-dashboard/web-site/
```

---

## 📋 Script Automático

Crie um arquivo `clone-and-start.sh`:

```bash
#!/bin/bash

echo "🚀 Clonando e iniciando Academia Dashboard..."

# Clonar projeto
cd /home/ubuntu
git clone https://github.com/DavidMenezess/academia-dashboard.git

# Entrar na pasta
cd academia-dashboard/web-site

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

# Ajustar permissões
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d --build

# Aguardar
sleep 30

# Verificar
docker ps

echo "✅ Projeto clonado e containers iniciados!"
```

Execute:
```bash
chmod +x clone-and-start.sh
./clone-and-start.sh
```

---

## ✅ Resultado Esperado

Após executar os comandos, você deve ver:

```bash
ubuntu@ip-172-31-0-14:~$ ls -la academia-dashboard/
total 20
drwxr-xr-x 4 ubuntu ubuntu 4096 Jan 15 10:30 .
drwxr-xr-x 3 ubuntu ubuntu 4096 Jan 15 10:30 ..
drwxr-xr-x 8 ubuntu ubuntu 4096 Jan 15 10:30 web-site
drwxr-xr-x 8 ubuntu ubuntu 4096 Jan 15 10:30 .git
-rw-r--r-- 1 ubuntu ubuntu 1234 Jan 15 10:30 README.md
```

E os containers rodando:
```bash
ubuntu@ip-172-31-0-14:~$ docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                    NAMES
abc123def456   academia-dashboard-prod  "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp       academia-dashboard-prod
def456ghi789   academia-data-api-prod   "node server.js"         2 minutes ago   Up 2 minutes   0.0.0.0:3000->3000/tcp     academia-data-api-prod
```

---

## 🌐 Acessar Dashboard

Após os containers estarem rodando:

1. **Descubra seu IP público:**
   ```bash
   curl ifconfig.me
   ```

2. **Acesse no navegador:**
   - **Dashboard:** http://SEU-IP-PUBLICO
   - **API:** http://SEU-IP-PUBLICO:3000

---

**🎉 Pronto! Seu projeto deve estar funcionando!**
