import json
import logging
import boto3
import os
from decimal import Decimal
from get_flowhub_task_status.get_status_repositories import (
    get_all_replication_tasks,
    get_single_replication_task,
    get_step_function_status_complete_from_dynamo,
    save_flowhub_task_status,
)

from get_flowhub_task_status.runtime_decorator import runtime_log

logger = logging.getLogger()
logger.setLevel(logging.INFO)

class SafeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal): return float(obj)
        if isinstance(obj, set): return list(obj)
        try:
            return super().default(obj)
        except TypeError:
            return str(obj)

@runtime_log
def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(body, cls=SafeEncoder),
    }

@runtime_log
def lambda_handler(event, _):
    try:
        body = json.loads(event.get("body", "{}"))
        action = body.get("action")
        if not action:
            return _response(400, {"error": "Parâmetro 'action' é obrigatório."})

        if action == "listar_status":
            tasks_from_dms = get_all_replication_tasks()
            logger.info(f"DEBUG: Total de tasks do DMS encontradas: {len(tasks_from_dms)}")
            
            # 1. Preparar lista com todas as chaves para buscar no DynamoDB
            keys_to_get = []
            for t in tasks_from_dms:
                tid = t["ReplicationTaskIdentifier"].lower()
                keys_to_get.append({'task_identifier': tid})

            dynamo_items = {} # Inicia um dicionário vazio para os resultados

            # Só faz a chamada se tiver chaves para buscar
            if keys_to_get:
                # Fazer UMA ÚNICA chamada ao DynamoDB para pegar todos os itens de uma vez
                dynamodb = boto3.resource("dynamodb")
                table_name = os.environ.get("DYNAMODB_TABLE_NAME")
                
                response = dynamodb.batch_get_item(
                    RequestItems={
                        table_name: {
                            'Keys': keys_to_get,
                            'ConsistentRead': True
                        }
                    }
                )
                
                # Organizar os resultados em um dicionário para acesso rápido depois
                for item in response.get('Responses', {}).get(table_name, []):
                    dynamo_items[item['task_identifier']] = item

            tasks_to_return = []
            for t in tasks_from_dms:
                tid = t["ReplicationTaskIdentifier"].lower()
                
                # Agora, em vez de chamar uma função, apenas pegamos o resultado do dicionário
                fh = dynamo_items.get(tid, {}) # Pega o item que já buscamos ou um dict vazio
                
                is_processing = fh.get("sfn_status", "").lower() == "running"
                
                # A escrita continua acontecendo individualmente (o que é rápido e aceitável)
                save_flowhub_task_status(
                    task_identifier=tid,
                    dms_status=t["Status"]
                )
                
                tasks_to_return.append({
                    "TaskIdentifier": t["ReplicationTaskIdentifier"], "TaskArn": t["ReplicationTaskArn"],
                    "Status": t["Status"], "ReplicationInstanceArn": t.get("ReplicationInstanceArn"),
                    "SourceEndpointArn": t.get("SourceEndpointArn"),
                    "MigrationProgress": t.get("ReplicationTaskStats", {}).get("FullLoadProgressPercent", "N/A"),
                    "FlowHubStatus": fh.get("sfn_status", "Indefinido"), 
                    "sfn_finished_at": fh.get("sfn_finished_at", ""),
                    "restartDisabled": is_processing, "connectionDisabled": is_processing,
                    "updated_by": fh.get("updated_by", "N/A"),
                })
            return _response(200, tasks_to_return)

        elif action == "detalhes_task":
            task_arn = body.get("replication_task_arn") or body.get("task_arn")
            if not task_arn:
                return _response(400, {"error": "Parâmetro 'replication_task_arn' ou 'task_arn' é obrigatório"})
            task_details = get_single_replication_task(task_arn)
            if not task_details:
                return _response(404, {"error": f"Task com ARN '{task_arn}' não encontrada."})
            return _response(200, task_details)
        else:
            return _response(400, {"error": f"Ação desconhecida: '{action}'"})
    except Exception as e:
        logger.error(f"ERRO NO LAMBDA HANDLER: {str(e)}", exc_info=True)
        return _response(500, {"error": str(e)})