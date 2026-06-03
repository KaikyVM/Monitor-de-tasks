terraform {
  backend "s3" {
    bucket = "meu-bucket-tcc-terraform-stat" // <-- SEU BUCKET
    key    = "dms-task-monitor/tcc/terraform.tfstate" // <-- NOVA CHAVE
    region = "us-east-1" // Mesma região do bucket
  }
}

provider "aws" {
  region = var.aws_region
}
locals {
  # Definimos o escopo base do projeto para reutilização
  resource_prefix = "${var.environment}-${var.app_name}"

  # Nomes de recursos derivados seguindo o padrão <recurso>-<ambiente>-<escopo>

  # API Gateway (recurso: api)
  api_gateway_name = "api-${local.resource_prefix}"
  # CodeCommit (recurso: repo - assumindo uma abreviação comum)
  codecommit_repository_name = "repo-${local.resource_prefix}"
  # Amplify App (geralmente segue <ambiente>--projeto>)
  amplify_app_name = local.resource_prefix
  # IAM Role do Amplify (Exceção: mantém o padrão da AWS para evitar problemas)
  amplify_iam_role_name = "AmplifyServiceRole-${var.app_name}-${var.environment}"
  # Cognito (recurso: cgnt)
  cognito_user_pool_name          = "cgnt-${local.resource_prefix}-user-pool"
  cognito_user_pool_client_name   = local.resource_prefix # Nomes de cliente são mais simples
  cognito_domain_prefix           = local.resource_prefix # Domínio deve ser único
  # Lambdas e Roles do Cognito (recurso: lambda, role)
  codecommit_policy_name = "policy-${local.resource_prefix}-codecommit-access"
  cognito_lambda_iam_role_name  = "role-${local.resource_prefix}-cognito-trigger"
  cognito_pre_signup_lambda_name = "lambda-${local.resource_prefix}-pre-signup"
  cognito_post_conf_lambda_name   = "lambda-${local.resource_prefix}-post-confirmation"
  # DynamoDB (recurso: ddb)
  dynamodb_table_name = "ddb-${local.resource_prefix}-task-status"
  # Lambdas e Roles das Funções da Aplicação (recurso: lambda, role)
  get_status_lambda_name          = "lambda-${local.resource_prefix}-get-status"
  get_status_lambda_iam_role_name = "role-${local.resource_prefix}-get-status"
  invoke_sfn_lambda_name          = "lambda-${local.resource_prefix}-invoke-sfn"
  invoke_sfn_lambda_iam_role_name = "role-${local.resource_prefix}-invoke-sfn"
  test_dms_lambda_name            = "lambda-${local.resource_prefix}-test-dms"
  test_dms_lambda_iam_role_name   = "role-${local.resource_prefix}-test-dms"
  update_status_lambda_name          = "lambda-${local.resource_prefix}-update-status"
  update_status_lambda_iam_role_name = "role-${local.resource_prefix}-update-status"
}
# module "codecommit" {
#   source          = "../../modules/codecommit"
#   repository_name = local.codecommit_repository_name
#   tags            = var.tags
# }
# module "codecommit_policy_dev" {
#   source = "../../modules/iam_codecommit_policy"

#   policy_name = local.codecommit_policy_name
#   repository_name = local.codecommit_repository_name
# }

# Cria os recursos base para dev
module "api_gateway" {
  source      = "../../modules/api_gateway"
  api_name    = local.api_gateway_name
  environment = var.environment
  tags        = var.tags
}
# CRIA UM ÚNICO AUTORIZADOR COMPARTILHADO PARA A API
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "${local.resource_prefix}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = module.api_gateway.id
  provider_arns = [module.cognito.user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# Configuração de Logs para a API Gateway

# Cria um Log Group dedicado para os logs de execução da API
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${local.api_gateway_name}"
  retention_in_days = 30 # ver quanto tempo seria o ideal
}

# Cria a IAM Role que a API Gateway usará para escrever no CloudWatch
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "${local.api_gateway_name}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

# Anexa a política gerenciada da AWS que contém as permissões necessárias
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy_attachment" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Associa a Role à conta da API Gateway (necessário para o Stage usar a role)
resource "aws_api_gateway_account" "current" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}


# Cria o recurso pai /dms na nova API
resource "aws_api_gateway_resource" "dms_parent" {
  rest_api_id = module.api_gateway.id
  parent_id   = module.api_gateway.root_resource_id # Pega o ID da raiz "/"
  path_part   = "dms"
}

# CHAMADA DOS MÓDULOS

module "amplify" {
  source = "../../modules/amplify"

  # Passando nomes exatos
  app_name_override = local.amplify_app_name
  iam_role_name     = local.amplify_iam_role_name
  
  # Variáveis
  app_name       = var.app_name 
  environment    = var.environment
  repository_url = var.github_repo_url
  access_token   = var.github_pat
  branch_name    = var.amplify_branch_name  
  branch_stage   = var.amplify_branch_stage
  tags           = var.tags
  frontend_env_vars = {
    VITE_API_BASE_URL      = resource.aws_api_gateway_stage.api_stage.invoke_url
    VITE_COGNITO_AUTHORITY = module.cognito.user_pool_endpoint
    VITE_COGNITO_CLIENT_ID = module.cognito.user_pool_client_id
    VITE_REDIRECT_URI = var.cognito_callback_url
    VITE_LOGOUT_URI   = var.cognito_logout_url
  }
}

module "cognito" {
  source = "../../modules/cognito"

  # nomes exatos
  user_pool_name          = local.cognito_user_pool_name
  user_pool_client_name   = local.cognito_user_pool_client_name
  lambda_iam_role_name    = local.cognito_lambda_iam_role_name
  pre_signup_lambda_name  = local.cognito_pre_signup_lambda_name
  post_conf_lambda_name   = local.cognito_post_conf_lambda_name

  # Variáveis de configuração
  app_name                = var.app_name
  environment             = var.environment
  aws_region              = var.aws_region
  cognito_domain_prefix   = local.cognito_domain_prefix
  user_groups             = var.cognito_user_groups
  cognito_callback_urls = [var.cognito_callback_url, "http://localhost:5173"]
  cognito_logout_urls   = [var.cognito_logout_url,   "http://localhost:5173"]


  # Caminhos Lambdas
  pre_signup_lambda_source_file      = "${path.root}/../../../src/backend/pre_signup/pre_signup.py"
  post_confirmation_lambda_source_file = "${path.root}/../../../src/backend/post_confirmation/post_confirmation.py"
}

module "get_DMS_task_monitor_task_status" {
  source = "../../modules/get_DMS_task_monitor_task_status"

  # Passando os dados da API criada pelo módulo "api_gateway"
  api_gateway_id                 = module.api_gateway.id
  api_gateway_execution_arn      = module.api_gateway.execution_arn
  api_gateway_parent_resource_id = aws_api_gateway_resource.dms_parent.id
  cors_allow_origin       = "*"//var.cognito_callback_url 
  
  # Passando nomes exatos
  step_function_execution_arn_pattern = "${replace(var.stepfunction_arn, ":stateMachine:", ":execution:")}:*"
  dynamodb_table_name = local.dynamodb_table_name
  lambda_name         = local.get_status_lambda_name
  lambda_iam_role_name = local.get_status_lambda_iam_role_name

  # Variáveis de configuração
  api_gateway_authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  app_name                         = var.app_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  environment                      = var.environment
  tags                             = var.tags
  aws_region                       = var.aws_region
  lambda_source_dir_path           = "${path.root}/../../../src/backend"
  lambda_handler_path              = "get_DMS_task_monitor_task_status.get_DMS_task_monitor_task_status.lambda_handler"
}

module "invoke_step_function" {
  source = "../../modules/invoke-stepFunction"

  # Passando os dados da API criada pelo módulo "api_gateway"
  api_gateway_id                 = module.api_gateway.id
  api_gateway_execution_arn      = module.api_gateway.execution_arn
  api_gateway_parent_resource_id = aws_api_gateway_resource.dms_parent.id
  allowed_cors_origin = "*" 

  # Passando nomes exatos
  lambda_name         = local.invoke_sfn_lambda_name
  lambda_iam_role_name = local.invoke_sfn_lambda_iam_role_name

  # Variáveis de configuração
  api_gateway_authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  app_name                         = var.app_name
  environment                      = var.environment
  tags                             = var.tags
  dynamodb_table_name_param = local.dynamodb_table_name
  lambda_source_dir                = "${path.root}/../../../src/backend"
  lambda_handler_path              = "invoke_step_Function.invoke_step_Function.lambda_handler"

  # Conectando módulos
  cognito_user_pool_arn = module.cognito.user_pool_arn
  stepfunction_arn = var.stepfunction_arn
  dynamodb_table_arn    = module.get_DMS_task_monitor_task_status.dynamodb_table_arn
}

module "teste_conectividade_dms" {
  source = "../../modules/teste-conectividade-dms"

  # Passando os dados da API criada pelo módulo "api_gateway"
  api_gateway_id                 = module.api_gateway.id
  api_gateway_execution_arn      = module.api_gateway.execution_arn
  api_gateway_parent_resource_id = aws_api_gateway_resource.dms_parent.id
  allowed_cors_origin = "*"
  
  # Passando nomes exatos
  lambda_name         = local.test_dms_lambda_name
  lambda_iam_role_name = local.test_dms_lambda_iam_role_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  
  # Variáveis de configuração
  api_gateway_authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
  app_name                         = var.app_name
  environment                      = var.environment
  tags                             = var.tags
  aws_region                       = var.aws_region
  lambda_source_dir                = "${path.root}/../../../src/backend/lambda_teste_conectividade_dms"
  lambda_handler_path              = "lambda_teste_conectividade_dms.lambda_handler"
  
}
module "update_status_lambda" {
  source = "../../modules/update_status_lambda"

  app_name               = var.app_name
  environment            = var.environment
  lambda_name            = local.update_status_lambda_name
  lambda_iam_role_name   = local.update_status_lambda_iam_role_name
  lambda_handler_path    = "lambda-update-status.handler" 
  lambda_source_dir      = "${path.root}/../../../src/backend/update_status_lambda" # Verifique se este caminho está correto
  dynamodb_table_arn     = module.get_DMS_task_monitor_task_status.dynamodb_table_arn
  dynamodb_table_name    = local.dynamodb_table_name
  tags                   = var.tags
}

module "eventbridge" {
  source = "../../modules/eventbrige" # Usando a pasta que você criou

  environment                 = var.environment
  state_machine_arn           = var.stepfunction_arn
  target_lambda_arn           = module.update_status_lambda.lambda_arn
  target_lambda_function_name = module.update_status_lambda.lambda_function_name
  tags                        = var.tags
  app_name = var.app_name
}


# Deployment da API Gateway

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = module.api_gateway.id

  triggers = {
    always_redeploy = timestamp()
  }
  depends_on = [
    module.get_DMS_task_monitor_task_status.post_integration,
    module.get_DMS_task_monitor_task_status.options_integration,
    module.invoke_step_function.post_integration,
    module.invoke_step_function.options_integration,
    module.teste_conectividade_dms.post_integration,
    module.teste_conectividade_dms.options_integration,
    ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = var.environment
  rest_api_id   = module.api_gateway.id
  deployment_id = aws_api_gateway_deployment.deployment.id

  # Habilita o rastreamento com AWS X-Ray
  xray_tracing_enabled = true

  # Adiciona a configuração de logs de acesso
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
        "requestId": "$context.requestId",
        "ip": "$context.identity.sourceIp",
        "requestTime": "$context.requestTime",
        "httpMethod": "$context.httpMethod",
        "resourcePath": "$context.resourcePath",
        "status": "$context.status",
        "authorizer.principalId": "$context.authorizer.principalId",
        "integration.error": "$context.integration.error",
        "integration.status": "$context.integration.status"
    })
  }

  # Garante que a role da conta seja configurada antes do stage
  depends_on = [aws_api_gateway_account.current]
}

