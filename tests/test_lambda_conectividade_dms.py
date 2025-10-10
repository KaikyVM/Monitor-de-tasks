import json
import boto3
import os
import pytest
from unittest.mock import patch, MagicMock

# Importa a função lambda real que você quer testar
from src.backend.lambda_teste_conectividade_dms.lambda_teste_conectividade_dms import (
    lambda_handler,
)

# O @patch agora mira no 'boto3.client' DENTRO do arquivo da lambda.
# Isso garante que, quando o handler for chamado, ele receba um cliente mockado.
@patch("src.backend.lambda_teste_conectividade_dms.lambda_teste_conectividade_dms.boto3.client")
def test_lambda_start_success_with_instance_arn(mock_boto3_client):
    """Testa o caminho feliz de 'start-test' usando ReplicationInstanceArn."""
    # ARRANGE
    mock_dms = MagicMock()
    mock_boto3_client.return_value = mock_dms
    
    # Preparamos o retorno da função que será chamada
    mock_dms.test_connection.return_value = {} # Sucesso não retorna nada de especial

    event = {"body": json.dumps({
        "action": "start-test",
        "ReplicationInstanceArn": "arn:aws:dms:sa-east-1:123:rep:instance",
        "endpoint_arn": "arn:aws:dms:sa-east-1:123:endpoint:source",
    })}

    # ACT
    response = lambda_handler(event, None)
    body = json.loads(response["body"])

    # ASSERT
    assert response["statusCode"] == 200
    assert body["status"] == "testing"
    # Verificamos se a função mockada foi chamada com os parâmetros corretos
    mock_dms.test_connection.assert_called_once_with(
        ReplicationInstanceArn="arn:aws:dms:sa-east-1:123:rep:instance",
        EndpointArn="arn:aws:dms:sa-east-1:123:endpoint:source",
    )

@patch("src.backend.lambda_teste_conectividade_dms.lambda_teste_conectividade_dms.boto3.client")
def test_lambda_start_success_with_task_arn(mock_boto3_client):
    """Testa o caminho feliz de 'start-test' usando a retrocompatibilidade com task_arn."""
    # ARRANGE
    mock_dms = MagicMock()
    mock_boto3_client.return_value = mock_dms
    
    # Preparamos o retorno das DUAS funções que serão chamadas
    mock_dms.describe_replication_tasks.return_value = {
        "ReplicationTasks": [{"ReplicationInstanceArn": "arn:aws:dms:sa-east-1:123:rep:instance-from-task"}]
    }
    mock_dms.test_connection.return_value = {}

    event = {"body": json.dumps({
        "action": "start-test",
        "task_arn": "arn:aws:dms:sa-east-1:123:task:some-task",
        "endpoint_arn": "arn:aws:dms:sa-east-1:123:endpoint:source",
    })}

    # ACT
    response = lambda_handler(event, None)
    body = json.loads(response["body"])

    # ASSERT
    assert response["statusCode"] == 200
    assert body["status"] == "testing"
    # Verificamos se a função que busca o ARN foi chamada
    mock_dms.describe_replication_tasks.assert_called_once()
    # E verificamos se o test_connection usou o ARN correto, vindo da busca
    mock_dms.test_connection.assert_called_once_with(
        ReplicationInstanceArn="arn:aws:dms:sa-east-1:123:rep:instance-from-task",
        EndpointArn="arn:aws:dms:sa-east-1:123:endpoint:source",
    )

# Para este teste, não precisamos mockar o boto3, pois a função deve retornar antes.
def test_lambda_invalid_parameters():
    """Testa a validação de parâmetros faltando."""
    event = {"body": json.dumps({"action": "start-test"})}
    response = lambda_handler(event, None)
    body = json.loads(response["body"])

    assert response["statusCode"] == 422
    assert "obrigatórios ausentes" in body.get("error", "")