import boto3
import datetime
import os


def get_last_status(task_id):
    """Busca o registro mais recente para uma task no DynamoDB."""
    # Inicializa o cliente DENTRO da função
    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ.get("DYNAMODB_TABLE_NAME")
    flowhub_tbl = dynamodb.Table(table_name)

    return flowhub_tbl.get_item(Key={"task_identifier": task_id}).get("Item", {})


def update_status_in_db(task_identifier, status, execution_arn=None, updated_by=None):
    """Atualiza o status de uma task de forma segura usando UpdateExpression."""
    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ.get("DYNAMODB_TABLE_NAME")
    flowhub_tbl = dynamodb.Table(table_name)

    # Inicia a construção da expressão de atualização
    update_expression_parts = [
        "#sfn_status = :sfn_status",
        "#updated_by = :updated_by",
        "#updated_at = :updated_at",
    ]
    expression_attribute_names = {
        "#sfn_status": "sfn_status",
        "#updated_by": "updated_by",
        "#updated_at": "updated_at",
    }
    expression_attribute_values = {
        ":sfn_status": status,
        ":updated_by": updated_by or "desconhecido",
        ":updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }

    # Adiciona o ARN à atualização APENAS se ele for fornecido.
    # Isso evita que um valor nulo apague um ARN existente.
    if execution_arn:
        update_expression_parts.append("#sfn_arn = :sfn_arn")
        expression_attribute_names["#sfn_arn"] = "sfn_execution_arn"
        expression_attribute_values[":sfn_arn"] = execution_arn

    # Monta a expressão final e executa a atualização
    final_update_expression = "SET " + ", ".join(update_expression_parts)

    print("DEBUG: DENTRO DE update_status_in_db")
    print(f"Task Identifier: {task_identifier}")
    print(f"Update Expression: {final_update_expression}")
    print(f"Expression Attribute Names: {expression_attribute_names}")
    print(f"Expression Attribute Values: {expression_attribute_values}")
    print("FIM DO DEBUG")

    flowhub_tbl.update_item(
        Key={"task_identifier": task_identifier},
        UpdateExpression=final_update_expression,
        ExpressionAttributeNames=expression_attribute_names,
        ExpressionAttributeValues=expression_attribute_values,
    )
