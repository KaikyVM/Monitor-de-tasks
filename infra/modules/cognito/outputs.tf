output "user_pool_id" {
  description = "O ID do Cognito User Pool."
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client_id" {
  description = "O ID do App Client para o frontend."
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "user_pool_domain_endpoint" {
  description = "A URL de endpoint do domínio do User Pool."
  value       = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "user_pool_arn" {
  description = "O ARN do Cognito User Pool."
  value       = aws_cognito_user_pool.user_pool.arn
}

output "user_pool_endpoint" {
  description = "A URL de autoridade do User Pool (issuer)."
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
}
