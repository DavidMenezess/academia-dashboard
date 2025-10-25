# ========================================
# INSTÂNCIA EC2 - SERVIDOR DA APLICAÇÃO
# ========================================

# Instância EC2 t2.micro (Free Tier)
resource "aws_instance" "academia_dashboard" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_dynamodb_profile.name

  vpc_security_group_ids = [aws_security_group.academia_dashboard.id]

  # Volume EBS (Free Tier: até 30GB)
  root_block_device {
    volume_type           = "gp2" # General Purpose SSD
    volume_size           = var.ebs_volume_size
    delete_on_termination = true
    encrypted             = false # Não criptografado para Free Tier

    tags = {
      Name = "${var.project_name}-${var.environment}-root-volume"
    }
  }

  # Monitoramento (desabilitado para Free Tier)
  monitoring = var.enable_detailed_monitoring

  # User Data - Script usando quick-fix.sh
  user_data = base64encode(templatefile("${path.module}/user-data-quickfix.sh", {
    aws_region = var.aws_region
  }))

  # Metadados da instância
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 para segurança
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Proteção contra terminação acidental
  disable_api_termination = false # false para facilitar testes

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Description = "Servidor EC2 para Academia Dashboard"
    OS          = "Ubuntu 22.04 LTS"
  }

  # Aguardar a criação do security group
  depends_on = [aws_security_group.academia_dashboard]

  lifecycle {
    ignore_changes = [
      user_data, # Evita recriação ao mudar user_data
      ami        # Evita recriação ao atualizar AMI
    ]
  }
}

# Elastic IP (1 grátis quando anexado à instância)
resource "aws_eip" "academia_dashboard" {
  domain   = "vpc"
  instance = aws_instance.academia_dashboard.id

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }

  depends_on = [aws_instance.academia_dashboard]
}

# Associação do Elastic IP com a instância
resource "aws_eip_association" "academia_dashboard" {
  instance_id   = aws_instance.academia_dashboard.id
  allocation_id = aws_eip.academia_dashboard.id
}