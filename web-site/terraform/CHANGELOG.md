# 📝 Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2024-01-XX

### ✨ Adicionado

#### Infraestrutura Base
- Configuração completa do Terraform para AWS
- Suporte a Free Tier (t2.micro, 30GB EBS, 1 Elastic IP)
- Provider AWS com configuração otimizada
- Data sources para AMI Ubuntu e VPC default

#### Segurança
- Security Groups com portas mínimas necessárias
- SSH restrito a IP específico configurável
- IMDSv2 habilitado na instância EC2
- Fail2ban para proteção SSH
- Firewall UFW configurado automaticamente
- Guia de segurança completo (SECURITY.md)

#### Automação
- User Data script completo para setup automático
- Scripts bash para gerenciamento:
  - `setup.sh` - Setup inicial interativo
  - `deploy.sh` - Deploy automatizado
  - `destroy.sh` - Destruição segura com confirmação
  - `update.sh` - Atualização de infraestrutura e código
  - `connect.sh` - Conexão SSH facilitada
  - `status.sh` - Status da infraestrutura
  - `health-check.sh` - Verificação de saúde completa
  - `backup-state.sh` - Backup do Terraform state

#### Documentação
- README.md completo e detalhado
- QUICK_START.md para início rápido
- DEPLOY.md com guia de deployment
- SECURITY.md com práticas de segurança
- Inline documentation em todos os arquivos
- Comentários em português

#### Configuração
- Variáveis configuráveis via terraform.tfvars
- Arquivo de exemplo (terraform.tfvars.example)
- Tags personalizáveis para todos recursos
- Suporte a configuração de GitHub repo

#### Outputs
- IP público (Elastic IP)
- URLs do dashboard e API
- Comando SSH formatado
- Resumo completo do deployment
- Informações de Free Tier
- Próximos passos

#### DevOps
- Makefile com comandos úteis
- .gitignore configurado para segurança
- Backend remoto S3 (exemplo opcional)
- Suporte a state locking com DynamoDB

#### Aplicação
- Deploy automático via Docker Compose
- Nginx + Node.js configurados
- Health checks implementados
- Sistema de backup automático
- Scripts de atualização no servidor
- Logs centralizados

### 🔧 Configurações

#### EC2
- Tipo: t2.micro (Free Tier)
- SO: Ubuntu 22.04 LTS
- Volume: 20GB EBS gp2
- Elastic IP fixo
- Monitoring básico (Free Tier)

#### Rede
- VPC default
- Security Group customizado
- Portas: 22 (SSH), 80 (HTTP), 443 (HTTPS), 3000 (API)
- Elastic IP com associação automática

#### Docker
- Docker instalado via user-data
- Docker Compose configurado
- Containers: Nginx + Node.js
- Restart automático

### 📚 Recursos Adicionais

- Suporte a múltiplas regiões AWS
- Validação de variáveis
- Lifecycle rules para recursos
- Tags automáticas
- Health checks completos

### 🎯 Free Tier

Recursos dentro do Free Tier:
- ✅ 750 horas/mês EC2 t2.micro
- ✅ 30GB armazenamento EBS
- ✅ 1 Elastic IP anexado
- ✅ 15GB transferência dados (12 meses)
- ✅ VPC/Security Groups ilimitados

### 🔄 Próximas Versões

#### [1.1.0] - Planejado
- [ ] Suporte a Auto Scaling (sai do Free Tier)
- [ ] Load Balancer (sai do Free Tier)
- [ ] Route53 para DNS
- [ ] Certificate Manager para SSL
- [ ] CloudWatch alarms avançados

#### [1.2.0] - Planejado
- [ ] VPC customizada
- [ ] Subnets públicas/privadas
- [ ] NAT Gateway (sai do Free Tier)
- [ ] Bastion Host
- [ ] RDS para banco de dados (sai do Free Tier)

#### [2.0.0] - Futuro
- [ ] Multi-região
- [ ] Disaster Recovery
- [ ] CI/CD com GitHub Actions
- [ ] Monitoring completo
- [ ] WAF configurado

---

## Tipos de Mudanças

- `✨ Adicionado` - Novas funcionalidades
- `🔧 Modificado` - Mudanças em funcionalidades existentes
- `🗑️ Removido` - Funcionalidades removidas
- `🐛 Corrigido` - Correções de bugs
- `🔒 Segurança` - Melhorias de segurança
- `📚 Documentação` - Mudanças na documentação
- `⚡ Performance` - Melhorias de performance
- `🔄 Refatoração` - Refatoração de código

---

## Como Contribuir

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m '✨ Adiciona nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

**Versão atual: 1.0.0**

