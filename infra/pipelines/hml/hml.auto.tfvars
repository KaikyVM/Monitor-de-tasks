# VARIÁVEIS GERAIS PARA HML
app_name    = "flowhub-view"
environment = "hml" 
aws_region  = "sa-east-1"
tags = {
  Project     = "Flowhub View"
  Environment = "hml" 
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
cognito_callback_url = "https://develop.d3520jzun9p5q3.amplifyapp.com"
cognito_logout_url   = "https://develop.d3520jzun9p5q3.amplifyapp.com/login"

stepfunction_arn = "arn:aws:states:sa-east-1:038503386091:stateMachine:cdc-corp-dev-start-recovery"