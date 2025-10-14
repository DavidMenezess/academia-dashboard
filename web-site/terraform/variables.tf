# ========================================
# VARIÁVEIS DO TERRAFORM - AWS FREE TIER
# ========================================

# Região da AWS (use a mais próxima para melhor latência)
variable "aws_region" {
  description = "Região da AWS para deploy"
  type        = string
  default     = "us-east-1" # N. Virginia - Free Tier disponível
}

# Nome do projeto
variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "academia-dashboard"
}

# Ambiente (dev, staging, prod)
variable "environment" {
  description = "Ambiente de deploy"
  type        = string
  default     = "prod"
}

# Tipo da instância EC2 (t2.micro = Free Tier)
variable "instance_type" {
  description = "Tipo da instância EC2 (t2.micro para Free Tier)"
  type        = string
  default     = "t2.micro"
}

# Chave SSH para acesso à instância
variable "key_name" {
  description = "Nome da chave SSH para acesso à instância EC2"
  type        = string
  # IMPORTANTE: Você precisa criar esta chave no AWS Console antes
}

# Seu IP público para acesso SSH (segurança)
variable "your_ip" {
  description = "Seu IP público para acesso SSH (formato: x.x.x.x/32)"
  type        = string
  # Use: curl ifconfig.me para descobrir seu IP
}

# URL do repositório GitHub
variable "github_repo" {
  description = "URL do repositório GitHub para deploy"
  type        = string
  default     = ""
  # Exemplo: https://github.com/seu-usuario/academia-dashboard.git
}

# Tags padrão para todos os recursos
variable "tags" {
  description = "Tags padrão para recursos AWS"
  type        = map(string)
  default = {
    Project     = "Academia Dashboard"
    ManagedBy   = "Terraform"
    Environment = "Production"
    CostCenter  = "Free-Tier"
  }
}

# Tamanho do volume EBS (GB) - Free Tier permite até 30GB
variable "ebs_volume_size" {
  description = "Tamanho do volume EBS em GB (Free Tier: até 30GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.ebs_volume_size >= 8 && var.ebs_volume_size <= 30
    error_message = "Tamanho do volume deve estar entre 8GB e 30GB para Free Tier."
  }
}

# Habilitar monitoramento detalhado (gera custos fora do Free Tier)
variable "enable_detailed_monitoring" {
  description = "Habilitar monitoramento detalhado CloudWatch (gera custos)"
  type        = bool
  default     = false # false para Free Tier
}

# Porta da API
variable "api_port" {
  description = "Porta da API Node.js"
  type        = number
  default     = 3000
}

# Porta do Dashboard
variable "dashboard_port" {
  description = "Porta do Dashboard (HTTP)"
  type        = number
  default     = 80
}


