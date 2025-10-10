resource "aws_codecommit_repository" "repo" {
  repository_name = var.repository_name
  description     = "Repositório para a aplicação ${var.repository_name}"
  tags            = var.tags
}