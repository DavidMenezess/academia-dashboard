# ========================================
# SECURITY GROUPS - CONTROLE DE ACESSO
# ========================================

# Security Group para a instância EC2
resource "aws_security_group" "academia_dashboard" {
  name_prefix = "${var.project_name}-${var.environment}-"
  description = "Security Group for Academia Dashboard"
  vpc_id      = data.aws_vpc.default.id

  # SSH - Acesso restrito ao seu IP
  ingress {
    description = "SSH restricted access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  # HTTP - Acesso público
  ingress {
    description = "HTTP public access"
    from_port   = var.dashboard_port
    to_port     = var.dashboard_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS - Acesso público (para futuro SSL)
  ingress {
    description = "HTTPS public access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API - Acesso público
  ingress {
    description = "API Node.js public access"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP - Ping para monitoramento
  ingress {
    description = "ICMP Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída - Permite todo tráfego de saída
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


