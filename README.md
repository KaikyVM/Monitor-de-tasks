
# Flowhub View

Aplicação para monitorar tarefas de replicação do AWS DMS, permitindo consultar o estado das tasks, testar conectividade e executar recuperações de forma controlada.

## Estrutura

```
src/
  frontend/    # Interface React/Vite
  backend/     # Lambdas e lógica de integração AWS
infra/         # Terraform: módulos, pipelines e ambiente mock
tests/         # Testes automatizados em Python
scripts/       # Utilitários de execução e benchmark
docs/          # Documentação complementar
```

## Tecnologias

- Frontend: React, Vite e Tailwind CSS
- Backend: Python, AWS Lambda e API Gateway
- Dados: Amazon DynamoDB
- Autenticação: Amazon Cognito
- Infraestrutura: Terraform

## Desenvolvimento local

Frontend:

```bash
cd src/frontend
npm install
npm run dev
```

Backend e testes:

```bash
pip install -r requirements.txt
pytest
```

## Segurança

Não versione arquivos `.env`, credenciais AWS, tokens de acesso ou arquivos `*.tfvars` com valores reais. Use variáveis de ambiente e mantenha arquivos locais fora do Git.
