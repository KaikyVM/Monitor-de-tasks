output "app_id" {
  description = "ID Amplify."
  value       = aws_amplify_app.DMS_task_monitor_app.id
}

output "app_default_domain" {
  description = "dominio padrão."
  value       = aws_amplify_app.DMS_task_monitor_app.default_domain
}

output "branch_url" {
  description = "URL específica da branch conectada."
  value       = "https://${aws_amplify_branch.amplify_branch.branch_name}.${aws_amplify_app.DMS_task_monitor_app.id}.amplifyapp.com"
}

output "default_domain" {
  description = "O domínio padrão da aplicação Amplify."
  value       = aws_amplify_app.DMS_task_monitor_app.default_domain
}