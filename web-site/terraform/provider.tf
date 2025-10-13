# ========================================
# CONFIGURAÇÃO DO PROVIDER AWS
# ========================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend para armazenar o estado do Terraform
  # Descomente e configure conforme necessário
  # backend "s3" {
  #   bucket         = "seu-bucket-terraform-state"
  #   key            = "academia-dashboard/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  # }
}

# Provider AWS
provider "aws" {
  region = var.aws_region
  
  # Tags padrão aplicadas a todos os recursos
  default_tags {
    tags = var.tags
  }
}

# Data source para obter a AMI mais recente do Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Data source para obter a VPC padrão
data "aws_vpc" "default" {
  default = true
}

