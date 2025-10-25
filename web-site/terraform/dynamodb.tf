# ========================================
# DYNAMODB - BANCO DE DADOS
# ========================================

# Tabela DynamoDB para o sistema da academia
resource "aws_dynamodb_table" "academia_dashboard" {
  name         = "${var.project_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Free Tier friendly
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # Índice Global Secundário para consultas por categoria
  global_secondary_index {
    name            = "CategoryIndex"
    hash_key        = "category"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Configurações de proteção de dados
  point_in_time_recovery {
    enabled = false # Desabilitado para Free Tier
  }

  server_side_encryption {
    enabled = false # Desabilitado para Free Tier
  }

  # Tags para organização e custos
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-database"
    Description = "Tabela DynamoDB para sistema da academia"
    Service     = "DynamoDB"
    CostCenter  = "Free-Tier"
  })

  # Lifecycle para evitar custos desnecessários
  lifecycle {
    prevent_destroy = false # Permitir destruição para testes
  }
}

# ========================================
# IAM ROLE PARA EC2 ACESSAR DYNAMODB
# ========================================

# Role IAM para a instância EC2
resource "aws_iam_role" "ec2_dynamodb_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Description = "Role IAM para EC2 acessar DynamoDB"
    Service     = "IAM"
    CostCenter  = "Free-Tier"
  })
}

# Política para acessar DynamoDB
resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "${var.project_name}-${var.environment}-dynamodb-policy"
  description = "Política para acessar tabela DynamoDB da academia"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          aws_dynamodb_table.academia_dashboard.arn,
          "${aws_dynamodb_table.academia_dashboard.arn}/index/*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-dynamodb-policy"
    Description = "Política para acessar DynamoDB"
    Service     = "IAM"
    CostCenter  = "Free-Tier"
  })
}

# Anexar política à role
resource "aws_iam_role_policy_attachment" "ec2_dynamodb_policy" {
  role       = aws_iam_role.ec2_dynamodb_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

# Instance Profile para a EC2
resource "aws_iam_instance_profile" "ec2_dynamodb_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_dynamodb_role.name

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ec2-profile"
    Description = "Instance Profile para EC2 acessar DynamoDB"
    Service     = "IAM"
    CostCenter  = "Free-Tier"
  })
}

# ========================================
# VARIÁVEIS DE AMBIENTE PARA A APLICAÇÃO
# ========================================

# Outputs para configuração da aplicação
output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.academia_dashboard.name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = aws_dynamodb_table.academia_dashboard.arn
}

output "dynamodb_table_endpoint" {
  description = "Endpoint da tabela DynamoDB"
  value       = "https://dynamodb.${var.aws_region}.amazonaws.com"
}

output "iam_role_arn" {
  description = "ARN da role IAM para EC2"
  value       = aws_iam_role.ec2_dynamodb_role.arn
}






