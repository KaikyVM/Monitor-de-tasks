import pytest
# Importamos a função que queremos testar
from src.backend.pre_signup.pre_signup import lambda_handler

def test_handler_with_allowed_domain():
    """
    Testa se o cadastro é PERMITIDO quando o e-mail tem o domínio correto.
    """
    # 1. Prepara um evento de teste simulando um e-mail válido
    test_event = {
        'request': {
            'userAttributes': {
                'email': 'kaiky.barbosa@rededor.com.br'
            }
        }
    }

    # 2. Executa a função
    response = lambda_handler(test_event, None)

    # 3. Verifica o resultado: a função deve retornar o mesmo evento, sem erros.
    assert response == test_event

def test_handler_with_disallowed_domain():
    """
    Testa se o cadastro é BLOQUEADO quando o e-mail tem um domínio inválido.
    """
    # 1. Prepara um evento de teste simulando um e-mail inválido
    test_event = {
        'request': {
            'userAttributes': {
                'email': 'impostor@gmail.com'
            }
        }
    }

    # 2. Executa a função e verifica se ela lança uma exceção
    with pytest.raises(Exception) as excinfo:
        lambda_handler(test_event, None)

    # 3. Verifica o resultado: a mensagem de erro da exceção deve conter o texto esperado.
    assert "permitido apenas para e-mails do domínio @rededor.com.br" in str(excinfo.value)

def test_handler_with_malformed_email():
    """
    Testa o comportamento com um e-mail que não corresponde ao padrão esperado.
    """
    test_event = {
        'request': {
            'userAttributes': {
                'email': 'nao_e_um_email'
            }
        }
    }
    with pytest.raises(Exception):
        lambda_handler(test_event, None)