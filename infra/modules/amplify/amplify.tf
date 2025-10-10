
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_amplify_app" "flowhub_view_app" {
  name = var.app_name_override
  #name = "${var.app_name}-${var.environment}" # variavel

  environment_variables = {

  }

  repository           = var.repository_url 
  iam_service_role_arn = aws_iam_role.amplify_service_role.arn
  tags = {
    Project     = var.app_name
    Environment = var.environment
  }
}

# branch conectada
resource "aws_amplify_branch" "amplify_branch" {
  app_id      = aws_amplify_app.flowhub_view_app.id
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
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/amplify/${aws_amplify_app.flowhub_view_app.id}/*"
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

resource "aws_iam_role_policy_attachment" "amplify_codecommit_access" {
  role       = aws_iam_role.amplify_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_amplify_domain_association" "domain" {
  app_id      = aws_amplify_app.flowhub_view_app.id
  domain_name = data.aws_route53_zone.main.name

  sub_domain {
    branch_name = aws_amplify_branch.amplify_branch.branch_name
    prefix      = var.subdomain_prefix
  }
}