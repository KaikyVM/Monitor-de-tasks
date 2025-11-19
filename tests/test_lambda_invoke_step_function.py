import json
import os
import pytest
import boto3
from moto import mock_aws
from unittest.mock import patch
import sys

# Adiciona a pasta 'src' ao sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

# Importa o handler e a função do repositório
from src.backend.invoke_step_Function.invoke_step_Function import lambda_handler
from src.backend.invoke_step_Function.invoke_repositories import update_status_in_db

@pytest.fixture(scope="function")
def aws_credentials():
    """Garante que credenciais FALSAS sejam usadas."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "sa-east-1"
    # --- CORREÇÃO AQUI ---
    # Define a variável de ambiente com o nome da tabela que o teste espera.
    os.environ["DYNAMODB_TABLE_NAME"] = "DMS_task_monitor_task_status"

@pytest.fixture
def mock_dynamodb_table(aws_credentials):
    """Cria a tabela DynamoDB mockada."""
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="sa-east-1")
        # Usa a variável de ambiente para criar a tabela com o nome correto
        table_name = os.environ.get("DYNAMODB_TABLE_NAME")
        table = dynamodb.create_table(
            TableName=table_name,
            KeySchema=[{"AttributeName": "task_identifier", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "task_identifier", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST"
        )
        yield table

def create_mock_api_gateway_event(body: dict, groups: list):
    """Função helper para criar um evento de API Gateway com autorizador Cognito."""
    return {
        "httpMethod": "POST",
        "body": json.dumps(body),
        "requestContext": {
            "authorizer": {
                "claims": {
                    "cognito:groups": groups
                }
            }
        }
    }

# Teste do Repositório
def test_update_status_in_db(mock_dynamodb_table):
    """Testa se a função do repositório escreve corretamente no DB."""
    table = mock_dynamodb_table
    update_status_in_db("task-123", "running", "arn:fake", "kaiky")
    
    item = table.get_item(Key={"task_identifier": "task-123"}).get("Item")
    assert item is not None
    assert item["sfn_status"] == "running"
    assert item["updated_by"] == "kaiky"

# Testes da Lambda

@patch("src.backend.invoke_step_Function.invoke_step_Function.start_step_function")
def test_lambda_handler_get_last_status_authorized(mock_start_fn, mock_dynamodb_table):
    event = create_mock_api_gateway_event(
        body={"action": "get_last_status", "task_identifier": "task-123"},
        groups=["Engenharia"]
    )
    
    response = lambda_handler(event, None)
    
    assert response["statusCode"] == 200
    body = json.loads(response['body'])
    assert body['status'] == 'Não iniciada'

@patch("src.backend.invoke_step_Function.invoke_step_Function.start_step_function")
def test_lambda_handler_start_step_function_authorized(mock_start_fn):
    mock_start_fn.return_value = {'statusCode': 200, 'body': json.dumps({'message': 'Success'})}
    event = create_mock_api_gateway_event(
        body={"task_identifier": "task-123"},
        groups=["TimeN1"]
    )
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    mock_start_fn.assert_called_once()

def test_lambda_handler_unauthorized():
    event = create_mock_api_gateway_event(
        body={"task_identifier": "task-123"},
        groups=["TimeProjetos"] 
    )
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 403