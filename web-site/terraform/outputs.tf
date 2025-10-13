# ========================================
# OUTPUTS - INFORMAÇÕES DO DEPLOY
# ========================================

# IP Público da instância (Elastic IP)
output "public_ip" {
  description = "IP Público do servidor (Elastic IP)"
  value       = aws_eip.academia_dashboard.public_ip
}

# URL do Dashboard
output "dashboard_url" {
  description = "URL do Dashboard"
  value       = "http://${aws_eip.academia_dashboard.public_ip}"
}

# URL da API
output "api_url" {
  description = "URL da API"
  value       = "http://${aws_eip.academia_dashboard.public_ip}:${var.api_port}"
}

# Health Check URL
output "health_check_url" {
  description = "URL do Health Check"
  value       = "http://${aws_eip.academia_dashboard.public_ip}/health"
}

# ID da instância EC2
output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.academia_dashboard.id
}

# Nome da instância
output "instance_name" {
  description = "Nome da instância EC2"
  value       = "${var.project_name}-${var.environment}"
}

# AMI ID utilizada
output "ami_id" {
  description = "ID da AMI Ubuntu utilizada"
  value       = data.aws_ami.ubuntu.id
}

# Security Group ID
output "security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.academia_dashboard.id
}

# Comando SSH
output "ssh_command" {
  description = "Comando para conectar via SSH"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.academia_dashboard.public_ip}"
}

# Zona de disponibilidade
output "availability_zone" {
  description = "Zona de disponibilidade da instância"
  value       = aws_instance.academia_dashboard.availability_zone
}

# Tipo da instância
output "instance_type" {
  description = "Tipo da instância EC2"
  value       = aws_instance.academia_dashboard.instance_type
}

# Estado da instância
output "instance_state" {
  description = "Estado da instância EC2"
  value       = aws_instance.academia_dashboard.instance_state
}

# Informações de custo (Free Tier)
output "free_tier_info" {
  description = "Informações sobre Free Tier"
  value = {
    instance_type     = "t2.micro (750 horas/mês grátis)"
    ebs_volume        = "${var.ebs_volume_size}GB (30GB grátis por mês)"
    elastic_ip        = "1 Elastic IP grátis quando anexado"
    data_transfer_out = "1GB grátis por mês (primeiros 15GB para novos clientes)"
  }
}

# Resumo completo
output "deployment_summary" {
  description = "Resumo completo do deployment"
  value = {
    projeto           = var.project_name
    ambiente          = var.environment
    regiao            = var.aws_region
    ip_publico        = aws_eip.academia_dashboard.public_ip
    dashboard_url     = "http://${aws_eip.academia_dashboard.public_ip}"
    api_url           = "http://${aws_eip.academia_dashboard.public_ip}:${var.api_port}"
    ssh_connect       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.academia_dashboard.public_ip}"
    instance_id       = aws_instance.academia_dashboard.id
    sistema_operacional = "Ubuntu 22.04 LTS"
  }
}

# Próximos passos
output "next_steps" {
  description = "Próximos passos após o deploy"
  value = <<-EOT
  
  ========================================
  ✅ DEPLOY CONCLUÍDO COM SUCESSO!
  ========================================
  
  📍 IP Público: ${aws_eip.academia_dashboard.public_ip}
  
  🌐 Acesse seu Dashboard:
     ${aws_eip.academia_dashboard.public_ip}
  
  🔌 API disponível em:
     http://${aws_eip.academia_dashboard.public_ip}:${var.api_port}
  
  🔑 Conectar via SSH:
     ssh -i ${var.key_name}.pem ubuntu@${aws_eip.academia_dashboard.public_ip}
  
  📋 Comandos úteis (após conectar SSH):
     • Ver informações: cat ~/SYSTEM_INFO.txt
     • Ver containers: docker ps
     • Ver logs: docker logs -f academia-dashboard-prod
     • Atualizar app: sudo update-academia-dashboard
     • Fazer backup: sudo backup-academia-dashboard
  
  ⏰ Aguarde 2-3 minutos para a aplicação inicializar completamente
  
  💰 Free Tier AWS:
     • 750 horas/mês de t2.micro (GRÁTIS)
     • ${var.ebs_volume_size}GB de armazenamento (30GB GRÁTIS)
     • 1 Elastic IP (GRÁTIS quando anexado)
  
  ========================================
  EOT
}

