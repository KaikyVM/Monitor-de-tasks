output "repository_clone_url_http" {
  description = "A URL de clone HTTP do repositório."
  value       = aws_codecommit_repository.repo.clone_url_http
}

output "repository_arn" {
  description = "O ARN do repositório."
  value       = aws_codecommit_repository.repo.arn
}
output "codecommit_repo_name" {
  description = "O nome do repositório CodeCommit criado."
  value       = aws_codecommit_repository.repo.repository_name
}