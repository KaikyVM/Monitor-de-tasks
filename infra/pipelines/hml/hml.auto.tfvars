# VARIÁVEIS GERAIS PARA O TCC
app_name    = "dms-task-monitor" // <-- NOVO NOME DO PROJETO
environment = "tcc"              // <-- NOVO AMBIENTE
aws_region  = "us-east-1"        // <-- SUGESTÃO: Mude para uma região com mais serviços no Free Tier, como N. Virginia.

tags = {
  Project     = "DMS Task Monitor" // <-- NOVO NOME PARA TAGS
  Environment = "tcc"
}

api_gateway_parent_resource_path = "/monitor" // <-- Mais genérico

# Amplify (Ajuste para o seu novo repositório)
amplify_branch_name  = "main" // ou a branch do seu TCC
amplify_branch_stage = "PRODUCTION"

# Cognito (Vamos simplificar para o TCC)
cognito_user_groups = {
  "Admin" = "Administradores do sistema"
  "User"  = "Usuários com permissão de visualização e execução"
}
# ATENÇÃO: Essas URLs só funcionarão DEPOIS do primeiro deploy do Amplify.
# Por enquanto, coloque um valor temporário.
cognito_callback_url = "https://main.xxxxxxxxxxxxxx.amplifyapp.com" // Placeholder
cognito_logout_url   = "https://main.xxxxxxxxxxxxxx.amplifyapp.com/login" // Placeholder



# Step Function (ARN da sua Step Function "mock")
stepfunction_arn = "arn:aws:states:us-east-1:SEU_ACCOUNT_ID:stateMachine:tcc-dms-task-monitor-recovery-mock" // Placeholder