import os
import logging

# Configuração do logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

class SignUpError(Exception):
    """Exceção customizada para erros de validação no pré-cadastro do Cognito."""
    pass

def lambda_handler(event, context):
    """
    Valida se o e-mail do usuário pertence a um domínio permitido antes de
    permitir o cadastro no Cognito.
    """
    # Domínio permitido
    allowed_domain = os.environ.get('ALLOWED_DOMAIN', '@rededor.com.br')

    try:
        # Obtém o e-mail do evento enviado pelo Cognito
        user_email = event['request']['userAttributes']['email']

        logger.info(f"Verificando o e-mail: {user_email}")

        # Verifica se o e-mail termina com o domínio permitido (ignorando maiúsculas/minúsculas)
        if user_email and user_email.lower().endswith(allowed_domain.lower()):
            logger.info("Domínio permitido. Continuando o cadastro.")
            # Se o domínio for permitido, retorna o evento para o Cognito continuar
            return event
        else:
            logger.warning("Domínio não permitido. Bloqueando o cadastro.")
            # Lança a exceção específica com a mensagem de erro para o usuário
            raise SignUpError(f"Cadastro permitido apenas para e-mails do domínio {allowed_domain}.")

    except KeyError:
        # acontece se o evento do Cognito não tiver a estrutura esperada
        logger.error("Estrutura do evento inválida. A chave 'email' não foi encontrada.")
        # Lança a exceção específica com uma mensagem amigável
        raise SignUpError("Ocorreu um erro ao processar seu cadastro. Contate o suporte.")
        
    except Exception as e:
        # Captura qualquer outro erro inesperado, registra e relança
        logger.error(f"Ocorreu um erro inesperado: {str(e)}")
        # Relança a exceção original para que o Cognito bloqueie o cadastro
        # e o erro completo apareça nos logs para depuração.
        raise e