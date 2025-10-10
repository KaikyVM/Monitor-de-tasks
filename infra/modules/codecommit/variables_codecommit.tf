variable "repository_name" {
  description = "O nome do repo no CodeCommit."
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas."
  type        = map(string)
  default     = {}
}
