# Amplify
output "amplify_app_url" {
  description = "URL da aplicação Amplify em DEV."
  value       = module.amplify.branch_url
}

# Cognito
output "cognito_user_pool_id" {
  description = "O ID do User Pool do Cognito de DEV."
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "O ID do App Client do Cognito de DEV."
  value       = module.cognito.user_pool_client_id
}

output "cognito_domain_endpoint" {
  description = "O endpoint do domínio do Cognito de DEV."
  value       = module.cognito.user_pool_domain_endpoint
}

# API Gateway
output "invoke_step_function_endpoint_url" {
  description = "URL do endpoint para invocar a Step Function."
  value       = module.invoke_step_function.api_gateway_endpoint_invoke_url
}

output "get_task_status_endpoint_url" {
  description = "URL do endpoint para buscar o status da tarefa."
  value       = module.get_flowhub_task_status.api_gateway_endpoint_invoke_url
}

output "test_connectivity_dms_endpoint_url" {
  description = "URL do endpoint para testar a conectividade DMS."
  value       = module.teste_conectividade_dms.api_gateway_endpoint_invoke_url
}
output "codecommit_repo_name" {
  description = "O nome do repositório CodeCommit criado."
  value       = module.codecommit.codecommit_repo_name
}