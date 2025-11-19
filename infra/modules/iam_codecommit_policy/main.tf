# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# resource "aws_iam_policy" "codecommit_access" {
#   name = var.policy_name
#   path = "/"
#   description = "Permite acesso de push/pull ao repositório CodeCommit ${var.repository_name}"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = [
#           "codecommit:GitPull",
#           "codecommit:GitPush"
#         ],
#         Resource = "arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.repository_name}"
#       }
#     ]
#   })
# }