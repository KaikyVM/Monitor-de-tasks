# Guia de redação — artigo RECIMA21

## Recorte e tese

**Recorte.** O estudo de caso é o DMS-Task-Monitor, uma ferramenta operacional de uso intermitente para consultar o estado de tarefas do AWS Database Migration Service (DMS), apoiar testes de conectividade e disparar um fluxo de recuperação autorizado. O artigo compara FaaS e IaaS por medições controladas e analisa CaaS documentalmente. Ele não compara, de forma experimental, a latência do Amazon EKS.

**Tese que os dados permitem defender.** Para o fluxo e as configurações avaliadas, a AWS Lambda evita custo de computação ociosa e reduz a infraestrutura a administrar; a EC2 entrega menor tempo no núcleo de processamento medido, mas pressupõe uma instância provisionada. O EKS acrescenta um plano de controle e uma camada de orquestração cuja relação custo-benefício deve ser avaliada no contexto de uma carga pequena e intermitente, e não por suposta inferioridade geral do Kubernetes.

Evitar três generalizações: (a) “EC2 é 9,01 vezes mais rápida que Lambda”; (b) “a amostra mede cold start”; (c) “EKS é inviável”. As formas corretas são, respectivamente, “nas implementações avaliadas”, “tempo interno do fluxo medido” e “menos adequado ao cenário-base adotado, salvo cluster já existente e custos compartilhados”.

## Pergunta, objetivos e respostas esperadas

**Pergunta central.** Quais trade-offs de desempenho, custo e esforço operacional surgem ao hospedar uma ferramenta operacional de baixo volume em FaaS, IaaS e CaaS?

**RQ1 — desempenho.** Como os paradigmas influenciam o tempo de execução do fluxo de consulta e atualização em lote? A resposta deve apresentar as médias, desvios-padrão e condições do benchmark FaaS/EC2; EKS fica explicitamente fora da comparação empírica de latência.

**RQ2 — custo.** Como variam os custos mensais no cenário de uso intermitente definido? A resposta deve sair de um modelo de custos comum aos três paradigmas, com tarifas e data de consulta declaradas.

**RQ3 — operação.** Quais implicações de manutenção, controle de runtime, disponibilidade e recuperação operacional resultam da escolha? A resposta combina evidência do caso, documentação AWS e as limitações declaradas.

**Objetivo geral.** Avaliar os trade-offs de desempenho, custo e esforço operacional entre FaaS, IaaS e CaaS para hospedar uma ferramenta operacional de uso intermitente, tendo o DMS-Task-Monitor como estudo de caso.

**Objetivos específicos.** (i) caracterizar a arquitetura e o fluxo operacional do estudo de caso; (ii) medir o tempo de execução do núcleo de consulta em lote e atualização de status em Lambda e EC2; (iii) modelar o custo mensal dos três cenários; (iv) comparar os requisitos operacionais com evidências documentais; e (v) descrever a mudança no processo de recuperação, distinguindo tempo humano de tempo técnico.

## Estrutura e conteúdo a redigir

### 1. Introdução

Escreva cinco parágrafos curtos.

1. Apresente a necessidade de ferramentas operacionais para processos de migração e replicação de dados. Mostre que essas ferramentas não são necessariamente o produto principal e podem ter acesso pouco frequente.
2. Defina o problema arquitetural: custo ocioso, tempo de resposta e trabalho de operação não crescem da mesma forma em FaaS, IaaS e CaaS.
3. Apresente o caso sem citar empresa, conta AWS, repositório privado ou usuários: a ferramenta centraliza consulta de status, teste de conectividade e disparo controlado de recuperação de tarefas DMS.
4. Declare objetivo geral, objetivos específicos e as três RQs. Não responda às RQs na introdução.
5. Delimite: Lambda e EC2 possuem ensaio empírico; EKS tem análise documental. Antecipe que os resultados valem para a configuração e carga do caso.

### 2. Fundamentação teórica e trabalhos relacionados

**2.1 Computação em nuvem.** Use NIST para características essenciais e modelos de serviço. Não transforme esta subseção em tutorial de AWS.

**2.2 FaaS, IaaS e CaaS.** Para cada paradigma, explique somente os mecanismos que entrarão na comparação:

- FaaS: execução sob demanda, cobrança por invocação/duração, limites de runtime e inicialização. Use documentação AWS para fatos de produto.
- IaaS: VM, responsabilidade por sistema operacional, atualizações e disponibilidade; custo de capacidade provisionada.
- CaaS/EKS: plano de controle Kubernetes, workloads em pods e computação dos nós EC2 ou Fargate. Esclareça que EKS não elimina o custo dos workloads.

**2.3 Trabalhos relacionados.** Use o texto abaixo como esqueleto, adaptando ao que for efetivamente citado:

> Estudos de avaliação de FaaS mostram que resultados de desempenho dependem do benchmark, da configuração e dos serviços externos usados pela função. Scheuner e Leitner (2020) revisaram 112 estudos e apontaram limitações de reprodutibilidade, além da predominância de microbenchmarks e da avaliação de sobrecarga da plataforma. Esse panorama fundamenta a necessidade de declarar ambiente, carga, instrumento de medição e limites de comparabilidade no presente estudo.
>
> Allen et al. (2024) comparam uma aplicação em contêineres sobre EC2 e uma alternativa em AWS Lambda, considerando custo e desempenho. A pesquisa é pertinente por tratar da decisão EC2–Lambda, mas emprega uma aplicação de microserviços e perfil de carga distintos. O presente estudo aplica a discussão a uma ferramenta operacional intermitente e mede o núcleo de operações DynamoDB de seu caso de uso.
>
> Para o ecossistema baseado em Kubernetes, Decker, Kasprzak e Kunkel (2022) avaliam plataformas serverless auto-hospedadas sobre Kubernetes. Embora o contexto seja de HPC e não seja diretamente transferível ao caso DMS, o trabalho ajuda a situar que desempenho e esforço dependem da plataforma e da configuração do cluster. Assim, este artigo não usa essa literatura para afirmar desempenho do EKS, mas para delimitar sua análise documental.

Não alegue “poucos estudos existem” sem uma revisão sistemática própria. Prefira: “a literatura encontrada aborda principalmente benchmarks de plataforma, microserviços, cargas concorrentes ou clusters auto-hospedados; este trabalho examina um estudo de caso de ferramenta operacional intermitente”.

### 3. Metodologia

**3.1 Caracterização.** Descreva um estudo de caso quantitativo com componente documental. Cite Runeson e Höst (2009) para estudo de caso em engenharia de software e Wohlin et al. (2012) para a apresentação experimental.

**3.2 Estudo de caso.** Registre a arquitetura: frontend React; API Gateway; Lambdas Python; DynamoDB; Cognito; Step Functions; EventBridge; infraestrutura descrita em Terraform. Descreva o fluxo em termos verificáveis: usuário autorizado consulta tarefas, testa conectividade quando aplicável e solicita uma recuperação; o backend inicia a Step Function, registra o status no DynamoDB e recebe atualização final via EventBridge. Não especifique estados internos da Step Function original até ela ser conferida.

**3.3 Benchmark FaaS e IaaS.** Declare em tabela:

| Item | FaaS | IaaS |
|---|---|---|
| Plataforma | AWS Lambda | EC2 t3.micro |
| Região | us-east-1 | us-east-1 |
| Runtime | Python 3.12 | Python 3.12.9 |
| SDK | boto3/botocore 1.42.97 | boto3/botocore 1.42.97 |
| Dados | 42 tarefas mock | 42 tarefas mock |
| Amostra | 30 execuções | 30 execuções |
| Métrica | tempo interno do fluxo | tempo interno do fluxo |

Descreva que ambos realizam leitura em lote no DynamoDB e atualizações individuais de status. Depois declare a limitação: a réplica EC2 não é o mesmo handler da Lambda; ela não monta a resposta HTTP completa e a Lambda cria o recurso DynamoDB na etapa de leitura. Portanto, a comparação representa implementações funcionalmente equivalentes do núcleo de operações, e não uma comparação ponta a ponta de artefato idêntico.

O cronômetro da Lambda começa dentro do handler. Logo, a métrica não inclui toda a inicialização da função nem a rede cliente–API Gateway. Não chame os 30 valores de “cold starts”.

**3.4 Métricas e análise.** Defina as variáveis antes de mostrar qualquer resultado: tempo interno do fluxo, em segundos; média, desvio-padrão amostral, mínimo e máximo das 30 execuções; e a razão entre as médias como medida descritiva, sem teste de hipótese. Para custos, defina a tabela de preços a coletar em **[DATA]**, região us-east-1, USD, e se créditos/free tier serão excluídos do cenário-base. Os valores calculados e as estatísticas pertencem à seção 4.

**3.5 Recuperação operacional.** Descreva o protocolo, não os resultados: quais processos são comparados; os marcos que iniciam e encerram a contagem; como cada duração foi obtida; e quais etapas serão classificadas como tempo humano, tempo técnico do serviço de replicação e validação.

A definição real da máquina de estados permite descrever, de forma anonimizada, o seguinte macrofluxo: leitura de parâmetros e validação do estado da tarefa; suspensão do agendamento; limpeza paralela de dados intermediários e filas, acompanhada da desativação de consumidores; verificação cíclica da desativação; reconstrução de estado em paralelo ao reinício da tarefa em modo de recarga; espera de estabilização e consulta periódica do progresso; processamento incremental; validação opcional; e execução síncrona de um fluxo de pós-recuperação. Não publique nomes de recursos, contas, ARNs, regiões corporativas, nomes de filas, tabelas, funções ou parâmetros internos.

O fluxo automatizado não corresponde etapa por etapa ao procedimento manual anteriormente descrito com checkpoint e posição CDC customizada. Consequentemente, a comparação deve explicitar que são duas estratégias de recuperação diferentes. Para calcular MTTR, extraia dos logs os timestamps de início da execução, fim do isolamento, início e fim da recarga, conclusão dos processamentos auxiliares, pós-recuperação e término da execução. A tabela preenchida e a redução calculada pertencem à seção 4.2.

**3.6 CaaS documental.** O cenário-base deve ser reprodutível:

- Região: us-east-1; moeda: USD; data da tarifa: **[DATA]**.
- Aplicação: um serviço ou job de monitoramento com a mesma finalidade do caso, sem pressupor a medição de latência do EKS.
- EKS: plano de controle gerenciado, mais nós EC2 **ou** Fargate. Escolha uma opção; não some ambas.
- Rede, balanceador e armazenamento: inclua apenas quando a arquitetura definida exigir cada item; registre zero/N.A. nos demais casos.
- Mostre dois cenários: **cluster dedicado** e **cluster preexistente compartilhado**. O segundo evita uma recomendação injusta contra Kubernetes quando o plano de controle já é custo afundado.

Equações a preencher com preços oficiais:

```text
C_lambda = N_inv × P_inv + (N_inv × duração_s × memória_GB × P_GB-s) + C_serviços_associados
C_ec2 = horas_mês × P_instância + C_EBS + C_rede + C_serviços_associados
C_eks_dedicado = horas_mês × P_control_plane + C_workers + C_EBS + C_rede + C_balanceador + C_serviços_associados
C_eks_compartilhado = C_workers_incremental + C_serviços_incrementais
```

O custo de Lambda não é automaticamente zero: pode ser zero sob um benefício aplicável, mas a tabela principal deve mostrar o preço de tabela sem créditos e uma nota separada para o free tier. O custo da EC2 não deve ser comparado como se ela fosse desligada e simultaneamente atendesse eventos imprevisíveis; para o cenário disponível sob demanda, use 730 horas/mês e explique a premissa.

### 4. Resultados e discussão

**4.1 Otimização e desempenho.** Aqui entram a tabela ou gráfico com N, média, desvio-padrão, mínimo e máximo. Apresente primeiro a evolução interna do FaaS: 14,0007 s ± 0,4746 s para 2,3249 s ± 0,1684 s após a correção da reinstanciação do recurso AWS SDK, redução de 83,4%. A interpretação é limitada ao código avaliado: o ganho demonstra que o padrão de instanciação afetava essa implementação, não que seja uma propriedade geral do FaaS.

Depois apresente a EC2 normalizada: 0,2579 s ± 0,0151 s. Comente a diferença observada entre as implementações medidas (2,3249/0,2579 = 9,01), mas reapresente a limitação de equivalência. Não use essa razão como afirmação universal entre serviços.

**4.2 Recuperação operacional.** Esta subseção deve apresentar a tabela preenchida, os valores totais e o cálculo da redução. A definição analisada contém uma espera incondicional de 600 segundos antes da primeira verificação de conclusão da recarga, além do tempo dos jobs síncronos e do pós-processamento. Portanto, 7,5 minutos não pode representar o tempo ponta a ponta dessa execução completa. Antes de publicar o MTTR, identifique exatamente o que foi cronometrado — por exemplo, tempo de atuação humana, tempo até o disparo, tempo até o reinício ou tempo total até a conclusão. O ponto forte pode estar na redução de ações manuais e na padronização do processo, mas essas consequências devem ser apoiadas por observação, logs ou descrição verificável, não inferidas somente da topologia da máquina de estados.

| Etapa | Manual | DMS-Task-Monitor | Evidência | Duração |
|---|---|---|---|---|
| Detecção e triagem | [preencher] | [preencher] | [log, cronômetro ou procedimento] | [min] |
| Autorização e disparo | [preencher] | [preencher] | [evidência] | [min] |
| Recuperação no DMS | [preencher] | [preencher] | [evidência] | [min] |
| Validação | [preencher] | [preencher] | [evidência] | [min] |
| Total | [valor] | [valor] | [método] | [min] |

Se 34,5 e 7,5 minutos forem confirmados para uma métrica com os mesmos marcos, relate redução de 78,3% e dê à métrica o nome correspondente. Não a chame de MTTR ponta a ponta se o intervalo terminar antes do encerramento da máquina de estados. Se os tempos vierem de estimativa de procedimento, use “tempo estimado por decomposição de etapas”, não “MTTR experimental replicado”.

**4.3 Custos.** A tabela precisa ter as premissas antes dos números. Inclua invocações por mês, duração usada na estimativa, memória Lambda, horas da EC2, tamanho/forma de execução do worker EKS e itens acessórios. Discuta o ponto de mudança de forma condicional: “para os valores e premissas adotados”, e não como limite geral.

**4.4 Matriz comparativa.** Use a matriz abaixo e cite a origem de cada linha.

| Critério | FaaS | IaaS | CaaS/EKS | Base da afirmação |
|---|---|---|---|---|
| Tempo do núcleo medido | 2,3249 s ± 0,1684 s | 0,2579 s ± 0,0151 s | não medido | experimento |
| Custo de computação ociosa | sem execução, sem duração faturada | instância disponível no cenário-base | plano de controle e/ou workers conforme cenário | modelo de custos AWS |
| Controle de runtime | limitado às opções do serviço | sistema e processos controlados pelo usuário | imagem, pods e configuração do cluster | documentação AWS |
| Trabalho operacional | gerenciamento de infraestrutura delegado | SO, atualizações e capacidade | configuração/orquestração do cluster e workloads | documentação AWS + escopo |
| Limite do achado | handler e carga específicos | instância específica | sem benchmark empírico | metodologia |

**4.5 Guia de decisão.** Escreva decisões condicionais:

- FaaS: adequado quando a baixa ociosidade e a menor administração são prioritárias e o tempo observado atende ao requisito da ferramenta.
- EC2: adequado quando o serviço permanece ativo, há requisito de runtime/controle ou a latência do núcleo é determinante.
- EKS: pode ser adequado quando já existe cluster compartilhado, há múltiplos workloads conteinerizados ou necessidades de orquestração não atendidas pelos outros cenários. Não recomendá-lo para um serviço isolado não significa rejeitá-lo em todo contexto.

### 5. Considerações finais

Retome cada RQ com uma resposta limitada ao caso. Liste contribuições: benchmark controlado, registro da otimização de implementação, modelo documental transparente e matriz de decisão. Termine com limitações: estudo único, benchmark de núcleo não ponta a ponta, ausência de experimento EKS, dependência de preços datados e processo de MTTR a documentar. Trabalhos futuros: execução do mesmo artefato em todos os ambientes, medição ponta a ponta e de inicialização, múltiplas cargas, e validação do EKS.

## Referências iniciais verificadas

ALLEN, Christopher; LI, Xiaozhou; ABDELFATTAH, Amr S.; CERNY, Tomas; TAIBI, Davide. Comparing cost and performance of microservices and serverless in AWS: EC2 vs Lambda. In: HAN, H.; BAKER, E. (ed.). *Next Generation Data Science*. Cham: Springer Nature Switzerland, 2024. p. 60–72. DOI: https://doi.org/10.1007/978-3-031-61816-1_5.

DECKER, Jonathan; KASPRZAK, Piotr; KUNKEL, Julian Martin. Performance evaluation of open-source serverless platforms for Kubernetes. *Algorithms*, v. 15, n. 7, art. 234, 2022. DOI: https://doi.org/10.3390/a15070234.

RUNESON, Per; HÖST, Martin. Guidelines for conducting and reporting case study research in software engineering. *Empirical Software Engineering*, v. 14, n. 2, p. 131–164, 2009. DOI: https://doi.org/10.1007/s10664-008-9102-8.

SCHEUNER, Joel; LEITNER, Philipp. Function-as-a-service performance evaluation: a multivocal literature review. *Journal of Systems and Software*, v. 170, art. 110708, 2020. DOI: https://doi.org/10.1016/j.jss.2020.110708.

WOHLIN, Claes et al. *Experimentation in software engineering*. Berlin: Springer, 2012.

Para preços e características do produto, cite sempre as páginas AWS consultadas na data do fechamento: Lambda Pricing, Amazon EC2 Pricing, Amazon EKS Pricing, Lambda runtime environment e documentação do Amazon EKS. Não substitua essas fontes por artigo científico para valores monetários ou cotas atuais.
