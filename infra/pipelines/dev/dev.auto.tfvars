# VARIÁVEIS GERAIS PARA O TCC
app_name    = "dms-task-monitor"
environment = "tcc"
aws_region  = "us-east-1"     

tags = {
  Project     = "DMS Task Monitor" 
  Environment = "tcc"
}

api_gateway_parent_resource_path = "/monitor"

# # Amplify (Ajuste para o seu novo repositório)
amplify_branch_name  = "main" // ou a branch do seu TCC
amplify_branch_stage = "PRODUCTION"

# Cognito (Vamos simplificar para o TCC)
cognito_user_groups = {
  "Admin" = "Administradores do sistema"
  "User"  = "Usuários com permissão de visualização e execução"
}


cognito_callback_url = "https://main.xxxxxxxxxxxxxx.amplifyapp.com" // Placeholder
cognito_logout_url   = "https://main.xxxxxxxxxxxxxx.amplifyapp.com/login" // Placeholder


github_repo_url = "https://github.com/KaikyVM/Monitor-de-tasks.git"
github_pat      = "TOKEN_AQUI"

# Step Function (ARN da sua Step Function "mock")
stepfunction_arn = "arn:aws:states:us-east-1:319580610252:stateMachine:tcc-dms-task-monitor-recovery-mock"