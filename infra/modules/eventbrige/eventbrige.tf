
# Recurso 1: A Regra do EventBridge que filtra os eventos
resource "aws_cloudwatch_event_rule" "sfn_status_change_rule" {
  name        = "CaptureSfnStatusChanges-${var.app_name}-${var.environment}"
  description = "Captura eventos de mudança de status da Step Function do DMS_task_monitor"

  event_pattern = jsonencode({
    "source"      : ["aws.states"],
    "detail-type" : ["Step Functions Execution Status Change"],
    "detail" : {
      "stateMachineArn" : [var.state_machine_arn],
      "status": ["SUCCEEDED", "FAILED", "ABORTED", "TIMED_OUT"]
    }
  })

  tags = var.tags
}

# Recurso 2: O Alvo da Regra
resource "aws_cloudwatch_event_target" "invoke_update_status_lambda" {
  rule      = aws_cloudwatch_event_rule.sfn_status_change_rule.name
  target_id = "InvokeUpdateStatusLambdaTarget-${var.environment}"
  arn       = var.target_lambda_arn
}

# Recurso 3: A Permissão para o EventBridge invocar a Lambda
resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromEventBridge-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sfn_status_change_rule.arn
}