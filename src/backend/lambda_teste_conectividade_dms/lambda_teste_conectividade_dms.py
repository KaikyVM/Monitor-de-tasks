import json
import boto3
import os

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}

def start_test_connection(dms_client, replication_instance_arn, endpoint_arn):
    try:
        dms_client.test_connection(
            ReplicationInstanceArn=replication_instance_arn,
            EndpointArn=endpoint_arn
        )
        return {"message": "Teste iniciado com sucesso", "status": "testing"}
    except Exception as e:
        return {"message": "Erro ao iniciar teste", "status": "failed", "error": str(e)}

def check_test_connection(dms_client, replication_instance_arn, endpoint_arn):
    try:
        describe_response = dms_client.describe_connections(
            Filters=[{"Name": "replication-instance-arn", "Values": [replication_instance_arn]}]
        )
        for connection in describe_response.get("Connections", []):
            if connection["EndpointArn"] == endpoint_arn:
                return {
                    "message": "Status verificado",
                    "status": connection.get("Status"),
                }
        return {"message": "Endpoint não encontrado", "status": "unknown"}
    except Exception as e:
        return {
            "message": "Erro ao verificar status",
            "status": "failed",
            "error": str(e),
        }

def get_instance_arn_from_task_arn(dms_client, task_arn):
    try:
        response = dms_client.describe_replication_tasks(
            Filters=[{"Name": "replication-task-arn", "Values": [task_arn]}]
        )
        if response.get("ReplicationTasks"):
            return response["ReplicationTasks"][0].get("ReplicationInstanceArn")
        return None
    except Exception:
        return None

def lambda_handler(event, context):
    try:
        dms_client = boto3.client("dms", region_name=os.environ.get("AWS_REGION", "sa-east-1"))

        # --- CORREÇÃO AQUI: Voltando para a lógica de parsing mais robusta ---
        if "body" in event and event["body"]:
            body = json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
        else:
            body = event
        # --- FIM DA CORREÇÃO ---

        body = {k.lower(): v for k, v in body.items()}

        action = body.get("action")
        endpoint_arn = body.get("endpoint_arn")
        
        replication_instance_arn = body.get("replicationinstancearn")
        task_arn = body.get("task_arn")

        if not replication_instance_arn and task_arn:
            replication_instance_arn = get_instance_arn_from_task_arn(dms_client, task_arn)

        if not action or not replication_instance_arn or not endpoint_arn:
            return {
                "statusCode": 422, "headers": CORS_HEADERS,
                "body": json.dumps({"error": "Parâmetros obrigatórios ausentes ou task_arn inválido."}),
            }

        if action == "start-test":
            result = start_test_connection(dms_client, replication_instance_arn, endpoint_arn)
        elif action == "check-test":
            result = check_test_connection(dms_client, replication_instance_arn, endpoint_arn)
        else:
            return {"statusCode": 400, "headers": CORS_HEADERS, "body": json.dumps({"error": "Ação inválida"})}

        # Esta lógica está correta, vamos mantê-la.
        # Se a função de negócio retornar um erro, o status code da API será 500.
        # Senão, será 200.
        statusCode = 500 if "error" in result else 200
        return {"statusCode": statusCode, "headers": CORS_HEADERS, "body": json.dumps(result)}

    except Exception as e:
        # Este 'except' geral agora só será acionado por erros inesperados, como o de parsing do body.
        return {"statusCode": 500, "headers": CORS_HEADERS, "body": json.dumps({"error": str(e)})}