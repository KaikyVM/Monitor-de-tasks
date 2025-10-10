# Documentação da Aplicação de Gerenciamento de Tasks

## 1. Visão Geral do Projeto

**Objetivo:**  
Esta aplicação tem como finalidade gerenciar tasks de forma simples e intuitiva. Ela permite que o usuário visualize o status das tasks, teste a conexão com os endpoints envolvidos, inicie fluxos de execução (Step Functions) e reinicie tasks quando necessário. Além disso, a aplicação foi desenvolvida com foco em performance, usabilidade e segurança, utilizando diversos serviços da AWS para garantir escalabilidade e robustez.

---

## 2. Arquitetura da Aplicação

### 2.1 Tecnologias Utilizadas

- **Amazon Cognito:** Gerencia a autenticação e autorização dos usuários.  
- **AWS Lambda:** Responsável pelo backend, onde a lógica de negócio é implementada (início e monitoramento de Step Functions, comunicação com o banco de dados, etc).  
- **AWS Step Functions:** Orquestra os fluxos de execução dos processos relacionados às tasks.  
- **Amazon DynamoDB:** Banco de dados NoSQL utilizado para armazenar os registros e o status das tasks.  
- **React:** Framework utilizado para o desenvolvimento da interface do usuário (front-end).  
- **AWS Amplify:** Ferramenta que realiza o deploy e integra os serviços da AWS com a aplicação front-end.
- **React OIDC Context:** Biblioteca utilizada para integração com Amazon Cognito para autenticação.

### 2.2 Diagrama de Arquitetura

**Descrição:**  
1. **Usuário:** Interage com a interface via navegador.  
2. **Front-End (React):** Apresenta a dashboard das tasks, permite ações como teste de conexão e reinício de tasks.  
3. **API (Lambda):** Recebe requisições do front-end, processa as ações solicitadas e comunica-se com o DynamoDB e o Step Functions para gerenciamento dos processos.  
4. **DynamoDB:** Armazena os registros das tasks e seus status atualizados.  
5. **Step Functions:** Gerencia o fluxo de execução para as tasks, permitindo a orquestração de processos complexos.

---

## 3. Estrutura do Front-End

### 3.1 Componentes Principais

A aplicação foi estruturada de forma modular, utilizando diversos componentes React para melhor manutenção e reutilização de código:

- **DashBoard:** Componente principal que gerencia o estado e orquestra outros componentes.
- **TaskStatusModal:** Exibe mensagens durante o teste de conexão.
- **ConfirmationModal:** Solicita confirmação e nome de usuário para reiniciar uma task.
- **TaskListHeader:** Renderiza o cabeçalho da lista de tasks.
- **TaskRow:** Renderiza uma linha da tabela de tasks com suas ações.
- **Pagination:** Gerencia a paginação da lista de tasks.
- **SearchAndUpdateControls:** Controla a busca, atualização de dados e mudança de tema.

### 3.2 Serviços e APIs

A comunicação com o backend é realizada através de um módulo de serviços isolado (`services/api.js`), que contém funções para:

- `fetchTasks`: Recupera a lista de tasks.
- `fetchStepFunctionStatus`: Consulta o status da Step Function de uma task.
- `getTaskDetails`: Obtém detalhes específicos de uma task.
- `startConnectionTest`: Inicia um teste de conexão.
- `checkConnectionTest`: Verifica o status do teste de conexão.
- `invokeStepFunction`: Inicia uma execução de Step Function para reiniciar uma task.
- `checkStepFunctionExecution`: Monitora o status de uma execução de Step Function.

---

## 4. Fluxo da Aplicação

### 4.1 Fluxo de Execução (Back-End)

1. **Recepção de Requisição:**  
   - A função Lambda (`lambda_handler`) recebe o evento enviado pelo front-end.
   - O corpo do evento é decodificado para identificar a ação (por exemplo, `get_last_status`, iniciar Step Function, etc).

2. **Verificação e Execução:**  
   - Se a ação for **get_last_status**, a função consulta o DynamoDB para retornar o último status da task.
   - Se for uma requisição para iniciar uma Step Function, a função `start_step_function` é acionada, que:
     - Prepara o payload com informações da task.
     - Inicia a execução da Step Function usando um nome único (gerado com data e UUID).
     - Registra o status "running" no DynamoDB.

3. **Monitoramento:**  
   - Caso a requisição contenha um `executionArn`, a função `check_step_function_status` é chamada para consultar o status atual da execução e atualizá-lo no DynamoDB.

4. **Resposta para o Front-End:**  
   - Após processar a requisição, a função Lambda retorna um JSON com o status ou detalhes da execução para o front-end atualizar a interface.

### 4.2 Fluxo de Execução (Front-End)

1. **Autenticação e Inicialização:**
   - O usuário é autenticado via Amazon Cognito usando `react-oidc-context`.
   - Após autenticação bem-sucedida, o componente **DashBoard** é renderizado.
   - O método `fetchTasksHandler` é invocado para buscar as tasks do backend.

2. **Carregamento e Apresentação dos Dados:**  
   - Durante o carregamento, um spinner é exibido para feedback visual.
   - Em caso de erro, uma mensagem é mostrada com opção para tentar novamente.
   - A dashboard exibe uma lista paginada de tasks com informações como: identificador, status, status da conexão e da Step Function.
   - Recursos de pesquisa permitem filtrar tasks pelo identificador.

3. **Ações do Usuário:**  
   - **Trocar Tema:** O usuário pode alternar entre tema claro e escuro, com preferência salva no localStorage.
   - **Pesquisar Tasks:** Filtragem em tempo real das tasks exibidas.
   - **Paginação:** Navegação entre várias páginas de tasks.
   - **Testar Conexão:** Ao clicar, a função `testConnection` é acionada, que:
     - Exibe um modal informando o início do teste.
     - Requisita os detalhes da task e aciona o endpoint para teste.
     - Faz múltiplas tentativas com intervalo de 10 segundos (máximo 30 tentativas).
     - Atualiza a interface com o status retornado (ex: "Conexão (OK)" ou "Conexão (Falha)").
   - **Reiniciar Task:** Ao acionar o botão de reinício:
     - Um modal de confirmação é exibido solicitando o nome do usuário.
     - Após confirmação, `invokeStepFunction` inicia uma nova execução da Step Function.
     - O status da task é atualizado na interface.
   - **Logout:** Ao clicar na imagem de perfil, o usuário pode fazer logout da aplicação.

4. **Atualização Periódica:**  
   - Um `setInterval` é utilizado para atualizar o status da Step Function a cada 5 segundos, garantindo que a dashboard exiba informações sempre atualizadas.

---

## 5. Lógica de Habilitação e Desabilitação dos Botões

A interface foi desenhada para que os botões de **teste de conexão** e **restart** fiquem habilitados ou desabilitados de acordo com o status atual da task, evitando ações redundantes ou inválidas:

- **Botão de Teste de Conexão:**
  - **Habilitado:** Quando o status da task é "failed" ou "stopped", permitindo que o usuário inicie um novo teste.
  - **Desabilitado:** Se a task estiver em estado "running" ou se o teste estiver em andamento.

- **Botão de Restart:**
  - **Habilitado:** Em condições onde a task falhou e é possível reiniciá-la, ou quando o teste de conexão foi bem-sucedido, mas a task necessita de reinicialização. Também é habilitado quando o status da Step Function é "success" ou "failed".
  - **Desabilitado:** Se a Step Function estiver executando ("running" ou "executando") ou se o status atual não permitir reinício.

As classes CSS (`btn-gray`, `btn-green`, `btn-red`) aplicadas dinamicamente ao botão de conexão ajudam a indicar visualmente o status:
- **btn-green:** Conexão OK.  
- **btn-red:** Conexão com Falha.  
- **btn-gray:** Estado neutro ou aguardando ação.

---

## 6. Estilização e Interface do Usuário

### 6.1 Temas

A aplicação suporta dois temas:
- **Tema Claro:** Modo padrão da aplicação.
- **Tema Escuro (Dark Mode):** Ativado pelo botão na interface ou pela preferência salva no localStorage.

### 6.2 Elementos de UI Responsivos

- **Loading Spinner:** Exibido durante operações de carregamento.
- **Mensagens de Erro:** Feedback visual em caso de falhas.
- **Modais de Confirmação e Status:** Fornecem feedback durante operações.
- **Indicadores Visuais de Status:** Utiliza cores e gradientes para indicar diferentes estados das tasks:
  - Verde escuro: Task completa (running com 100% de progresso)
  - Verde claro: Task em execução (running)
  - Vermelho: Task falhou (failed)
  - Cinza: Task parada ou pronta (stopped/ready)

### 6.3 Recursos de Usabilidade

- **Pesquisa:** Permite filtrar tasks rapidamente por identificador.
- **Paginação Inteligente:** Adapta-se à quantidade de tasks e mantém consistência entre filtros.
- **Atualizações Automáticas:** Verifica status a cada 5 segundos sem necessidade de atualização manual.
- **Feedback Visual:** Cores, botões e estilos indicam claramente os estados e ações disponíveis.

---

## 7. Autenticação e Segurança

### 7.1 Fluxo de Autenticação

- **Login:** Utiliza Amazon Cognito via `react-oidc-context` para autenticação segura.
- **Sessão:** O token de autenticação é gerenciado pelo contexto de auth.
- **Logout:** Implementado através do método `signoutRedirect` do contexto de autenticação.

### 7.2 Segurança

- **Validação de Entradas:** O sistema valida entradas antes de enviar ao backend.
- **Tratamento de Erros:** Mensagens de erro são exibidas de forma amigável, sem expor detalhes sensíveis.
- **Autorização:** As ações sensíveis como reinício de tasks requerem identificação do usuário.

---

## 8. Tratamento de Erros e Resiliência

### 8.1 Estratégias de Tratamento de Erro

- **Erros de API:** Capturados e exibidos com opção de retry.
- **Timeouts:** Implementados para operações de longa duração como testes de conexão.
- **Erros de Processamento:** Feedback visual claro quando operações falham.

### 8.2 Resiliência

- **Tentativas Múltiplas:** Para testes de conexão, o sistema faz até 30 tentativas com intervalo de 10 segundos.
- **Estado Consistente:** Atualização seletiva do estado para evitar perda de informações.
- **Cache de Referência:** Utiliza `useRef` para manter referências estáveis entre renderizações.

---

## 9. Considerações para Desenvolvimento Futuro

- **Exportação de Dados:** Implementar funcionalidade para exportar informações de tasks.
- **Filtragem Avançada:** Adicionar filtros por status, data, etc.
- **Histórico de Ações:** Registrar histórico de interações e alterações de status.
- **Notificações:** Implementar sistema de alertas para mudanças críticas de status.
- **Responsividade Mobile:** Melhorar adaptação para dispositivos móveis.