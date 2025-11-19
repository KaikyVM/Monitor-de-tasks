import pytest
import boto3
from moto import mock_aws
import os

# Importe a função handler da sua Lambda.
from src.backend.post_confirmation.post_confirmation import lambda_handler

@pytest.fixture(scope="function")
def aws_credentials():
    """Garante que credenciais FALSAS sejam usadas, protegendo sua conta real."""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "sa-east-1"

@pytest.fixture(scope="function")
def cognito_setup(aws_credentials):
    """
    Configura um ambiente Cognito mockado. Cria o User Pool e o grupo 'Usuarios'.
    """
    with mock_aws():
        client = boto3.client("cognito-idp", region_name="sa-east-1")
        
        # 1. Criar um User Pool mockado
        response_pool = client.create_user_pool(PoolName="DMS_task_monitor_test_pool")
        user_pool_id = response_pool['UserPool']['Id']
        
        # 2. Criar o grupo padrão que a Lambda espera que exista
        client.create_group(GroupName="Usuarios", UserPoolId=user_pool_id)
            
        yield client, user_pool_id

def create_mock_cognito_event(user_pool_id, username, email):
    """Função helper para criar o objeto de evento do Cognito."""
    return {
        'userPoolId': user_pool_id,
        'userName': username,
        'request': {
            'userAttributes': {
                'email': email,
                'sub': f'uuid-for-{username}'
            }
        }
    }

def test_new_user_is_added_to_default_group(cognito_setup):
    """
    Cenário: Verifica se um novo usuário, independentemente do e-mail,
    é adicionado corretamente ao grupo padrão 'Usuarios'.
    """
    # ARRANGE: Preparar o ambiente do teste
    cognito_client, user_pool_id = cognito_setup
    username = "qualquer-usuario"
    email = "kaiky.barbosa@rededor.com.br"
    
    cognito_client.admin_create_user(UserPoolId=user_pool_id, Username=username)
    event = create_mock_cognito_event(user_pool_id, username, email)
    
    # ACT: Executar a função lambda
    lambda_handler(event, {})
    
    # ASSERT: Verificar o estado do serviço mockado
    response = cognito_client.admin_list_groups_for_user(Username=username, UserPoolId=user_pool_id)
    
    # Verifica se o usuário está em exatamente um grupo
    assert len(response['Groups']) == 1 
    # Verifica se o nome do grupo é 'Usuarios'
    assert response['Groups'][0]['GroupName'] == 'Usuarios'

#pip install joserfc
# pip install -r requirements.txt
