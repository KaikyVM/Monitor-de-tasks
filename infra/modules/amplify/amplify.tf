
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_amplify_app" "DMS_task_monitor_app" {
  name = var.app_name_override
  #name = "${var.app_name}-${var.environment}" # variavel

  environment_variables = {

  }

  repository           = var.repository_url 
  iam_service_role_arn = aws_iam_role.amplify_service_role.arn
  access_token = var.access_token
  tags = {
    Project     = var.app_name
    Environment = var.environment
  }
}

# branch conectada
resource "aws_amplify_branch" "amplify_branch" {
  app_id      = aws_amplify_app.DMS_task_monitor_app.id
  branch_name = var.branch_name # colocando variavel
  stage       = var.branch_stage

  enable_auto_build = true
  framework         = "React"

  # DEPOIS - O jeito novo, flexível e correto
  environment_variables = merge(var.frontend_env_vars, {
    BUILD_TRIGGER = timestamp() # Mantém o trigger para forçar o build
  })
  tags = {
    Project     = var.app_name
    Environment = var.environment
  }
}
# Adicione este bloco ao final de infra/modules/amplify/amplify.tf

resource "aws_iam_policy" "amplify_ssm_policy" {
  name = format("AmplifySSMAccess-%s", var.app_name_override)
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ssm:GetParameters",
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/amplify/${aws_amplify_app.DMS_task_monitor_app.id}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amplify_ssm_access" {
  role       = aws_iam_role.amplify_service_role.name
  policy_arn = aws_iam_policy.amplify_ssm_policy.arn
}

# role amplify codecommit
resource "aws_iam_role" "amplify_service_role" {
  name = var.iam_role_name
  #name = "AmplifyServiceRole-${var.app_name}-${var.environment}" 

  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "amplify.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

