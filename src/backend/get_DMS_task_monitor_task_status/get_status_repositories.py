import boto3
import datetime
import os
from datetime import datetime, timezone 
from boto3.dynamodb.conditions import Key
from decimal import Decimal
from get_DMS_task_monitor_task_status.runtime_decorator import runtime_log

@runtime_log
def get_all_replication_tasks():
    """
    Busca TODAS as tarefas de replicação do DMS usando um paginador.
    """
    dms_client = boto3.client("dms", region_name=os.environ.get("REGION", "sa-east-1"))
    try:
        paginator = dms_client.get_paginator("describe_replication_tasks")
        tasks = []
        for page in paginator.paginate():
            tasks.extend(page.get("ReplicationTasks", []))
        print(f"DEBUG: Total de tasks encontradas: {len(tasks)}")
        return tasks
    except Exception as e:
        print(f"ERRO ao buscar replication tasks: {str(e)}")
        raise

@runtime_log
def get_single_replication_task(task_arn: str):
    """
    Busca os detalhes de UMA ÚNICA tarefa de replicação pelo seu ARN.
    """
    dms_client = boto3.client("dms", region_name=os.environ.get("REGION", "sa-east-1"))
    try:
        response = dms_client.describe_replication_tasks(
            Filters=[{"Name": "replication-task-arn", "Values": [task_arn]}]
        )
        tasks = response.get("ReplicationTasks", [])
        return tasks[0] if tasks else None
    except Exception as e:
        print(f"ERRO ao buscar task única com ARN {task_arn}: {str(e)}")
        raise

@runtime_log
def get_step_function_status_complete_from_dynamo(task_id):
    """Busca o status de uma Step Function específica no DynamoDB."""
    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ.get("DYNAMODB_TABLE_NAME")
    DMS_task_monitor_tbl = dynamodb.Table(table_name)
    resp = DMS_task_monitor_tbl.get_item(Key={"task_identifier": task_id})
    item = resp.get("Item", {})
    return {
        "status": item.get("sfn_status", "Indefinido"),
        "sfn_execution_arn": item.get("sfn_execution_arn", ""),
        "updated_by": item.get("updated_by", ""),
        "sfn_finished_at": item.get("sfn_finished_at", ""),
        "recovery": "recovery" in item.get("sfn_execution_arn", "").lower(),
    }

@runtime_log
def save_DMS_task_monitor_task_status(
    task_identifier, dms_status):
    """
        VERSÃO OTIMIZADA: Salva APENAS o status do DMS.
    O status da Step Function é atualizado de forma assíncrona pela outra Lambda.
    """
    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ.get("DYNAMODB_TABLE_NAME")
    DMS_task_monitor_tbl = dynamodb.Table(table_name)
    
    DMS_task_monitor_tbl.update_item(
        Key={"task_identifier": task_identifier},
        UpdateExpression="SET #dms = :dms, #upd_at = :upd_at",
        ExpressionAttributeNames={
            "#dms": "dms_status",
            "#upd_at": "updated_at",
        },
        ExpressionAttributeValues={
            ":dms": dms_status,
            ":upd_at": datetime.now(timezone.utc).isoformat(),
        },
    )

@runtime_log
def get_full_status_from_dynamo(task_id):
    """Busca o item completo de uma tarefa no DynamoDB."""
    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ.get("DYNAMODB_TABLE_NAME")
    DMS_task_monitor_tbl = dynamodb.Table(table_name)
    return DMS_task_monitor_tbl.get_item(Key={"task_identifier": task_id}).get("Item", {})
