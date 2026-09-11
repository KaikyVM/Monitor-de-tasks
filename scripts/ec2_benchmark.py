import boto3
import time
import os
import json
from datetime import datetime, timezone

REGION = "us-east-1"
TABLE_NAME = "ddb-tcc-dms-task-monitor-task-status"

# Cliente boto3 instanciado no escopo global do módulo (fix: evita re-inicialização a cada chamada)
dynamodb = boto3.resource("dynamodb", region_name=REGION)

# Mock das tasks do DMS para não depender do AWS DMS real (exatamente igual ao teste FaaS)
def get_mock_dms_tasks():
    return [{"ReplicationTaskIdentifier": f"tcc-mock-task-{i:03d}", "Status": "ready"} for i in range(1, 43)]

def save_DMS_task_monitor_task_status(task_identifier, dms_status):
    # Artefato do código original mantido para replicação exata
    DMS_task_monitor_tbl = dynamodb.Table(TABLE_NAME)
    DMS_task_monitor_tbl.update_item(
        Key={"task_identifier": task_identifier},
        UpdateExpression="SET #dms = :dms, #upd_at = :upd_at",
        ExpressionAttributeNames={"#dms": "dms_status", "#upd_at": "updated_at"},
        ExpressionAttributeValues={
            ":dms": dms_status,
            ":upd_at": datetime.now(timezone.utc).isoformat(),
        },
    )

def lambda_handler_replica():
    t0 = time.time()
    
    tasks_from_dms = get_mock_dms_tasks()
    
    keys_to_get = []
    for t in tasks_from_dms:
        tid = t["ReplicationTaskIdentifier"].lower()
        keys_to_get.append({'task_identifier': tid})

    dynamo_items = {}
    if keys_to_get:
        response = dynamodb.batch_get_item(
            RequestItems={
                TABLE_NAME: {
                    'Keys': keys_to_get,
                    'ConsistentRead': True
                }
            }
        )
        for item in response.get('Responses', {}).get(TABLE_NAME, []):
            dynamo_items[item['task_identifier']] = item

    for t in tasks_from_dms:
        tid = t["ReplicationTaskIdentifier"].lower()
        fh = dynamo_items.get(tid, {})
        save_DMS_task_monitor_task_status(task_identifier=tid, dms_status=t["Status"])
        
    execution_time = time.time() - t0
    return execution_time

if __name__ == "__main__":
    print("Iniciando benchmark EC2 (N=30)...")
    times = []
    for i in range(30):
        t = lambda_handler_replica()
        times.append(t)
        print(f"Iteration {i+1}/30: {t:.4f}s")
        
    avg = sum(times) / len(times)
    var = sum((x - avg) ** 2 for x in times) / (len(times) - 1) if len(times) > 1 else 0
    std = var ** 0.5
    print("--- RESULTS ---")
    print(f"N: {len(times)}")
    print(f"Média: {avg:.4f}s")
    print(f"Desvio Padrão: {std:.4f}s")
