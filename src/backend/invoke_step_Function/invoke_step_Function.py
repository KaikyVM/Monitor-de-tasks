import json
import os
import boto3
from datetime import datetime, timezone, timedelta
import uuid
import re
from invoke_step_Function.invoke_repositories import (
    get_last_status,
    update_status_in_db,
)

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
}

def lambda_handler(event, context):
    try:
        # Lógica de autorização
        try:
            user_groups = event["requestContext"]["authorizer"]["claims"].get(
                "cognito:groups", []
            )
        except (KeyError, TypeError):
            user_groups = []

        print(f"Usuário tentando acesso com os grupos: {user_groups}")
        allowed_groups = ["Engenharia", "TimeN1"]
        if not any(group in user_groups for group in allowed_groups):
            print("ACESSO NEGADO.")
            return {
                "statusCode": 403,
                "headers":CORS_HEADERS,
                "body": json.dumps(
                    {
                        "message": "Acesso Proibido. Você não tem permissão para executar esta ação."
                    }
                ),
            }
        print("Acesso CONCEDIDO.")

        body = json.loads(event.get("body", "{}"))
        updated_by = body.get("updated_by", "desconhecido")

        if body.get("action") == "get_last_status":
            task_id = body.get("task_identifier")
            last_status_item = get_last_status(task_id)
            if not last_status_item:
                return {
                    "statusCode": 200,
                    "body": json.dumps({"status": "Não iniciada"}),
                    "headers": CORS_HEADERS,
                }
            return {
                "statusCode": 200,
                "body": json.dumps(last_status_item, default=str),
                "headers":CORS_HEADERS,
            }

        if "task_identifier" in body and "executionArn" not in body:
            return start_step_function(body, updated_by)
        elif "executionArn" in body:
            task_identifier = body.get("task_identifier", None)
            return check_step_function_status(
                body["executionArn"], task_identifier, updated_by
            )
        else:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Parâmetros inválidos"}),
                "headers":CORS_HEADERS,
            }

    except Exception as e:
        print(f"Erro no handler principal: {str(e)}")
        return {
            "statusCode": 500,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": str(e)}),
        }


def start_step_function(body, updated_by):
    sfn_client = boto3.client("stepfunctions")
    task_identifier = body["task_identifier"].lower()
    current_record = get_last_status(task_identifier)

    if current_record and current_record.get("sfn_status", "").lower() in [
        "running",
        "executando",
    ]:
        return {
            "statusCode": 400,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "Restart já acionado para esta task."}),
        }

    # Esta lógica agora gera o nome da tabela de parâmetros dinamicamente.
    # Ela procura por '-dev', '-hml', ou '-prd' e reconstrói o nome base.
    match = re.search(r"(-dev|-hml|-prd)", task_identifier)
    if match:
        # Pega tudo até o final do sufixo do ambiente (ex: 'flowhub-tasy-cloud-dev')
        base_identifier = task_identifier[: match.end()]
    else:
        # Se não encontrar um ambiente, usa o identificador inteiro como base (fallback)
        base_identifier = task_identifier

    sfn_params_table_name = f"{base_identifier}-sfn-params"

    payload = {
        "task_identifier": task_identifier,
        "sfn_params_table_name": sfn_params_table_name,
    }

    # ARN DA STEP FUNCTION
    state_machine_arn = os.environ.get("STEP_FUNCTION_ARN")

    # É uma boa prática verificar se a variável existe
    if not state_machine_arn:
        print("ERRO: A variável de ambiente STEP_FUNCTION_ARN não está configurada.")
        return {
            "statusCode": 500,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": "Erro de configuração interna do servidor."}),
        }

    formatted_name = (
        f"{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M')}-{task_identifier}"
    )

    # Dispara a Step Function
    response = sfn_client.start_execution(
        stateMachineArn=state_machine_arn,
        name=formatted_name,
        input=json.dumps(payload),
    )
    # atualiza o item
    # task_identifier Ele define sfn_status como "running"
    update_status_in_db(
        task_identifier=task_identifier,
        status="running",
        execution_arn=response["executionArn"],
        updated_by=updated_by,
    )
    return {
        "statusCode": 200,
        "headers": CORS_HEADERS,
        "body": json.dumps(
            {
                "message": "Step Function executada",
                "executionArn": response["executionArn"],
            }
        ),
    }


def check_step_function_status(execution_arn, task_identifier=None, updated_by=None):
    sfn_client = boto3.client("stepfunctions")
    try:
        response = sfn_client.describe_execution(executionArn=execution_arn)
        status = response["status"]
        if task_identifier:
            update_status_in_db(
                task_identifier=task_identifier,
                status=status,
                execution_arn=execution_arn,
                updated_by=updated_by
            )
        return {
            "statusCode": 200,
            "headers": CORS_HEADERS,
            "body": json.dumps({"status": status}),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": CORS_HEADERS,
            "body": json.dumps({"error": str(e)}),
        }
