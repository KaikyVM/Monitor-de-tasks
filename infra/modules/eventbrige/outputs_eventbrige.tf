output "event_rule_arn" {
  description = "O ARN da regra do EventBridge criada."
  value       = aws_cloudwatch_event_rule.sfn_status_change_rule.arn
}