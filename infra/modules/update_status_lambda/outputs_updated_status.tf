output "lambda_arn" {
  description = "O ARN da função Lambda criada."
  value       = aws_lambda_function.update_status_lambda.arn
}

output "lambda_function_name" {
  description = "O nome da função Lambda criada."
  value       = aws_lambda_function.update_status_lambda.function_name
}