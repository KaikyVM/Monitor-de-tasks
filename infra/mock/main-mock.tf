# ===================================================================
# ARQUIVO ÚNICO PARA INFRAESTRUTURA MOCK DO TCC
# Cria um ambiente de simulação para o DMS Task Monitor
# ===================================================================

# --- 1. Configuração do Provedor e Variáveis ---

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "Região da AWS para criar os recursos."
  type        = string
  default     = "us-east-1" # N. Virginia tem mais opções no Free Tier
}

variable "db_password" {
  description = "Senha para o usuário do banco de dados de simulacao."
  type        = string
  sensitive   = true # Impede que a senha apareça nos logs do Terraform
}

# --- 2. Rede (VPC, Subnets e Security Groups) ---

# Usa a VPC e subnets padrão da sua conta para simplificar
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group para a instância EC2 que vai rodar o banco de dados
resource "aws_security_group" "ec2_db_sg" {
  name        = "tcc-ec2-db-sg"
  description = "Permite acesso SSH e acesso do DMS ao PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH para debug"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # AVISO: Aberto para o mundo. Para o TCC está OK.
  }

  ingress {
    description     = "PostgreSQL a partir do DMS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.dms_sg.id] # Apenas o DMS pode acessar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tcc-ec2-db-sg" }
}

# Security Group para a instância de replicação do DMS
resource "aws_security_group" "dms_sg" {
  name        = "tcc-dms-sg"
  description = "Security Group para a instancia de replicacao do DMS"
  vpc_id      = data.aws_vpc.default.id

  # Não precisa de regras de entrada, pois ele inicia a conexão
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tcc-dms-sg" }
}


# --- 3. Instância EC2 com Banco de Dados PostgreSQL ---

# Pega a AMI mais recente do Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Cria a instância EC2 (Free Tier)
resource "aws_instance" "db_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro" # Free Tier
  vpc_security_group_ids = [aws_security_group.ec2_db_sg.id]
  key_name      = "tcc-key" # IMPORTANTE: Troque pelo nome do seu par de chaves para poder acessar via SSH

  # Script que roda na inicialização para instalar e configurar o PostgreSQL
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install postgresql14 -y
              postgresql-setup --initdb
              
              # Configura o PostgreSQL para aceitar conexões externas
              echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf
              echo "host all all 0.0.0.0/0 md5" >> /var/lib/pgsql/data/pg_hba.conf
              
              systemctl start postgresql
              systemctl enable postgresql
              
              # Cria as bases de dados e o usuário para o DMS
              sudo -u postgres psql -c "CREATE DATABASE source_db;"
              sudo -u postgres psql -c "CREATE DATABASE target_db;"
              sudo -u postgres psql -c "CREATE USER dms_user WITH PASSWORD '${var.db_password}';"
              sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE source_db TO dms_user;"
              sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE target_db TO dms_user;"
              EOF

  tags = { Name = "tcc-db-server" }
}

# --- 4. Recursos do AWS DMS ---

# Grupo de subnets para a replicação
resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id   = "tcc-dms-subnet-group"
  replication_subnet_group_description = "Subnets para o TCC DMS"
  subnet_ids                    = data.aws_subnets.default.ids
}

# Instância de Replicação (Free Tier)
resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id   = "tcc-dms-instance"
  replication_instance_class = "dms.t3.micro" # Free Tier
  allocated_storage         = 20
  vpc_security_group_ids    = [aws_security_group.dms_sg.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.id
  
  tags = { Name = "tcc-dms-instance" }
}

# Endpoint de Origem
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "tcc-source-pg-endpoint"
  endpoint_type = "source"
  engine_name   = "postgres"
  server_name   = aws_instance.db_server.private_ip
  port          = 5432
  database_name = "source_db"
  username      = "dms_user"
  password      = var.db_password

  depends_on = [aws_instance.db_server]
  tags = { Name = "tcc-source-endpoint" }
}

# Endpoint de Destino
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "tcc-target-pg-endpoint"
  endpoint_type = "target"
  engine_name   = "postgres"
  server_name   = aws_instance.db_server.private_ip
  port          = 5432
  database_name = "target_db"
  username      = "dms_user"
  password      = var.db_password

  depends_on = [aws_instance.db_server]
  tags = { Name = "tcc-target-endpoint" }
}

# Tarefa de Replicação 1 (Saudável)
resource "aws_dms_replication_task" "healthy_task" {
  replication_task_id      = "tcc-healthy-task"
  migration_type           = "full-load-and-cdc" # Carga total + contínua
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  
  table_mappings = jsonencode({
    rules = [{
      "rule-type"        = "selection",
      "rule-id"          = "1",
      "rule-name"        = "select-all-public",
      "object-locator"   = { "schema-name" = "public", "table-name" = "%" },
      "rule-action"      = "include",
      "load-order"       = 1
    }]
  })

  replication_task_settings = jsonencode({
    Logging = {
      EnableLogging = true
    }
  })
  
  tags = { Name = "tcc-healthy-task" }
}
# Tarefa de Replicação 2 (Para a gente "quebrar" e recuperar)
resource "aws_dms_replication_task" "failing_task" {
  replication_task_id      = "tcc-failing-task" # <-- NOME DIFERENTE
  migration_type           = "full-load"        # Apenas carga total, para ela parar sozinha
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  
  table_mappings = jsonencode({
    rules = [{
      "rule-type"        = "selection",
      "rule-id"          = "1",
      "rule-name"        = "select-all-public",
      "object-locator"   = { "schema-name" = "public", "table-name" = "%" },
      "rule-action"      = "include",
      "load-order"       = 1
    }]
  })

  # Para garantir que a tarefa não comece automaticamente
  start_replication_task = false
  
  tags = { Name = "tcc-failing-task" }
}

# Não se esqueça de adicionar o ARN dela nos outputs também
output "dms_failing_task_arn" {
  description = "ARN da tarefa de replicacao do DMS para simular falha."
  value       = aws_dms_replication_task.failing_task.replication_task_arn
}

# --- 5. Step Function de Simulação (Mock) ---

# Role que a Step Function vai usar
resource "aws_iam_role" "sfn_role" {
  name = "tcc-step-function-mock-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.${var.aws_region}.amazonaws.com"
      }
    }]
  })
}

# A State Machine em si
resource "aws_sfn_state_machine" "mock_recovery" {
  name     = "tcc-dms-task-monitor-recovery-mock"
  role_arn = aws_iam_role.sfn_role.arn

  definition = <<-EOF
  {
    "Comment": "Um fluxo de trabalho de simulacao para o TCC",
    "StartAt": "SimulandoRecovery",
    "States": {
      "SimulandoRecovery": {
        "Type": "Wait",
        "Seconds": 15,
        "Next": "RecoveryConcluido"
      },
      "RecoveryConcluido": {
        "Type": "Succeed"
      }
    }
  }
  EOF

  tags = { Name = "tcc-sfn-mock" }
}

# --- 6. Outputs ---

output "ec2_public_ip" {
  description = "IP Público da instância EC2 para acesso via SSH."
  value       = aws_instance.db_server.public_ip
}

output "dms_healthy_task_arn" {
  description = "ARN da tarefa de replicacao do DMS."
  value       = aws_dms_replication_task.healthy_task.replication_task_arn
}

output "step_function_mock_arn" {
  description = "ARN da Step Function de simulacao para usar na replicacao principal."
  value       = aws_sfn_state_machine.mock_recovery.id
}