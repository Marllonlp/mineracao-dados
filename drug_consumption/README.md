# Drug Consumption — Predição de Risco de Consumo de Drogas

## Objetivo do trabalho

O objetivo deste trabalho foi aplicar técnicas de mineração de dados para prever o risco de consumo de diferentes substâncias a partir da base **Drug Consumption**.

A análise buscou classificar os indivíduos em dois grupos:

- **Não usuário**
- **Usuário**

O foco principal foi comparar modelos, tratar o desbalanceamento das classes e melhorar o equilíbrio entre sensitividade e especificidade.

## Base de dados

A base utilizada foi a **UCI Drug Consumption (Quantified)**.

Ela contém informações de respondentes e registros relacionados ao consumo de diferentes substâncias. Cada substância possui uma classificação de consumo dividida em níveis.

Para este trabalho, as classes foram reorganizadas da seguinte forma:

| Classes originais | Nova classificação |
|---|---|
| CL0 e CL1 | Não usuário |
| CL2 até CL6 | Usuário |

Também foram removidos os respondentes que declararam uso de **Semeron**, uma substância fictícia usada para identificar respostas inconsistentes.

## Problema analisado

O problema trabalhado foi de **classificação supervisionada**.

A pergunta principal foi:

> Com base nas características dos respondentes, é possível prever se uma pessoa pertence ao grupo de usuário ou não usuário para cada substância?

Como cada droga possui uma distribuição diferente de usuários e não usuários, a análise foi feita separadamente para cada substância.

## Drogas analisadas

Foram avaliadas várias substâncias da base, incluindo:

- Alcohol;
- Amphet;
- Amyl;
- Benzos;
- Caffeine;
- Cannabis;
- Chocolate;
- Coke;
- Crack;
- Ecstasy;
- Heroin;
- Ketamine;
- LSD;
- Legalh;
- Meth;
- Mushrooms;
- Nicotine;
- VSA.

## Desafio da base

O principal desafio foi o **desbalanceamento das classes**.

Algumas substâncias tinham muitos usuários, como álcool, cafeína e chocolate. Outras tinham poucos usuários, como crack, heroína e VSA.

Por isso, a acurácia sozinha não era suficiente para avaliar os modelos. Um modelo poderia ter boa acurácia apenas por acertar a classe majoritária.

## Metodologia

As principais etapas realizadas foram:

1. Carregamento da base;
2. Limpeza dos dados;
3. Remoção de respostas inconsistentes;
4. Conversão das classes em Usuário e Não usuário;
5. Separação entre treino e teste;
6. Treinamento de modelos diferentes por droga;
7. Tratamento do desbalanceamento;
8. Ajuste do limiar de decisão;
9. Avaliação por métricas;
10. Comparação com o artigo de referência.

## Técnicas utilizadas

Foram utilizadas diferentes técnicas, dependendo da dificuldade de cada droga:

| Técnica | Função |
|---|---|
| Random Forest | Modelo baseado em árvores de decisão |
| Ranger com pesos | Floresta aleatória com ajuste para classes desbalanceadas |
| Regressão logística penalizada | Modelo linear com regularização |
| C5.0 | Modelo baseado em árvore/boosting |
| SMOTE | Criação de exemplos sintéticos da classe minoritária |
| ADASYN | Balanceamento adaptativo da classe minoritária |
| Ensemble | Combinação de modelos para melhorar o desempenho |
| Ajuste de limiar | Escolha do melhor ponto de corte para cada droga |

A estratégia principal foi testar vários modelos e escolher a melhor abordagem para cada substância.

## Métricas utilizadas

As principais métricas avaliadas foram:

| Métrica | O que indica |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensitividade | Capacidade de identificar usuários |
| Especificidade | Capacidade de identificar não usuários |
| Precisão | Proporção de previsões positivas corretas |
| F1-score | Equilíbrio entre precisão e sensitividade |
| Acurácia balanceada | Média entre sensitividade e especificidade |
| ROC AUC | Capacidade geral de separação entre classes |
| PR AUC | Desempenho em bases desbalanceadas |

## Resultado médio geral

A análise proposta apresentou o seguinte desempenho médio:

| Abordagem | Acurácia | Sensitividade | Especificidade | F1-score | Acurácia balanceada | ROC AUC | PR AUC |
|---|---:|---:|---:|---:|---:|---:|---:|
| Nossa análise | 72,86% | 72,56% | 72,66% | 62,22% | 72,61% | 79,32% | 63,08% |
| Baseline RF | 81,52% | 59,70% | 68,78% | 60,26% | - | - | - |
| Artigo | 81,60% | 59,89% | 69,20% | 61,97% | - | - | - |
| Dados brutos | 82,61% | 54,48% | 70,86% | 56,14% | - | - | - |

## Interpretação dos resultados

A análise proposta teve acurácia média menor do que o artigo, mas apresentou melhor equilíbrio entre as classes.

O principal ganho foi na **sensitividade**, que passou de aproximadamente **59,89% no artigo** para **72,56% na análise proposta**.

Isso significa que o modelo passou a identificar melhor os usuários, sem depender apenas da classe majoritária.

Em bases desbalanceadas, esse equilíbrio é mais importante do que olhar apenas para a acurácia geral.

## Exemplos de resultados por droga

Algumas drogas tiveram resultados relevantes:

| Droga | Acurácia | Sensitividade | Especificidade | F1-score |
|---|---:|---:|---:|---:|
| Cannabis | 79,53% | 76,60% | 85,35% | 83,28% |
| Ecstasy | 76,33% | 78,61% | 75,00% | 71,02% |
| LSD | 78,04% | 85,95% | 75,29% | 66,88% |
| Legalh | 80,81% | 82,78% | 79,58% | 76,80% |
| Mushrooms | 78,04% | 79,62% | 77,24% | 70,82% |

Esses resultados mostram que a estratégia funcionou melhor em algumas substâncias, principalmente quando o modelo conseguiu equilibrar bem sensitividade e especificidade.

## Comparação com o artigo

O artigo de referência utilizava uma estratégia mais fixa, baseada principalmente em Random Forest.

Neste trabalho, a estratégia foi mais flexível:

- cada droga foi analisada separadamente;
- diferentes modelos foram testados;
- o desbalanceamento foi tratado conforme a necessidade;
- o limiar de decisão foi ajustado por droga;
- a escolha do modelo considerou várias métricas, não apenas acurácia.

## Conclusão

A principal conclusão é que, para a base Drug Consumption, não é ideal usar um único modelo fixo para todas as drogas.

Cada substância possui comportamento e distribuição diferentes. Por isso, testar modelos separadamente e ajustar o limiar de decisão tornou a análise mais equilibrada.

Mesmo com acurácia média menor, a análise proposta foi mais útil porque melhorou a identificação dos usuários e avaliou melhor o desempenho em bases desbalanceadas.
