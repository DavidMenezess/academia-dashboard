# 🏗️ Arquitetura da Infraestrutura - Academia Dashboard

## 📐 Visão Geral da Arquitetura

```
                        INTERNET
                            │
                            │
                    ┌───────▼───────┐
                    │  Elastic IP   │
                    │ (IP Público)  │
                    └───────┬───────┘
                            │
                    ┌───────▼────────┐
                    │ Security Group │
                    │   (Firewall)   │
                    └───────┬────────┘
                            │
        ┌───────────────────┼────────────────────┐
        │                   │                    │
    ┌───▼────┐         ┌────▼───┐         ┌─────▼─────┐
    │  SSH   │         │  HTTP  │         │   API     │
    │  :22   │         │  :80   │         │  :3000    │
    └────────┘         └────────┘         └───────────┘
        │                   │                    │
        └───────────────────┼────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   EC2 t2.micro │
                    │  Ubuntu 22.04  │
                    │                │
                    │  ┌──────────┐  │
                    │  │  Docker  │  │
                    │  └─────┬────┘  │
                    │        │       │
                    │  ┌─────▼────┐  │
                    │  │  Nginx   │  │
                    │  │Dashboard │  │
                    │  └──────────┘  │
                    │                │
                    │  ┌──────────┐  │
                    │  │ Node.js  │  │
                    │  │   API    │  │
                    │  └──────────┘  │
                    └────────────────┘
                            │
                    ┌───────▼────────┐
                    │  EBS Volume    │
                    │    20 GB       │
                    │   (Dados)      │
                    └────────────────┘
```

---

## 🔧 Componentes da Infraestrutura

### Camada de Rede

#### 1. VPC (Virtual Private Cloud)
- **Tipo**: VPC Default da AWS
- **CIDR**: Padrão AWS
- **Custo**: Grátis ✅
- **Função**: Isolamento de rede

#### 2. Elastic IP
- **Tipo**: IPv4 público fixo
- **Custo**: Grátis quando anexado ✅
- **Função**: IP público permanente
- **Benefício**: IP não muda após reiniciar

#### 3. Security Group
- **Regras de Entrada**:
  - SSH (22): Restrito ao seu IP
  - HTTP (80): Público (0.0.0.0/0)
  - HTTPS (443): Público (0.0.0.0/0)
  - API (3000): Público (0.0.0.0/0)
- **Regras de Saída**: 
  - Todas liberadas (necessário para updates)
- **Custo**: Grátis ✅

---

### Camada de Computação

#### 4. EC2 Instance (t2.micro)
- **vCPUs**: 1
- **Memória**: 1 GB RAM
- **Armazenamento**: 20 GB EBS
- **Sistema**: Ubuntu 22.04 LTS
- **Free Tier**: 750 horas/mês ✅
- **Custo fora do Free Tier**: ~$8.50/mês

**Softwares Instalados (via User Data)**:
- Docker & Docker Compose
- Git
- Nginx (via container)
- Node.js (via container)
- UFW Firewall
- Fail2ban
- Curl, Wget, Vim, etc.

---

### Camada de Armazenamento

#### 5. EBS Volume
- **Tipo**: gp2 (General Purpose SSD)
- **Tamanho**: 20 GB
- **Free Tier**: 30 GB/mês ✅
- **Performance**: 100 IOPS base
- **Backup**: Snapshots manuais
- **Custo fora do Free Tier**: ~$2/mês

**Conteúdo**:
```
/home/ubuntu/academia-dashboard/
├── data/                 # Dados da aplicação
├── logs/                 # Logs do sistema
├── api/                  # Código da API
└── src/                  # Frontend
```

---

### Camada de Aplicação

#### 6. Docker Containers

**Container 1: Dashboard (Nginx)**
```yaml
Image: nginx:alpine
Ports: 80:80
Volumes:
  - ./src:/usr/share/nginx/html
  - ./logs:/var/log/nginx
  - ./data:/app/data
Memory: 256M
CPU: 0.25
```

**Container 2: API (Node.js)**
```yaml
Image: node:18-alpine
Ports: 3000:3000
Volumes:
  - ./api:/app
  - ./data:/app/data
Memory: 256M
CPU: 0.25
```

---

## 🔐 Fluxo de Segurança

### 1. Acesso Externo → Servidor

```
Usuário/Internet
    ↓
Elastic IP (público)
    ↓
Security Group (firewall)
    │
    ├─ Porta 22: Apenas seu IP ✅
    ├─ Porta 80: Todos ✅
    ├─ Porta 443: Todos ✅
    └─ Porta 3000: Todos ✅
    ↓
EC2 Instance
    ↓
UFW (firewall secundário)
    ↓
Fail2ban (anti-brute force)
    ↓
Aplicação Docker
```

### 2. Proteção de Dados

```
Dados Sensíveis
    │
    ├─ terraform.tfstate
    │  └─ Não commitado (.gitignore) ✅
    │
    ├─ Chave SSH (.pem)
    │  └─ Não commitada (.gitignore) ✅
    │
    ├─ terraform.tfvars
    │  └─ Não commitado (.gitignore) ✅
    │
    └─ Credenciais AWS
       └─ Apenas em ~/.aws/ ✅
```

---

## 📊 Fluxo de Dados

### Request HTTP

```
Cliente (Navegador)
    │
    ▼
http://IP-PUBLICO
    │
    ▼
Elastic IP
    │
    ▼
Security Group (porta 80)
    │
    ▼
EC2 Instance
    │
    ▼
Docker Container (Nginx)
    │
    ▼
/usr/share/nginx/html/index.html
    │
    ▼
Response → Cliente
```

### Request API

```
Cliente (JavaScript)
    │
    ▼
http://IP-PUBLICO:3000/api/data
    │
    ▼
Elastic IP
    │
    ▼
Security Group (porta 3000)
    │
    ▼
EC2 Instance
    │
    ▼
Docker Container (Node.js)
    │
    ▼
API Handler (Express)
    │
    ▼
Lê /app/data/academia_data.json
    │
    ▼
Response JSON → Cliente
```

### Upload de Arquivo

```
Cliente (Navegador)
    │
    ▼
POST /api/upload (Excel/CSV)
    │
    ▼
Node.js API
    │
    ▼
Multer (processamento)
    │
    ▼
XLSX/CSV Parser
    │
    ▼
Grava em /app/data/academia_data.json
    │
    ▼
Response Success → Cliente
    │
    ▼
Cliente recarrega dashboard
```

---

## 🚀 Fluxo de Deploy

### Deploy Inicial (terraform apply)

```
1. Terraform Plan
   ├─ Valida configuração
   ├─ Calcula mudanças
   └─ Mostra preview
   
2. Terraform Apply
   ├─ Cria Security Group
   ├─ Cria EC2 Instance
   │  ├─ Usa AMI Ubuntu 22.04
   │  ├─ Anexa EBS 20GB
   │  └─ Injeta User Data
   ├─ Cria Elastic IP
   └─ Associa IP à Instance
   
3. User Data Script (na EC2)
   ├─ Atualiza sistema
   ├─ Instala Docker
   ├─ Instala Docker Compose
   ├─ Configura Firewall UFW
   ├─ Instala Fail2ban
   ├─ Clona repositório GitHub
   ├─ Cria dados iniciais
   ├─ Inicia containers Docker
   ├─ Cria scripts de manutenção
   └─ Gera SYSTEM_INFO.txt
   
4. Outputs
   ├─ Mostra IP público
   ├─ Mostra URLs
   ├─ Mostra comando SSH
   └─ Mostra próximos passos
```

### Atualização de Código

```
1. Desenvolvedor
   ├─ Modifica código localmente
   ├─ Git commit
   └─ Git push
   
2. Servidor (via SSH)
   ├─ sudo update-academia-dashboard
   │  ├─ Faz backup dos dados
   │  ├─ Git pull
   │  ├─ Docker-compose down
   │  ├─ Docker-compose up --build
   │  └─ Mostra logs
   └─ Aplicação atualizada
```

### Atualização de Infraestrutura

```
1. Desenvolvedor
   ├─ Modifica arquivos .tf
   └─ terraform plan
   
2. Terraform
   ├─ Calcula diferenças
   └─ Mostra mudanças
   
3. Aplicar
   ├─ terraform apply
   ├─ Atualiza recursos
   └─ Mostra novos outputs
```

---

## 🔄 Ciclo de Vida dos Recursos

### EC2 Instance

```
terraform apply
    ↓
[creating...] → [running]
    ↓
User Data executa (1x)
    ↓
Aplicação instalada
    ↓
[healthy]
    │
    ├─ Restart: Mantém dados ✅
    ├─ Stop/Start: Mantém dados ✅
    └─ Terminate: Perde dados ❌
    
terraform destroy
    ↓
[terminating...] → [terminated]
```

### Elastic IP

```
terraform apply
    ↓
[allocating...] → [allocated]
    ↓
[associating...] → [associated]
    ↓
IP disponível
    │
    ├─ Anexado à instance: Grátis ✅
    └─ Não anexado: Pago ❌
    
terraform destroy
    ↓
[disassociating...] → [releasing...]
    ↓
[released]
```

### EBS Volume

```
terraform apply
    ↓
[creating...] → [available]
    ↓
[attaching...] → [attached]
    ↓
Volume montado em /
    │
    ├─ Dados persistem entre reboots ✅
    └─ Deletado com instance ❌
        (delete_on_termination = true)
```

---

## 📈 Escalabilidade (Futuro)

### Arquitetura Multi-AZ (Sai do Free Tier)

```
                    INTERNET
                        │
                        ▼
                  Route 53 (DNS)
                        │
                        ▼
              Application Load Balancer
                    │       │
        ┌───────────┴───────┴────────────┐
        │                                │
    AZ-1a (us-east-1a)              AZ-1b (us-east-1b)
        │                                │
    EC2 Instance                    EC2 Instance
        │                                │
    EBS Volume                      EBS Volume
```

### Auto Scaling (Sai do Free Tier)

```
Auto Scaling Group
    │
    ├─ Min: 1 instance
    ├─ Desired: 2 instances
    └─ Max: 4 instances
    
Triggers:
    ├─ CPU > 70%: Scale up
    └─ CPU < 30%: Scale down
```

---

## 💾 Backup e Disaster Recovery

### Backup Automático (Implementado)

```
Cron Job (diário 3h)
    ↓
Script backup-academia-dashboard
    ↓
Copia:
    ├─ /data/*
    ├─ /logs/*
    └─ Configurações
    ↓
Tar.gz em /home/ubuntu/backups/
    ↓
Mantém últimos 7 backups
```

### Disaster Recovery (Manual)

```
Backup Local
    ↓
Download para S3 (manual)
    ↓
Novo terraform apply
    ↓
SSH no novo servidor
    ↓
Restaurar backup
    ↓
Aplicação recuperada
```

---

## 🎯 Pontos de Otimização

### Performance

1. **CloudFront CDN** (sai do Free Tier)
   - Cache de assets estáticos
   - Reduz latência global

2. **ElastiCache** (sai do Free Tier)
   - Cache de dados da API
   - Reduz load no servidor

3. **RDS** (sai do Free Tier)
   - Banco de dados gerenciado
   - Alta disponibilidade

### Segurança

1. **WAF** (sai do Free Tier)
   - Proteção contra ataques web
   - Rate limiting avançado

2. **VPC Customizada**
   - Subnets públicas/privadas
   - NAT Gateway

3. **AWS Secrets Manager**
   - Gerenciamento de secrets
   - Rotação automática

### Monitoramento

1. **CloudWatch Detailed**
   - Métricas customizadas
   - Alarmes configurados

2. **X-Ray** (sai do Free Tier)
   - Tracing de requisições
   - Debug distribuído

3. **GuardDuty** (sai do Free Tier)
   - Detecção de ameaças
   - ML-powered

---

## 📊 Métricas e Monitoramento

### Métricas Coletadas (CloudWatch Basic - Free)

```
EC2 Metrics (5 min):
    ├─ CPUUtilization
    ├─ DiskReadOps
    ├─ DiskWriteOps
    ├─ NetworkIn
    └─ NetworkOut

Custom Metrics (via scripts):
    ├─ Container Health
    ├─ API Response Time
    ├─ Disk Usage
    └─ Memory Usage
```

### Health Checks

```
Health Check Stack:
    │
    ├─ AWS EC2 Status Check
    │  └─ Instance reachability
    │
    ├─ Docker Health Check
    │  ├─ Nginx: curl localhost/health
    │  └─ API: wget localhost:3000/health
    │
    └─ Custom Script (health-check.sh)
       ├─ Ping
       ├─ SSH
       ├─ HTTP
       ├─ API
       ├─ Containers
       └─ Resources
```

---

## 🔬 Troubleshooting Flow

```
Problema Relatado
    ↓
./scripts/status.sh
    │
    ├─ Infrastructure OK?
    │  ├─ Yes → ./scripts/health-check.sh
    │  └─ No → terraform plan/apply
    │
    ├─ Application OK?
    │  ├─ Yes → Check logs
    │  └─ No → SSH + investigar
    │
    └─ Network OK?
       ├─ Yes → Check firewall
       └─ No → Security Group/IP
       
SSH no servidor
    ↓
docker ps (containers)
    ↓
docker logs (logs dos containers)
    ↓
tail -f /var/log/user-data.log
    ↓
Identificar problema
    ↓
Aplicar correção
    ↓
Verificar solução
```

---

**Arquitetura Versão:** 1.0.0  
**Free Tier Otimizado:** ✅  
**Produção Ready:** ⚠️ (Requer SSL/HTTPS)




