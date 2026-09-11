import boto3
import json
import os
import random
from datetime import datetime, timezone

def generate_mock_tasks(num_tasks=42):
    tasks = []
    statuses = ["SUCCEEDED", "RUNNING", "FAILED"]
    users = ["admin", "system", "tcc_user", "lambda"]
    
    for i in range(1, num_tasks + 1):
        task_id = f"tcc-mock-task-{i:03d}"
        tasks.append({
            "task_identifier": task_id,
            "sfn_status": random.choice(statuses),
            "sfn_finished_at": datetime.now(timezone.utc).isoformat(),
            "updated_by": random.choice(users),
            # Atributos de DMS que a Lambda salvará depois
            "dms_status": "ready"
        })
    return tasks

def seed_dynamodb(table_name, tasks, region="us-east-1"):
    dynamodb = boto3.resource("dynamodb", region_name=region)
    table = dynamodb.Table(table_name)
    
    print(f"Seeding {len(tasks)} tasks in DynamoDB table '{table_name}'...")
    
    with table.batch_writer() as batch:
        for task in tasks:
            batch.put_item(Item=task)
            
    print("Seed completed successfully!")

def get_dms_mock_data(tasks):
    # This generates the exact format that DMS describe_replication_tasks returns
    # We can use this to monkeypatch the Lambda for testing
    dms_tasks = []
    for t in tasks:
        dms_tasks.append({
            "ReplicationTaskIdentifier": t["task_identifier"],
            "ReplicationTaskArn": f"arn:aws:dms:us-east-1:123456789012:task:{t['task_identifier']}",
            "Status": "ready",
            "ReplicationInstanceArn": "arn:aws:dms:us-east-1:123456789012:rep:mock-instance",
            "SourceEndpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:mock-source",
            "ReplicationTaskStats": {"FullLoadProgressPercent": 100}
        })
    return dms_tasks

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Seed DynamoDB with mock tasks")
    parser.add_argument("--table", type=str, default="ddb-tcc-dms-task-monitor-task-status", help="DynamoDB table name")
    parser.add_argument("--region", type=str, default="us-east-1", help="AWS region")
    parser.add_argument("--generate-json", action="store_true", help="Only generate JSON, do not seed")
    
    args = parser.parse_args()
    
    mock_tasks = generate_mock_tasks(42)
    
    if args.generate_json:
        with open("mock_tasks.json", "w") as f:
            json.dump(mock_tasks, f, indent=2)
        print("Generated mock_tasks.json")
    else:
        seed_dynamodb(args.table, mock_tasks, args.region)
