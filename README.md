# README.md — Apresentação Geral

# Trabalhos de Mineração de Dados

Este repositório reúne os trabalhos desenvolvidos na disciplina de Temática em Mineração de Dados. Cada pasta representa uma base analisada, com seu respectivo relatório, metodologia, métricas utilizadas, resultados obtidos e conclusão.

## Objetivo geral

Aplicar técnicas de mineração de dados e aprendizado de máquina em diferentes bases, comparando modelos, avaliando métricas e interpretando os resultados de forma prática.

## Organização do repositório

- 01-cartao-credito/
- 02-interdia/
- 03-drug-consumption/
- 04-gallstone/
- 05-ilpd/

Cada pasta contém:

- README explicativo da base;
- relatório final;
- código utilizado na análise;
- gráficos e resultados, quando necessário.

## Como será apresentada a análise

A apresentação seguirá a seguinte ordem:

1. Explicação geral do repositório e da proposta da disciplina.
2. Apresentação individual de cada base.
3. Comparação entre os trabalhos.
4. Conclusão geral.

## Estrutura usada em cada trabalho

Em cada base, seguimos uma estrutura parecida:

1. Problema analisado;
2. Descrição da base;
3. Tratamento dos dados;
4. Modelos testados;
5. Métricas utilizadas;
6. Resultados principais;
7. Conclusão.

## Conclusão geral

Os trabalhos mostram que a escolha de um modelo não deve ser feita apenas pela acurácia. Em bases desbalanceadas ou ligadas à saúde e risco, métricas como sensitividade, especificidade, F1-score, AUC e matriz de confusão são essenciais para avaliar se o modelo realmente é útil na prática.



# 01-cartao-credito/README.md

# Análise de Inadimplência em Cartão de Crédito

## Objetivo

O objetivo deste trabalho foi prever a inadimplência de clientes de cartão de crédito utilizando técnicas de mineração de dados e aprendizado de máquina.

A análise buscou melhorar um artigo de referência que utilizava Random Forest com Recursive Feature Elimination, aplicando novas estratégias de preparação, balanceamento e ajuste do modelo.

## Base de dados

A base utilizada foi a Default of Credit Card Clients, disponível no UCI Machine Learning Repository. Ela contém informações de clientes de cartão de crédito de Taiwan, com variáveis relacionadas a limite de crédito, histórico de pagamento, valores de fatura e pagamentos realizados.

A variável-alvo indica se o cliente se tornou inadimplente no mês seguinte.

## Metodologia

As principais etapas realizadas foram:

- carregamento da base;
- remoção da coluna de identificação;
- tratamento de categorias inconsistentes;
- conversão das variáveis categóricas;
- separação entre treino e teste;
- criação de novas variáveis;
- seleção de atributos com RFE;
- treinamento com Random Forest;
- balanceamento da classe minoritária com SMOTE;
- ajuste do limiar de decisão.

## Melhorias aplicadas

Foram criadas três variáveis principais:

- SOMA_ATRASOS: representa o histórico acumulado de atrasos;
- USO_LIMITE_ATUAL: indica o quanto do limite de crédito foi utilizado;
- RAZAO_PAGAMENTO_ATUAL: mostra a proporção da fatura que foi paga.

Além disso, foi aplicado SMOTE para lidar com o desbalanceamento da base e o número de árvores do Random Forest foi aumentado para tornar o modelo mais estável.

## Métricas utilizadas

As principais métricas avaliadas foram:

- acurácia;
- sensitividade;
- especificidade;
- AUC;
- comparação entre diferentes limiares.

## Resultados principais

O modelo manteve AUC de 0,753. O ponto mais importante foi o ajuste do limiar de decisão.

Com limiar padrão de 0,50, a sensitividade foi de 37,53%. Com o limiar ajustado para 0,38, a sensitividade subiu para 45,21%, mantendo especificidade acima de 90%.

Isso é relevante porque, em risco de crédito, identificar possíveis devedores é mais importante do que apenas manter uma acurácia geral alta.

## Conclusão

A análise mostrou que o modelo ficou mais útil para aplicação prática ao priorizar a detecção de clientes inadimplentes. Mesmo sem aumentar a AUC, o ajuste de limiar tornou o modelo mais adequado para o problema real de crédito.



# 02-interdia/README.md

# InterDIA — Previsão de Autoimunidade Induzida por Fármacos

## Objetivo

O objetivo deste trabalho foi prever se compostos químicos apresentam sinais compatíveis com risco de induzir respostas autoimunes.

A proposta foi reproduzir o desenho científico do artigo de referência, mas criando uma versão mais simples de executar, transparente e reprodutível em R.

## Base de dados

A base foi obtida do UCI Machine Learning Repository. Ela contém descritores moleculares dos compostos e uma variável-alvo indicando risco positivo ou negativo para autoimunidade induzida por fármacos.

O conjunto de teste externo foi preservado apenas para avaliação final, evitando vazamento de dados.

## Metodologia

As principais etapas foram:

- uso da base oficial;
- manutenção do mesmo conjunto treino-teste externo do artigo;
- reutilização do subconjunto de 65 descritores publicados;
- treinamento de modelos supervisionados;
- avaliação com foco em base desbalanceada;
- escolha de limiar priorizando sensitividade;
- análise dos descritores mais importantes.

## Problema do desbalanceamento

A base possui menos compostos positivos do que negativos. Por isso, a acurácia sozinha não é suficiente.

Como o problema envolve risco em desenvolvimento de medicamentos, a análise priorizou evitar que compostos perigosos fossem classificados como seguros.

## Métricas utilizadas

Foram avaliadas métricas como:

- acurácia;
- sensitividade;
- especificidade;
- MCC;
- AUC;
- matriz de confusão.

## Modelo principal

O modelo principal utilizado foi o EasyEnsemble Screening, escolhido por ser mais adequado para triagem em base desbalanceada.

A ideia foi priorizar uma análise segura, evitando deixar passar compostos potencialmente problemáticos.

## Resultados e interpretação

A análise destacou descritores importantes como Ipc, Chi0, SlogP_VSA5, EState_VSA1, HallKierAlpha, RingCount, BalabanJ e Kappa3.

Esses atributos ajudam a explicar quais características químicas contribuíram mais para a separação entre compostos positivos e negativos.

## Conclusão

A análise foi considerada forte porque não entregou apenas um número de desempenho, mas um fluxo completo: base oficial, avaliação justa, reprodutibilidade, interpretação dos atributos e justificativa científica.

Para apresentação, o ponto principal é mostrar que a escolha das métricas foi guiada pelo contexto do problema, e não apenas pela busca de maior acurácia.



# 03-drug-consumption/README.md

# Drug Consumption — Análise de Consumo de Drogas

## Objetivo

O objetivo deste trabalho foi analisar a base Drug Consumption e construir modelos capazes de classificar usuários e não usuários para diferentes substâncias.

A proposta foi superar o artigo de referência no maior número possível de métricas e drogas, utilizando uma estratégia mais flexível por substância.

## Base de dados

A base utilizada foi a UCI Drug Consumption. Ela contém informações dos respondentes e classes relacionadas ao consumo de diferentes drogas.

A classificação foi organizada da seguinte forma:

- CL0 e CL1: Não usuário;
- CL2 a CL6: Usuário.

Respondentes que declararam uso de Semeron, uma droga fictícia usada para detectar respostas falsas, foram removidos da base.

## Metodologia

As principais etapas foram:

- limpeza da base;
- remoção de respostas inconsistentes;
- separação entre treino e teste;
- criação de modelos por droga;
- comparação entre diferentes famílias de modelos;
- tratamento de desbalanceamento;
- ajuste de limiar por droga;
- avaliação por métricas principais e adicionais.

## Estratégia aplicada

Diferente de uma abordagem única com Random Forest, este trabalho testou diferentes modelos para cada droga, como:

- Random Forest;
- regressão logística penalizada;
- C5.0;
- modelos com pesos de classe;
- SMOTE;
- ADASYN;
- ensembles simples.

A escolha foi feita de acordo com a dificuldade e o desbalanceamento de cada droga.

## Métricas utilizadas

As principais métricas foram:

- acurácia;
- sensitividade;
- especificidade;
- F1-score;
- ROC AUC;
- PR AUC;
- acurácia balanceada.

## Resultados principais

A análise proposta apresentou melhor equilíbrio entre sensitividade e especificidade em relação ao baseline simples.

A média geral da análise ficou mais adequada para comparação prática porque não olhou apenas para acurácia, mas também para o equilíbrio entre acertos nas duas classes.

## Conclusão

A análise mostrou que tratar cada droga individualmente é mais adequado do que aplicar um único modelo fixo para todas.

O principal ganho foi metodológico: testar múltiplos modelos, lidar melhor com desbalanceamento e ajustar limiares conforme o objetivo da classificação.



# 04-gallstone/README.md

# Gallstone Disease Prediction

## Objetivo

O objetivo deste trabalho foi analisar a base Gallstone Disease Prediction e investigar se um painel fixo de 10 variáveis realmente era necessário para prever presença de cálculo biliar.

A análise buscou equilibrar desempenho estatístico, custo de coleta das variáveis e plausibilidade clínica.

## Base de dados

A base utilizada foi a Gallstone Disease Prediction, disponível no UCI Machine Learning Repository.

Ela possui informações clínicas, laboratoriais e de composição corporal relacionadas à presença ou ausência de cálculo biliar.

A variável-alvo indica a presença de cálculo biliar.

## Metodologia

As principais etapas realizadas foram:

- análise exploratória;
- avaliação da distribuição da variável-alvo;
- análise por gênero;
- estudo de correlação entre variáveis;
- identificação de redundância;
- criação de painéis candidatos;
- comparação entre painéis completos, painéis brutos e painéis podados;
- validação cruzada;
- comparação entre modelos.

## Seleção de variáveis

Foram comparados diferentes painéis:

- full_38: todas as variáveis;
- raw_top_k: variáveis ranqueadas por importância;
- pruned_top_k: variáveis selecionadas após remover redundância forte.

A análise não considerou apenas desempenho. Também avaliou o custo operacional de coletar cada grupo de variáveis.

## Painel recomendado

O painel recomendado foi o pruned_top_11, com 11 variáveis.

Esse painel apresentou melhor equilíbrio entre desempenho médio, estabilidade e custo-benefício do que assumir um corte fixo universal de 10 variáveis.

## Métricas utilizadas

Foram avaliadas:

- acurácia;
- sensitividade;
- especificidade;
- precisão;
- F1-score;
- AUC;
- validação cruzada.

## Conclusão

O painel com 11 variáveis foi considerado mais adequado porque manteve bom desempenho e reduziu redundância.

A principal conclusão é que mais variáveis nem sempre significam melhor modelo. Em problemas reais, um painel menor, estável e com menor custo pode ser mais útil do que um conjunto grande de atributos.



# 05-ilpd/README.md

# ILPD — Indian Liver Patient Dataset

## Objetivo

O objetivo deste trabalho foi analisar a base Indian Liver Patient Dataset e comparar modelos de classificação para prever se um paciente possui ou não doença hepática.

A análise considerou a base completa e também separações por gênero, avaliando diferenças de desempenho entre os cenários.

## Base de dados

A base ILPD contém informações clínicas e laboratoriais de pacientes, incluindo variáveis relacionadas à função hepática.

A variável-alvo indica se o paciente pertence ao grupo doente ou saudável.

## Metodologia

As principais etapas foram:

- carregamento da base;
- renomeação das colunas;
- conversão da variável Gender;
- conversão da variável-alvo para Doente e Saudável;
- verificação de valores ausentes;
- separação estratificada entre treino e teste;
- validação cruzada estratificada com 10 folds;
- tratamento do desbalanceamento com upsampling;
- imputação por mediana;
- padronização das variáveis;
- avaliação final no conjunto de teste.

## Modelos testados

Foram avaliados diferentes modelos supervisionados:

- Regressão Logística;
- Random Forest;
- SVM com kernel radial;
- Naive Bayes;
- outros modelos comparativos.

## Cenários analisados

A análise foi feita em três cenários:

1. Base completa;
2. Apenas pacientes homens;
3. Apenas pacientes mulheres.

Essa separação permitiu verificar se o desempenho dos modelos mudava conforme o grupo analisado.

## Métricas utilizadas

Foram utilizadas:

- acurácia;
- sensitividade;
- especificidade;
- precisão;
- recall;
- F1-score;
- AUC;
- score geral.

## Resultados principais

Na base completa, o melhor modelo pelo critério composto foi a Regressão Logística.

No cenário de pacientes homens, o melhor modelo foi Random Forest, com bom desempenho em sensitividade e F1-score.

No cenário de pacientes mulheres, o Random Forest também foi o melhor pelo critério composto, mas o desempenho foi inferior, possivelmente por causa do menor número de registros femininos.

## Conclusão

A análise mostrou que a escolha do melhor modelo depende do cenário avaliado.

Como a base é pequena e desbalanceada, a acurácia sozinha não é suficiente. Métricas como sensitividade, especificidade, F1-score e AUC dão uma visão mais justa do desempenho dos modelos.
