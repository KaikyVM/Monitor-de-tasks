import os
import boto3
import json  # Adicionado o import para JSON
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("DYNAMO_TABLE_NAME")
table = dynamodb.Table(table_name)

def handler(event, context):
    print(f"Recebido evento: {event}")
    
    detail = event['detail']
    status = detail['status']
    stop_date = detail.get('stopDate')
    
    # 1. Pega a string JSON do 'input' da Step Function
    input_payload_str = detail['input']
    
    # 2. Converte a string JSON para um dicionário Python
    input_payload = json.loads(input_payload_str)
    
    # 3. Pega o task_identifier original de dentro do input
    task_identifier = input_payload['task_identifier'].lower()

    # O resto do código continua igual, mas agora usando o task_identifier correto
    update_expression = "SET #sfn_status = :status, #updated_at = :ts"
    expression_names = {
        "#sfn_status": "sfn_status",
        "#updated_at": "updated_at"
    }
    expression_values = {
        ":status": status,
        ":ts": stop_date or datetime.now(timezone.utc).isoformat() 
    }
    
    if stop_date:
        update_expression += ", #sfn_finished = :finished"
        expression_names["#sfn_finished"] = "sfn_finished_at"
        expression_values[":finished"] = stop_date
    
    table.update_item(
        Key={"task_identifier": task_identifier},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_names,
        ExpressionAttributeValues=expression_values
    )

    return {"status": "ok"}