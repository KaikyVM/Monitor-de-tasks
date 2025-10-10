# VARIÁVEIS GERAIS PARA DEV
app_name    = "flowhub-view"
environment = "dev" 
aws_region  = "sa-east-1"
tags = {
  Project     = "Flowhub View"
  Environment = "dev" 
}
api_gateway_parent_resource_path = "/dms"


# Amplify
amplify_branch_name   = "develop" 
amplify_branch_stage  = "PRODUCTION"

# Cognito
cognito_user_groups = {
  "Engenharia"   = "Usuários com permissões administrativas totais"
  "TimeN1"       = "Acesso a tarefas e recovery"
  "TimeProjetos" = "Acesso apenas ao catálogo"
}
cognito_callback_url = "https://flowhub-view.dev-engenharia.tech-dor.com"
cognito_logout_url   = "https://flowhub-view.dev-engenharia.tech-dor.com/login"


subdomain_prefix = "flowhub-view"
hosted_zone_name = "dev-engenharia.tech-dor.com"
stepfunction_arn = "arn:aws:states:sa-east-1:038503386091:stateMachine:cdc-corp-dev-start-recovery"