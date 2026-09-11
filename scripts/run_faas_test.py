import boto3
import json
import time
import os
import zipfile
import shutil
import statistics
from decimal import Decimal
import sys

# Ajusta o path para importar o gerador de mocks
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../infra/mock")))
from seed_mock_tasks import generate_mock_tasks, get_dms_mock_data, seed_dynamodb

REGION = "us-east-1"
TABLE_NAME = "ddb-tcc-dms-task-monitor-task-status"
LAMBDA_NAME = "lambda-tcc-dms-task-monitor-get-status-TEST"
ROLE_NAME = "role-tcc-dms-task-monitor-TEST"

dynamodb = boto3.client("dynamodb", region_name=REGION)
iam = boto3.client("iam", region_name=REGION)
awslambda = boto3.client("lambda", region_name=REGION)

def setup_dynamodb():
    print("Checking DynamoDB table...")
    try:
        dynamodb.describe_table(TableName=TABLE_NAME)
        print("Table exists.")
    except dynamodb.exceptions.ResourceNotFoundException:
        print("Creating DynamoDB table...")
        dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{'AttributeName': 'task_identifier', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'task_identifier', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        waiter = dynamodb.get_waiter('table_exists')
        waiter.wait(TableName=TABLE_NAME)
        print("Table created.")

    # Seed data
    tasks = generate_mock_tasks(42)
    seed_dynamodb(TABLE_NAME, tasks, REGION)
    return tasks

def setup_iam_role():
    print("Checking IAM Role...")
    try:
        role = iam.get_role(RoleName=ROLE_NAME)
        role_arn = role['Role']['Arn']
    except iam.exceptions.NoSuchEntityException:
        print("Creating IAM Role...")
        assume_role_policy = {
            "Version": "2012-10-17",
            "Statement": [{"Action": "sts:AssumeRole", "Principal": {"Service": "lambda.amazonaws.com"}, "Effect": "Allow"}]
        }
        role = iam.create_role(
            RoleName=ROLE_NAME,
            AssumeRolePolicyDocument=json.dumps(assume_role_policy)
        )
        role_arn = role['Role']['Arn']
        
        iam.attach_role_policy(
            RoleName=ROLE_NAME,
            PolicyArn="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        )
        iam.attach_role_policy(
            RoleName=ROLE_NAME,
            PolicyArn="arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
        )
        # Give IAM time to propagate
        time.sleep(10)
    return role_arn

def prepare_lambda_package(tasks):
    print("Preparing Lambda package...")
    src_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../src/backend"))
    temp_dir = os.path.join(os.path.dirname(__file__), "temp_lambda")
    
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)
    
    shutil.copytree(os.path.join(src_dir, "get_DMS_task_monitor_task_status"), os.path.join(temp_dir, "get_DMS_task_monitor_task_status"))
    
    # Patch the lambda to return execution time and mock DMS
    handler_path = os.path.join(temp_dir, "get_DMS_task_monitor_task_status", "get_DMS_task_monitor_task_status.py")
    with open(handler_path, "r") as f:
        content = f.read()
    
    # Mocking DMS response
    dms_mock = json.dumps(get_dms_mock_data(tasks))
    content = content.replace(
        "tasks_from_dms = get_all_replication_tasks()",
        f"tasks_from_dms = {dms_mock}"
    )
    
    # Injecting time.time() inside the lambda to return it in the response body for precise measurement
    content = content.replace("def lambda_handler(event, _):", "def lambda_handler(event, _):\n    import time\n    t0 = time.time()")
    content = content.replace("return _response(200, tasks_to_return)", "return _response(200, {'execution_time_seconds': time.time() - t0, 'tasks': tasks_to_return})")
    
    with open(handler_path, "w") as f:
        f.write(content)
        
    zip_path = os.path.join(os.path.dirname(__file__), "lambda_package.zip")
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, temp_dir)
                zipf.write(file_path, arcname)
                
    shutil.rmtree(temp_dir)
    return zip_path

def deploy_lambda(role_arn, zip_path):
    print("Checking Lambda function...")
    try:
        awslambda.get_function(FunctionName=LAMBDA_NAME)
        print("Updating Lambda code...")
        with open(zip_path, "rb") as f:
            awslambda.update_function_code(FunctionName=LAMBDA_NAME, ZipFile=f.read())
        
        waiter = awslambda.get_waiter('function_updated_v2')
        waiter.wait(FunctionName=LAMBDA_NAME)
    except awslambda.exceptions.ResourceNotFoundException:
        print("Creating Lambda function...")
        with open(zip_path, "rb") as f:
            awslambda.create_function(
                FunctionName=LAMBDA_NAME,
                Runtime="python3.12",
                Role=role_arn,
                Handler="get_DMS_task_monitor_task_status.get_DMS_task_monitor_task_status.lambda_handler",
                Code={"ZipFile": f.read()},
                Timeout=60,
                MemorySize=128,
                Environment={"Variables": {"DYNAMODB_TABLE_NAME": TABLE_NAME, "REGION": REGION}}
            )
        waiter = awslambda.get_waiter('function_active_v2')
        waiter.wait(FunctionName=LAMBDA_NAME)

def run_tests():
    print("Running 30 iterations...")
    times = []
    payload = json.dumps({"body": json.dumps({"action": "listar_status"})})
    
    for i in range(30):
        # We also measure the network latency, but the true Lambda internal execution time is returned in the payload.
        # This matches the @runtime_log which measures execution time INSIDE the lambda.
        res = awslambda.invoke(
            FunctionName=LAMBDA_NAME,
            InvocationType='RequestResponse',
            Payload=payload
        )
        response_payload = json.loads(res['Payload'].read().decode('utf-8'))
        body = json.loads(response_payload['body'])
        if 'execution_time_seconds' in body:
            exec_time = body['execution_time_seconds']
            times.append(exec_time)
            print(f"Iteration {i+1}/30: {exec_time:.4f}s")
        else:
            print(f"Iteration {i+1}/30 failed: {body}")
            
    if times:
        avg = statistics.mean(times)
        std_dev = statistics.stdev(times) if len(times) > 1 else 0
        print("\n--- RESULTS ---")
        print(f"N: {len(times)}")
        print(f"Média: {avg:.4f}s")
        print(f"Desvio Padrão: {std_dev:.4f}s")
        
def cleanup(zip_path):
    print("Cleaning up AWS resources...")
    try:
        awslambda.delete_function(FunctionName=LAMBDA_NAME)
    except Exception as e:
        print(f"Error deleting lambda: {e}")
        
    if os.path.exists(zip_path):
        os.remove(zip_path)

if __name__ == "__main__":
    tasks = setup_dynamodb()
    role_arn = setup_iam_role()
    zip_path = prepare_lambda_package(tasks)
    deploy_lambda(role_arn, zip_path)
    run_tests()
    cleanup(zip_path)
    print("Done.")
