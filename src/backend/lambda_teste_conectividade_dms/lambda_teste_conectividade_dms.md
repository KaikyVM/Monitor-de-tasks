
````markdown
# lambda_teste_conectividade_dms

Essa AWS Lambda tem como objetivo **iniciar e verificar testes de conectividade** entre uma instância de replicação e um endpoint no serviço **AWS DMS (Database Migration Service)**.

## 🔧 Funcionalidade

A Lambda é acionada por uma requisição HTTP via API Gateway, recebendo um JSON no corpo da requisição com os seguintes parâmetros:

### Parâmetros obrigatórios:

| Parâmetro                | Tipo   | Descrição                                                                 |
|--------------------------|--------|---------------------------------------------------------------------------|
| `action`                 | string | `"start-test"` para iniciar ou `"check-test"` para verificar o status    |
| `ReplicationInstanceArn` ou `task_arn` | string | ARN da instância de replicação usada no DMS                              |
| `endpoint_arn`           | string | ARN do endpoint de origem ou destino no DMS                               |

> ✅ **Importante**: a Lambda aceita **dois nomes diferentes** para o parâmetro da instância de replicação:
>
> - `ReplicationInstanceArn` — **forma correta e recomendada**
> - `task_arn` — forma antiga usada pelo sistema legado (mantida por compatibilidade)

---

## ✅ Compatibilidade Retroativa

Antes desta atualização, a Lambda aceitava apenas o parâmetro `task_arn`, o que **violava o padrão de nomenclatura da AWS** e causava confusão com o que realmente representa o valor (`ReplicationInstanceArn` do DMS).

### O que foi corrigido:

- O código agora verifica **ambos os parâmetros** (`ReplicationInstanceArn` ou `task_arn`), o que permite que o **frontend atual continue funcionando** normalmente, **sem precisar de mudanças imediatas**.
- A partir de agora, sistemas novos devem preferir o uso de `ReplicationInstanceArn`.

---

## 📤 Exemplo de chamada (start-test)

```json
{
  "action": "start-test",
  "ReplicationInstanceArn": "arn:aws:dms:us-east-1:123456789012:rep:ABCDEFGHIJKL",
  "endpoint_arn": "arn:aws:dms:us-east-1:123456789012:endpoint:MNOPQRSTUVWX"
}
````

Ou, para compatibilidade com sistemas antigos:

```json
{
  "action": "start-test",
  "task_arn": "arn:aws:dms:us-east-1:123456789012:rep:ABCDEFGHIJKL",
  "endpoint_arn": "arn:aws:dms:us-east-1:123456789012:endpoint:MNOPQRSTUVWX"
}
```

---

## 📥 Exemplo de chamada (check-test)

```json
{
  "action": "start-test",
  "ReplicationInstanceArn": "arn:aws:dms:sa-east-1:038503386091:rep:377VM7ZJCZGOVHSWX4AYEYKXL4",
  "endpoint_arn": "arn:aws:dms:sa-east-1:038503386091:endpoint:QGQZPDYLOJC7HMEGP4KKNEBKTU"
}
---
depois
---
{
  "action": "check-test",
  "ReplicationInstanceArn": "arn:aws:dms:sa-east-1:038503386091:rep:377VM7ZJCZGOVHSWX4AYEYKXL4",
  "endpoint_arn": "arn:aws:dms:sa-east-1:038503386091:endpoint:QGQZPDYLOJC7HMEGP4KKNEBKTU"
}
```

---

## 🔄 Retorno esperado

### Sucesso

```json
{
  "message": "Teste iniciado com sucesso",
  "status": "testing"
}
```

e

```json
{
  "message": "Status verificado",
  "status": "successful"
}
```

### Erro de parâmetros

```json
{
  "error": "Parâmetros 'action', 'ReplicationInstanceArn' (ou 'task_arn') e 'endpoint_arn' são obrigatórios"
}
```

---

## 📎 Observações finais

* Essa Lambda é gerenciada por **Terraform**, e faz uso do cliente `boto3` para interações com o AWS DMS.
* Requisições CORS estão liberadas com `Access-Control-Allow-Origin: *`, permitindo integração com frontends externos.

---

## 📁 Estrutura do Projeto

```
lambda_teste_conectividade_dms/
├── lambda_teste_conectividade_dms.py
├── README.md
└── (arquivos Terraform separados em main.tf, lambda.tf, api_gateway.tf)
```