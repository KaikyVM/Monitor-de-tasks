# VARIÝVEIS GERAIS PARA PRD
app_name    = "flowhub-view"
environment = "prd" 
aws_region  = "sa-east-1"
tags = {
}

api_gateway_parent_resource_path = "/dms"


# Amplify
amplify_branch_name   = "main" 
amplify_branch_stage  = "PRODUCTION"

# Cognito
cognito_user_groups = {
  "Engenharia"   = "Usuários com permissões administrativas totais"
  "TimeN1"       = "Acesso a tarefas e recovery"
  "TimeProjetos" = "Acesso apenas ao catálogo"
}

# cognito_callback_url = "https://flowhub-view.dev-engenharia.tech-dor.com"
# cognito_logout_url   = "https://flowhub-view.dev-engenharia.tech-dor.com/login"

stepfunction_arn = "arn:aws:states:sa-east-1:310438508583:stateMachine:cdc-corp-prd-start-recovery"
hosted_zone_name = "engenharia.tech-dor.com"
subdomain_prefix = "flowhub-view"

