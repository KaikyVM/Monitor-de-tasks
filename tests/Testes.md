## 📁 Estrutura do Projeto

```bash
DMS_task_monitor View/
├── src/
│   └── backend/
│       └── lambda_conectvidade_dms/
│           └── lambda_function.py  # Código principal da Lambda
├── tests/
│   └── lambda_conectvidade_dms_teste/
│       └── lambda_conectividade_dms_test.py  # Testes automatizados com pytest
└── README.md
```

---

## 🧠 Funcionamento da Lambda

A Lambda responde a dois tipos de ação via evento (payload):

* `"action": "start-test"` → Inicia um teste de conectividade
* `"action": "check-test"` → Verifica o status de um teste iniciado

### 📥 Exemplo de Payload

```json
{
  "action": "start-test",
  "task_arn": "arn:aws:dms:task:...",
  "endpoint_arn": "arn:aws:dms:endpoint:..."
}
```

### 📤 Respostas esperadas

```json
{
  "message": "Teste iniciado com sucesso",
  "status": "testing"
}
```

ou

```json
{
  "message": "Status verificado",
  "status": "successful"
}
```

---

## 🧪 Testes Automatizados

Foi utilizado `pytest` para validar o comportamento da Lambda localmente. Os testes são do tipo **unitário**, com uso extensivo do `unittest.mock` para simular respostas da AWS.

Os mocks utilizados foram construídos com base na [documentação oficial do Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/dms.html), garantindo maior realismo nas simulações e mais robustez nos testes automatizados.

> ⚠️ Como o [moto](https://docs.getmoto.org/en/latest/) **não oferece suporte ao AWS DMS**, os testes não utilizam ambiente de simulação, mas ainda assim são confiáveis por conta da fidelidade aos retornos esperados do Boto3.

### ✅ Requisitos

* Python 3.12+
* `pytest` instalado

```bash
pip install pytest
```

### ▶️ Rodando os testes

Execute o comando abaixo na raiz do projeto:

```bash
pytest
```

Você deverá ver algo como:

```
============================= test session starts =============================
platform win32 -- Python 3.12.6, pytest-8.3.5
collected 1 item

tests/lambda_conectvidade_dms_teste/lambda_conectividade_dms_test.py::test_lambda_start_test_success PASSED
```

---

## 🧪 **Como estão sendo feitos os testes**

Esses testes são do tipo **unitário** e utilizam o módulo `unittest.mock` (especificamente o `@patch`) para **simular respostas de funções que fazem chamadas externas para a AWS**, ou seja, **não interagem com a AWS de verdade**.

### Ferramentas principais:

* `pytest`: usado como framework de testes.
* `unittest.mock.patch`: usado para **"substituir" temporariamente funções** da AWS (como `dms_client.test_connection` e `dms_client.describe_connections`) por versões controladas que você define no teste.
* **Base dos mocks**: todas as simulações foram baseadas em exemplos reais da documentação do Boto3, buscando manter os formatos de resposta e exceções o mais próximos possível da realidade.

---

## 🔎 **O que cada teste está testando**

### 1. `test_lambda_check_test_success`

**Contexto do teste**:
Esse teste foca na ação `"check-test"` do seu `lambda_handler`, que consulta o status de uma conexão no DMS.

**Objetivo**:
Verificar se, ao simular que a conexão está `"successful"`, a Lambda retorna corretamente:

* Status HTTP `200`
* E o campo `"status": "successful"` no corpo da resposta.

**Como é feito**:

```python
@patch("...dms_client.describe_connections")
def test_lambda_check_test_success(mock_describe_connections):
    mock_describe_connections.return_value = {
        "Connections": [
            {"EndpointArn": "arn:aws:dms:endpoint", "Status": "successful"}
        ]
    }
    event = {
        "body": json.dumps(
            {
                "action": "check-test",
                "endpoint_arn": "arn:aws:dms:endpoint",
            }
        )
    }
    result = lambda_handler(event, None)
    body = json.loads(result["body"])

    assert result["statusCode"] == 200
    assert body["status"] == "successful"
    assert body["message"] == "Connection successful."
```

---

### 2. `test_lambda_check_test_not_found`

**Contexto do teste**:
Esse teste cobre um caso de borda na ação `"check-test"`, em que nenhuma conexão com o `endpoint_arn` informado é encontrada.

**Objetivo**:
Verificar se a Lambda retorna corretamente:

* Status HTTP `404`
* E a mensagem de erro indicando que a conexão não foi encontrada.

**Como é feito**:

```python
@patch("...dms_client.describe_connections")
def test_lambda_check_test_not_found(mock_describe_connections):
    mock_describe_connections.return_value = {
        "Connections": [
            {"EndpointArn": "arn:aws:dms:endpoint:diferente", "Status": "successful"}
        ]
    }
    event = {
        "body": json.dumps(
            {
                "action": "check-test",
                "endpoint_arn": "arn:aws:dms:endpoint",
            }
        )
    }
    result = lambda_handler(event, None)
    body = json.loads(result["body"])

    assert result["statusCode"] == 404
    assert "error" in body
```

---

### 3. `test_lambda_handler_internal_error`

**Contexto do teste**:
Esse teste foca na ação `"start-test"` do `lambda_handler`, que tenta iniciar um teste de conexão no DMS.

**Objetivo**:
Verificar se, ao simular um erro (exceção) durante o `test_connection()`, a Lambda:

* Retorna status HTTP `500`
* E contém um campo `"error"` no corpo da resposta.

**Como é feito**:

```python
@patch("...dms_client.test_connection")
@patch("...dms_client.describe_connections")
def test_lambda_handler_internal_error(mock_describe_connections, mock_test_connection):
    mock_test_connection.side_effect = Exception("Erro interno do DMS")
    mock_describe_connections.return_value = {
        "Connections": [
            {"EndpointArn": "arn:aws:dms:endpoint", "Status": "successful"}
        ]
    }
    event = {
        "body": json.dumps(
            {
                "action": "start-test",
                "task_arn": "arn:aws:dms:task:...",
                "endpoint_arn": "arn:aws:dms:endpoint",
            }
        )
    }
    result = lambda_handler(event, None)
    body = json.loads(result["body"])

    assert result["statusCode"] == 500
    assert "error" in body
```

---

### 4. `test_lambda_invalid_parameters` (Atualizado)

**Contexto do teste**:
Esse teste verifica o comportamento da Lambda quando os parâmetros esperados no payload estão ausentes ou inválidos — por exemplo, faltando `task_arn`, `endpoint_arn` ou até mesmo a chave `action`.

**Objetivo**:
Garantir que, quando a requisição não contém os parâmetros mínimos necessários, a Lambda:

* Retorna status HTTP `400`
* E inclui uma mensagem clara de erro no corpo da resposta.

**Como é feito**:

```python
def test_lambda_invalid_parameters():
    event = {
        "body": json.dumps(
            {
                "action": "start-test",  # task_arn e endpoint_arn estão faltando
            }
        )
    }
    result = lambda_handler(event, None)
    body = json.loads(result["body"])

    assert result["statusCode"] == 400
    assert body == "Parâmetros 'action', 'ReplicationInstanceArn' (ou 'task_arn') e 'endpoint_arn' são obrigatórios"
```

---

### 5. `test_lambda_check_test_with_replication_instance_arn`

**Contexto do teste**:
Esse teste foca na ação `"check-test"`, mas agora com a inclusão do parâmetro `ReplicationInstanceArn`, substituindo o antigo `task_arn`. A ideia é garantir que a Lambda também valide esse parâmetro adicional.

**Objetivo**:
Verificar se, ao simular que a conexão está `"successful"`, a Lambda retorna corretamente:

* Status HTTP `200`
* E o campo `"status": "successful"` no corpo da resposta.
* Garantir que a mensagem seja consistente com o novo parâmetro.

**Como é feito**:

```python
@patch("...dms_client.describe_connections")
def test_lambda_check_test_with_replication_instance_arn(mock_describe_connections):
    mock_describe_connections.return_value = {
        "Connections": [
            {"EndpointArn": "arn:aws:dms:endpoint", "Status": "successful"}
        ]
    }
    event = {
        "body": json.dumps(
            {
                "action": "check-test",
                "ReplicationInstanceArn": "arn:aws:dms:replication-instance",
                "endpoint_arn": "arn:aws:dms:endpoint",
            }
        )
    }
    result = lambda_handler(event, None)
    body = json.loads(result["body"])

    assert result["statusCode"] == 200
    assert body["status"] == "successful"
    assert body["message"] == "Connection successful."
```
---

### 6. `test_lambda_start_test_with_task_arn`

**Contexto do teste**:
Esse teste foca na ação `"start-test"` do `lambda_handler`, garantindo que a função lide corretamente com a execução do teste de conectividade quando apenas o `task_arn` é fornecido (sem `endpoint_arn` explícito).

**Objetivo**:
Verificar se a Lambda:

* Inicia corretamente o teste de conectividade chamando `start_test_connection` do DMS via o `task_arn`.
* Retorna status HTTP `200`.
* Informa que o teste de conectividade foi iniciado com sucesso.

**Como é feito**:

```python
@patch("src.backend.lambda_teste_conectividade_dms.dms_client.start_test_connection")
@patch("src.backend.lambda_teste_conectividade_dms.dms_client.describe_connections")
def test_lambda_start_test_with_task_arn(mock_describe_connections, mock_start_test_connection):
    mock_describe_connections.return_value = {
        "Connections": [
            {"EndpointArn": "arn:aws:dms:endpoint", "Status": "successful"}
        ]
    }
    mock_start_test_connection.return_value = {}

    event = {
        "body": json.dumps(
            {
                "action": "start-test",
                "task_arn": "arn:aws:dms:task:..."
            }
        )
    }

    result = lambda_handler(event, None)
    body = json.loads(result["body"])

    assert result["statusCode"] == 200
    assert "Teste de conectividade iniciado com sucesso" in body["message"]
```
---

### 7. `test_lambda_with_mocked_task_arn`

**Contexto do teste**:
Esse teste simula a execução da ação `"start-test"` da Lambda, usando um ambiente AWS totalmente mockado com a biblioteca `moto`, que simula o comportamento do AWS DMS. É útil para testar a integração sem depender de recursos reais da AWS.

**Objetivo**:
Garantir que a Lambda consiga iniciar um teste de conectividade de forma correta, a partir de dados válidos, e que retorne:

* Status HTTP `200`
* Uma `message` ou `status` válida no corpo da resposta
* Um ambiente AWS simulado de forma realista com `boto3`

**Como é feito**:

```python
@mock_aws
def test_lambda_with_mocked_task_arn():
    client = boto3.client("dms", region_name="us-east-1")

    # Criação de uma replication task mockada para simular o ambiente AWS
    replication_task = client.create_replication_task(
        ReplicationTaskIdentifier="mock-task",
        SourceEndpointArn="arn:aws:dms:us-east-1:123456789012:endpoint:source",
        TargetEndpointArn="arn:aws:dms:us-east-1:123456789012:endpoint:target",
        ReplicationInstanceArn="arn:aws:dms:us-east-1:123456789012:rep:instance",
        MigrationType="full-load",
        TableMappings="{}",
        ReplicationTaskSettings="{}",
    )

    # Simula o evento enviado via API Gateway para a Lambda
    event = {
        "body": json.dumps({
            "action": "start-test",
            "replicationInstanceArn": "arn:aws:dms:us-east-1:123456789012:rep:instance",
            "endpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:source"
        }),
        "isBase64Encoded": False
    }

    # Executa a Lambda com os dados simulados
    response = lambda_handler(event, None)
    body = json.loads(response["body"])

    # Verificações de sucesso
    assert response["statusCode"] == 200
    assert "status" in body or "message" in body
```

---
