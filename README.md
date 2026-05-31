# Aplicações de Mineração de Dados na Predição de Riscos

## Sobre o projeto

Este repositório reúne os trabalhos desenvolvidos na disciplina de **Temática em Mineração de Dados**.

As análises foram aplicadas em diferentes áreas, como crédito, saúde, toxicologia e comportamento, utilizando técnicas de mineração de dados e aprendizado de máquina para identificar padrões, prever riscos e comparar modelos.

## Objetivo geral

O objetivo geral foi aplicar técnicas de mineração de dados em bases reais, avaliando os resultados por meio de métricas adequadas e interpretando os modelos de forma prática.

A apresentação não tem foco em código, mas sim em:

- objetivo de cada base;
- metodologia aplicada;
- métricas utilizadas;
- principais resultados;
- interpretação dos resultados;
- comparação entre os trabalhos.

## Trabalhos analisados

| Nº | Trabalho | Área | Objetivo |
|---|---|---|---|
| 1 | Cartão de Crédito | Finanças | Prever inadimplência |
| 2 | InterDIA | Toxicologia | Prever risco de autoimunidade induzida por fármacos |
| 3 | Drug Consumption | Comportamento | Prever risco de consumo de drogas |
| 4 | Gallstone Disease Prediction | Saúde | Prever presença de cálculo biliar |
| 5 | ILPD | Saúde | Prever doença hepática |

## Metodologia geral

Apesar de cada base ter características próprias, os trabalhos seguiram uma estrutura semelhante:

1. escolha e carregamento da base de dados;
2. análise inicial dos dados;
3. tratamento de dados ausentes ou inconsistentes;
4. separação entre treino e teste;
5. tratamento de desbalanceamento, quando necessário;
6. treinamento de modelos de classificação;
7. avaliação por métricas;
8. comparação dos resultados;
9. interpretação final.

## Métricas utilizadas

As principais métricas utilizadas nos trabalhos foram:

| Métrica | Significado |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensitividade | Capacidade de identificar corretamente os casos positivos |
| Especificidade | Capacidade de identificar corretamente os casos negativos |
| Precisão | Proporção de previsões positivas corretas |
| F1-score | Equilíbrio entre precisão e sensitividade |
| AUC | Capacidade geral do modelo de separar as classes |
| Matriz de confusão | Mostra os acertos e erros por classe |
| MCC | Métrica útil para bases desbalanceadas |

A acurácia não foi usada como única métrica, porque algumas bases eram desbalanceadas. Nesses casos, métricas como sensitividade, especificidade, F1-score e AUC foram mais importantes para avaliar o desempenho real dos modelos.

## Resumo dos resultados

| Trabalho | Principal técnica/modelo | Principal resultado |
|---|---|---|
| Cartão de Crédito | Random Forest, RFE, SMOTE e ajuste de limiar | AUC de 0,753 e aumento da sensitividade com limiar 0,38 |
| InterDIA | EasyEnsemble Screening | AUC de 0,897 e sensitividade de 0,900 |
| Drug Consumption | Modelos específicos por droga | Melhor equilíbrio entre sensitividade e especificidade |
| Gallstone | Seleção de variáveis e comparação de painéis | Painel recomendado pruned_top_11 |
| ILPD | Regressão Logística e Random Forest | Melhor desempenho variou conforme o cenário analisado |

## Organização do repositório

Cada pasta contém os arquivos relacionados a uma base específica:

- `README.md`: explicação resumida do trabalho;
- `relatorio.pdf`: relatório completo;
- `codigo.R` ou script equivalente: código usado na análise;
- gráficos ou resultados auxiliares, quando houver.

## Bases analisadas

### 01 — Cartão de Crédito

O trabalho teve como objetivo prever inadimplência de clientes de cartão de crédito.

Foram utilizadas técnicas como Random Forest, RFE, SMOTE e ajuste de limiar. O principal resultado foi a AUC de 0,753, com melhora na sensitividade ao ajustar o limiar de decisão.

[Acessar análise de Cartão de Crédito](./01-cartao-credito/)

### 02 — InterDIA

O trabalho teve como objetivo prever risco de autoimunidade induzida por fármacos a partir de descritores moleculares.

O modelo principal foi o EasyEnsemble Screening, que apresentou bom desempenho em uma base desbalanceada, com AUC de 0,897 e sensitividade de 0,900.

[Acessar análise InterDIA](./02-interdia/)

### 03 — Drug Consumption

O trabalho teve como objetivo prever usuários e não usuários para diferentes substâncias.

A estratégia foi testar modelos específicos por droga, tratando o desbalanceamento e ajustando limiares conforme a necessidade de cada substância.

[Acessar análise Drug Consumption](./03-drug-consumption/)

### 04 — Gallstone Disease Prediction

O trabalho teve como objetivo prever presença de cálculo biliar.

O diferencial foi comparar diferentes painéis de variáveis, considerando desempenho, custo de coleta e redundância. O painel recomendado foi o `pruned_top_11`.

[Acessar análise Gallstone](./04-gallstone/)

### 05 — ILPD

O trabalho teve como objetivo prever doença hepática usando dados demográficos e bioquímicos.

A análise comparou modelos na base completa e também separou os cenários por gênero. O melhor modelo variou conforme o cenário analisado.

[Acessar análise ILPD](./05-ilpd/)

## Comparação geral

| Critério | Cartão | InterDIA | Drogas | Gallstone | ILPD |
|---|---|---|---|---|---|
| Área | Crédito | Toxicologia | Comportamento | Saúde | Saúde |
| Tipo de problema | Classificação | Classificação | Classificação | Classificação | Classificação |
| Base desbalanceada | Sim | Sim | Sim | Parcialmente | Sim |
| Foco principal | Inadimplência | Risco autoimune | Consumo | Cálculo biliar | Doença hepática |
| Métrica importante | Sensitividade | Sensitividade e AUC | Sensitividade e especificidade | AUC e F1-score | F1-score e AUC |

## Principais aprendizados

Os trabalhos mostraram que a escolha do melhor modelo depende do contexto da base e do objetivo da análise.

Em bases desbalanceadas, a acurácia pode ser enganosa. Por isso, foi necessário avaliar outras métricas, principalmente sensitividade, especificidade, F1-score e AUC.

Também foi possível observar que modelos mais complexos nem sempre são automaticamente melhores. Em alguns casos, o mais importante foi ajustar o limiar, tratar o desbalanceamento ou escolher melhor as variáveis.

## Divisão da apresentação

### Parte 1

Responsável por apresentar:

- objetivo geral;
- organização do repositório;
- metodologia comum;
- métricas utilizadas;
- análise de Cartão de Crédito.

### Parte 2

Responsável por apresentar:

- análise InterDIA;
- análise Drug Consumption;
- principais desafios das bases desbalanceadas.

### Parte 3

Responsável por apresentar:

- análise Gallstone;
- análise ILPD;
- comparação geral;
- conclusão.

## Conclusão geral

A mineração de dados pode ser aplicada em diferentes áreas para apoiar decisões, prever riscos e identificar padrões.

Os trabalhos mostraram que não basta treinar um modelo e olhar apenas para a acurácia. É necessário entender o problema, avaliar as métricas corretas e interpretar os resultados conforme o contexto da base.

O principal aprendizado foi que o melhor modelo é aquele que apresenta equilíbrio entre desempenho, interpretação e utilidade prática.