# No arquivo: tests/test_lambda_get_flowhub_task_status.py

import json
import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime
import sys
import os

# Adiciona a pasta 'src' ao sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))


# Importa o handler da Lambda que estamos a testar
from src.backend.get_flowhub_task_status.get_flowhub_task_status import lambda_handler

# Importa as funções do repositório para testá-las diretamente
from src.backend.get_flowhub_task_status.get_status_repositories import (
    save_flowhub_task_status,
    get_step_function_status_complete_from_dynamo
)

# --- Testes de Unidade para as Funções do Repositório ---

@patch("src.backend.get_flowhub_task_status.get_status_repositories.boto3")
def test_save_flowhub_task_status_simplified(mock_boto3):
    """Testa a nova versão simplificada da função save_flowhub_task_status."""
    # ARRANGE
    mock_dynamodb_resource = MagicMock()
    mock_table = MagicMock()
    mock_boto3.resource.return_value = mock_dynamodb_resource
    mock_dynamodb_resource.Table.return_value = mock_table

    # ACT
    # Chamamos a função com a nova assinatura correta (apenas 2 argumentos)
    save_flowhub_task_status(
        task_identifier="task-id-123",
        dms_status="running"
    )

    # ASSERT
    # Verificamos se a função 'update_item' foi chamada na tabela mockada
    mock_table.update_item.assert_called_once()
    # E podemos verificar se os argumentos corretos foram passados
    call_args, call_kwargs = mock_table.update_item.call_args
    assert call_kwargs['Key'] == {"task_identifier": "task-id-123"}
    assert call_kwargs['ExpressionAttributeValues'][':dms'] == "running"
    # Note que não há mais verificação de dados da SFN aqui


@patch("src.backend.get_flowhub_task_status.get_status_repositories.boto3")
def test_get_step_function_status_complete_from_dynamo(mock_boto3):
    # ARRANGE
    mock_dynamodb_resource = MagicMock()
    mock_table = MagicMock()
    mock_boto3.resource.return_value = mock_dynamodb_resource
    mock_dynamodb_resource.Table.return_value = mock_table

    mock_table.get_item.return_value = {
        "Item": {
            "sfn_status": "SUCCEEDED",
            "sfn_execution_arn": "arn:aws:states:stepfunction:execution:recovery-123",
            "updated_by": "lambda",
        }
    }

    # ACT
    result = get_step_function_status_complete_from_dynamo("task1")

    # ASSERT
    assert result["status"] == "SUCCEEDED"
    assert result["sfn_execution_arn"] == "arn:aws:states:stepfunction:execution:recovery-123"


# --- Testes do Lambda Handler ---

@patch("src.backend.get_flowhub_task_status.get_flowhub_task_status.get_all_replication_tasks")
def test_lambda_handler_dms_client_failure(mock_get_tasks):
    # ARRANGE
    mock_get_tasks.side_effect = Exception("Erro inesperado no DMS")
    event = {"body": json.dumps({"action": "listar_status"})}

    # ACT
    response = lambda_handler(event, None)

    # ASSERT
    assert response["statusCode"] == 500
    assert "Erro inesperado no DMS" in json.loads(response["body"])["error"]
