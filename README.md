[![Quality Gate Status](https://prd.sonar.e-dor.net/api/project_badges/measure?project=flowhub-view&metric=alert_status&token=sqb_520c559f55c1d7c20865e7dd5e510f59c0d9edb4)](https://prd.sonar.e-dor.net/dashboard?id=flowhub-view)
[![Duplicated Lines (%)](https://prd.sonar.e-dor.net/api/project_badges/measure?project=flowhub-view&metric=duplicated_lines_density&token=sqb_520c559f55c1d7c20865e7dd5e510f59c0d9edb4)](https://prd.sonar.e-dor.net/dashboard?id=flowhub-view)
[![Lines of Code](https://prd.sonar.e-dor.net/api/project_badges/measure?project=flowhub-view&metric=ncloc&token=sqb_520c559f55c1d7c20865e7dd5e510f59c0d9edb4)](https://prd.sonar.e-dor.net/dashboard?id=flowhub-view)
[![Security Hotspots](https://prd.sonar.e-dor.net/api/project_badges/measure?project=flowhub-view&metric=security_hotspots&token=sqb_520c559f55c1d7c20865e7dd5e510f59c0d9edb4)](https://prd.sonar.e-dor.net/dashboard?id=flowhub-view)

# Flowhub View

## Sobre o Projeto

O Flowhub View é uma aplicação de monitoramento para as tarefas de replicação do AWS DMS, permitindo que os times de Engenharia e N1 reiniciem e validem o status das tasks de forma segura e controlada.

## Tecnologias Utilizadas

- **Frontend:** React, Vite, react-oidc-context
- **Backend:** Python, AWS Lambda, API Gateway
- **Banco de Dados:** Amazon DynamoDB
- **Autenticação:** Amazon Cognito
- **CI/CD:** Azure DevOps, SonarQube

## Como rodar o projeto


## Pipeline
| Ação                                      | Resultado                                     |
| ----------------------------------------- | --------------------------------------------- |
| Push com `#dev` no commit                 | Deploy em `dev`                               |
| Push com `#hml` no commit                 | Deploy em `hml`                               |
| Push com `#prd` no commit                 | Deploy em `prd`                               |
| Execução manual com `environment` marcado | Ignora o commit, usa o parâmetro              |
| PR para `main` ou `develop`               | **Roda apenas testes e análise (sem deploy)** |
# Monitor-de-tasks
# Monitor-de-tasks
