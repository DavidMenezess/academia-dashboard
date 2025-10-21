# 🗄️ Configuração do Banco de Dados - Academia Dashboard

## 🎯 **Opções Disponíveis**

### **1. 🆓 SQLite (Local - Gratuito)**
- **Custo:** $0.00
- **Configuração:** Automática
- **Limitações:** Apenas local
- **Recomendado para:** Desenvolvimento e testes

### **2. ☁️ DynamoDB (AWS - Free Tier)**
- **Custo:** $0.00 (dentro do Free Tier)
- **Configuração:** Requer AWS
- **Limitações:** 25GB, 25 RCUs, 25 WCUs
- **Recomendado para:** Produção

---

## 🚀 **Configuração Rápida**

### **Opção 1: SQLite (Padrão)**
```bash
# Não precisa configurar nada!
npm start
```

### **Opção 2: DynamoDB**
```bash
# 1. Configurar variáveis de ambiente
export DATABASE_TYPE=dynamodb
export AWS_REGION=us-east-1
export DYNAMODB_TABLE=academia-dashboard

# 2. Configurar credenciais AWS (uma das opções abaixo)

# Opção A: IAM Role (Recomendado para EC2)
export AWS_USE_IAM_ROLE=true

# Opção B: Credenciais diretas
export AWS_ACCESS_KEY_ID=sua-access-key
export AWS_SECRET_ACCESS_KEY=sua-secret-key

# 3. Criar tabela no DynamoDB
npm run setup-dynamodb

# 4. Iniciar servidor
npm start
```

---

## 🔧 **Configuração Detalhada**

### **📋 Variáveis de Ambiente**

| Variável | Descrição | Padrão | Obrigatório |
|----------|-----------|--------|-------------|
| `DATABASE_TYPE` | Tipo de banco (sqlite/dynamodb) | `sqlite` | Não |
| `AWS_REGION` | Região AWS | `us-east-1` | Sim (DynamoDB) |
| `DYNAMODB_TABLE` | Nome da tabela | `academia-dashboard` | Não |
| `AWS_USE_IAM_ROLE` | Usar IAM Role | `false` | Não |
| `AWS_ACCESS_KEY_ID` | Access Key AWS | - | Sim (sem IAM) |
| `AWS_SECRET_ACCESS_KEY` | Secret Key AWS | - | Sim (sem IAM) |

### **🔑 Configuração de Credenciais AWS**

#### **Método 1: IAM Role (Recomendado para EC2)**
```bash
# Na EC2, configure a IAM Role com permissões DynamoDB
export AWS_USE_IAM_ROLE=true
```

#### **Método 2: Credenciais Diretas**
```bash
# Configure as credenciais
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
```

#### **Método 3: Arquivo de Credenciais**
```bash
# Crie ~/.aws/credentials
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
region = us-east-1
```

---

## 📊 **Limites do DynamoDB Free Tier**

### **✅ Incluído no Free Tier (PERMANENTE):**
- **25 GB** de armazenamento
- **25 RCUs** (25 milhões de leituras/mês)
- **25 WCUs** (2,6 milhões de escritas/mês)
- **2,5 milhões** de leituras de streams
- **100.000** gravações de streams

### **💡 Para seu sistema de academia:**
- **Usuários:** ~10-50 usuários
- **Vendas:** ~100-1000 vendas/dia
- **Produtos:** ~50-200 produtos
- **Relatórios:** ~100-500 consultas/dia

**Isso é MUITO menos que os limites do Free Tier!**

---

## 🛠️ **Comandos Úteis**

### **Instalação:**
```bash
# Instalar dependências
npm install

# Configurar DynamoDB
npm run setup-dynamodb
```

### **Desenvolvimento:**
```bash
# Modo desenvolvimento
npm run dev

# Modo produção
npm start
```

### **Verificação:**
```bash
# Health check
curl http://localhost:3000/api/health

# Inicializar banco
curl http://localhost:3000/api/init
```

---

## 🔍 **Troubleshooting**

### **Erro: "Unable to locate credentials"**
```bash
# Configure as credenciais AWS
export AWS_ACCESS_KEY_ID=sua-key
export AWS_SECRET_ACCESS_KEY=sua-secret
```

### **Erro: "Table not found"**
```bash
# Crie a tabela
npm run setup-dynamodb
```

### **Erro: "Region not specified"**
```bash
# Configure a região
export AWS_REGION=us-east-1
```

### **Erro: "Access Denied"**
```bash
# Verifique as permissões IAM
# Sua role/user precisa de:
# - dynamodb:CreateTable
# - dynamodb:DescribeTable
# - dynamodb:PutItem
# - dynamodb:GetItem
# -.scan
# - dynamodb:UpdateItem
# - dynamodb:DeleteItem
```

---

## 📈 **Monitoramento de Custos**

### **AWS Cost Explorer:**
1. Acesse AWS Console → Cost Explorer
2. Filtre por serviço: DynamoDB
3. Monitore uso vs. Free Tier

### **CloudWatch:**
1. Acesse AWS Console → CloudWatch
2. Métricas → DynamoDB
3. Monitore ConsumedReadCapacityUnits e ConsumedWriteCapacityUnits

### **Alertas:**
```bash
# Configure alertas para quando exceder Free Tier
# Exemplo: Alert quando > 20 RCUs ou 20 WCUs
```

---

## 🎯 **Recomendações**

### **Para Desenvolvimento:**
- Use **SQLite** (mais simples)
- Configure **DynamoDB** apenas para testes

### **Para Produção:**
- Use **DynamoDB** com **IAM Role**
- Configure **monitoramento** de custos
- Use **PAY_PER_REQUEST** (Free Tier friendly)

### **Para EC2:**
- Configure **IAM Role** na instância
- Use **DynamoDB** para persistência
- Mantenha **SQLite** como fallback

---

## 🚀 **Próximos Passos**

1. **Escolha o banco:** SQLite ou DynamoDB
2. **Configure as variáveis** de ambiente
3. **Execute setup:** `npm run setup-dynamodb`
4. **Inicie o servidor:** `npm start`
5. **Teste a API:** `curl http://localhost:3000/api/health`

**Agora seu sistema tem persistência de dados sem custos!** 🎉
