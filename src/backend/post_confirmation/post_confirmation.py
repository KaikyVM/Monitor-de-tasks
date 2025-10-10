import boto3
import logging

# Configura o logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Adiciona todo novo usuário confirmado ao grupo padrão 'Usuarios'.
    """
    user_pool_id = event['userPoolId']
    user_name = event['userName']
    default_group_name = "Usuarios"

    try:
        # Inicializa o cliente BOTO3 DENTRO da função.
        # Isso garante que ele será mockado corretamente pelos testes.
        cognito_client = boto3.client('cognito-idp')
        
        logger.info(f"Adicionando usuário {user_name} ao grupo padrão '{default_group_name}'")
        
        cognito_client.admin_add_user_to_group(
            UserPoolId=user_pool_id,
            Username=user_name,
            GroupName=default_group_name,
        )
        logger.info("Usuário adicionado ao grupo padrão com sucesso.")

    except Exception as e:
        logger.error(f"Erro ao adicionar usuário ao grupo padrão: {e}")

    # O Cognito espera que o evento original seja retornado
    return event
