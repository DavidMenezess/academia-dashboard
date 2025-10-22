# 🚀 Iniciar Containers - Academia Dashboard

Guia para iniciar os containers após o Docker estar instalado.

---

## ⚡ Solução Rápida (2 minutos)

### **1. Verificar se o projeto existe:**
```bash
ls -la /home/ubuntu/academia-dashboard/
```

### **2. Entrar na pasta correta:**
```bash
cd /home/ubuntu/academia-dashboard
# Se tem web-site/, entrar nele
if [ -d "web-site" ]; then
    cd web-site
fi
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

### **7. Testar endpoints:**
```bash
curl http://localhost/health
curl http://localhost:3000/health
```

---

## 🔧 Comandos Detalhados

### **Verificar Estrutura do Projeto:**
```bash
# Ver se projeto existe
ls -la /home/ubuntu/

# Entrar na pasta
cd /home/ubuntu/academia-dashboard

# Ver estrutura
ls -la

# Se tem web-site/, entrar nele
if [ -d "web-site" ]; then
    echo "Entrando na pasta web-site..."
    cd web-site
    ls -la
fi
```

### **Configurar Projeto:**
```bash
# Criar diretórios
mkdir -p data logs api/uploads

# Ajustar permissões
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard

# Verificar se docker-compose.prod.yml existe
ls -la docker-compose.prod.yml
```

### **Iniciar Containers:**
```bash
# Parar containers existentes (se houver)
docker-compose -f docker-compose.prod.yml down || true

# Limpar sistema
docker system prune -f || true

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

# Ver logs
docker logs academia-dashboard-prod
docker logs academia-data-api-prod

# Testar endpoints
curl http://localhost/health
curl http://localhost:3000/health
```

---

## 🚨 Solução de Problemas

### **Erro: "docker-compose.prod.yml not found"**
```bash
# Verificar se está na pasta correta
pwd
ls -la

# Se não tem web-site/, criar estrutura básica
mkdir -p web-site
cd web-site
# Copiar arquivos necessários do repositório
```

### **Erro: "Permission denied"**
```bash
# Ajustar permissões
sudo chown -R ubuntu:ubuntu /home/ubuntu/academia-dashboard
sudo chmod -R 755 /home/ubuntu/academia-dashboard
```

### **Erro: "Port already in use"**
```bash
# Verificar portas em uso
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :3000

# Parar processos se necessário
sudo fuser -k 80/tcp
sudo fuser -k 3000/tcp
```

### **Containers não iniciam:**
```bash
# Ver logs detalhados
docker logs academia-dashboard-prod
docker logs academia-data-api-prod

# Rebuild completo
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

---

## ✅ Resultado Esperado

Após executar os comandos, você deve ver:

```bash
ubuntu@ip-172-31-0-14:~$ docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                    NAMES
abc123def456   academia-dashboard-prod  "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp       academia-dashboard-prod
def456ghi789   academia-data-api-prod   "node server.js"         2 minutes ago   Up 2 minutes   0.0.0.0:3000->3000/tcp     academia-data-api-prod
```

E os endpoints devem responder:
- `curl http://localhost/health` → `{"status":"ok"}`
- `curl http://localhost:3000/health` → `{"status":"ok"}`

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

**🎉 Pronto! Seu dashboard deve estar funcionando!**
