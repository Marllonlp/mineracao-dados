# Gallstone Disease Prediction — Predição de Cálculo Biliar

## Objetivo do trabalho

O objetivo deste trabalho foi aplicar técnicas de mineração de dados na base **Gallstone Disease Prediction**, buscando identificar quais variáveis ajudam a prever a presença de cálculo biliar.

A análise teve foco em três pontos principais:

- avaliar se era realmente necessário usar um corte fixo de 10 variáveis;
- comparar diferentes painéis de atributos;
- escolher um painel com bom equilíbrio entre desempenho, estabilidade e custo de coleta.

## Base de dados

A base utilizada foi a **Gallstone Disease Prediction**, disponível no repositório UCI Machine Learning Repository.

A base contém informações clínicas, laboratoriais e corporais relacionadas à presença ou ausência de cálculo biliar.

Resumo da base:

| Informação | Descrição |
|---|---|
| Base | Gallstone Disease Prediction |
| Quantidade de instâncias | 319 |
| Quantidade de preditoras | 38 |
| Variável alvo | Gallstone |
| Tipo de problema | Classificação supervisionada |

A variável alvo indica se o paciente possui ou não cálculo biliar.

## Problema analisado

O problema trabalhado foi de **classificação supervisionada**.

A pergunta principal foi:

> Com base em variáveis clínicas, laboratoriais e corporais, é possível prever a presença de cálculo biliar?

Além disso, o trabalho também investigou se usar exatamente 10 variáveis era a melhor escolha ou se outro conjunto de atributos poderia gerar melhor resultado.

## Desafio da base

O principal desafio foi encontrar um painel de variáveis que fosse útil na prática.

Não bastava escolher o maior número possível de atributos. Era necessário considerar:

- desempenho estatístico;
- quantidade de variáveis;
- custo de coleta;
- redundância entre variáveis;
- plausibilidade clínica.

Algumas variáveis eram muito correlacionadas entre si, principalmente as relacionadas à composição corporal. Por isso, usar muitas variáveis poderia deixar o modelo mais caro e redundante, sem melhorar muito o resultado.

## Metodologia

As principais etapas realizadas foram:

1. Carregamento da base;
2. Análise exploratória dos dados;
3. Avaliação da distribuição da variável alvo;
4. Análise de relevância das variáveis;
5. Identificação de variáveis redundantes;
6. Criação de painéis candidatos;
7. Comparação dos painéis;
8. Escolha do painel recomendado;
9. Treinamento de diferentes modelos;
10. Avaliação por múltiplas métricas.

## Painéis avaliados

Foram comparados diferentes conjuntos de variáveis:

| Painel | Descrição |
|---|---|
| full_38 | Utiliza todas as 38 variáveis |
| raw_top_k | Usa as principais variáveis pelo ranking bruto de importância |
| pruned_top_k | Usa variáveis selecionadas após remover redundância |
| raw_top_10 | Painel de referência com 10 variáveis |

A análise comparou painéis com diferentes quantidades de atributos para verificar qual entregava o melhor custo-benefício.

## Critério de escolha do painel

A escolha do painel levou em conta:

- AUC;
- F1-score;
- sensitividade;
- custo operacional;
- número de variáveis;
- estabilidade do resultado.

A regra foi escolher o painel elegível com menor custo operacional. Em caso de empate, seria escolhido o painel com menor número de variáveis e, depois, maior sensitividade.

## Painel recomendado

O painel recomendado foi o **pruned_top_11**.

Esse painel utilizou 11 variáveis e apresentou o melhor equilíbrio entre desempenho, estabilidade e custo-benefício.

Variáveis do painel recomendado no cenário 80/20:

- CRP;
- VitaminD;
- ECF_TBW;
- ECW;
- BM;
- TBFR;
- VMA;
- HFA;
- AST;
- Protein;
- Hyperlipidemia.

## Resultado do painel recomendado

O painel **pruned_top_11** apresentou os seguintes resultados médios na comparação dos painéis:

| Painel | Acurácia | Sensitividade | F1-score | AUC | Nº de features | Custo total |
|---|---:|---:|---:|---:|---:|---:|
| pruned_top_11 | 74,41% | 81,60% | 75,22% | 87,04% | 11 | 10,0 |

Esse resultado mostrou que o painel com 11 variáveis foi mais interessante do que assumir automaticamente um corte fixo de 10 variáveis.

## Comparação com o painel de referência

O painel de referência era o **raw_top_10**, com 10 variáveis.

Comparação:

| Painel | Acurácia | Sensitividade | F1-score | AUC | Nº de features |
|---|---:|---:|---:|---:|---:|
| raw_top_10 | 71,16% | 74,13% | 70,03% | 86,78% | 10 |
| pruned_top_11 | 74,41% | 81,60% | 75,22% | 87,04% | 11 |

O painel recomendado teve melhor acurácia, melhor sensitividade e melhor F1-score.

## Modelos utilizados

Foram avaliados nove modelos de classificação:

- Logistic Regression;
- Random Forest;
- AdaBoost;
- Gradient Boosting;
- MLP;
- SVM Radial;
- Decision Tree;
- Naive Bayes;
- KNN.

A comparação entre os modelos ajudou a verificar qual técnica se comportava melhor com o painel selecionado.

## Melhor resultado no cenário 80/20

No cenário 80/20, o painel recomendado apresentou bons resultados com diferentes modelos.

Alguns destaques:

| Modelo | Acurácia | Sensitividade | Especificidade | F1-score | AUC |
|---|---:|---:|---:|---:|---:|
| Logistic Regression | 92,06% | 96,88% | 87,10% | 92,54% | 90,62% |
| Random Forest | 88,89% | 93,75% | 83,87% | 89,55% | 94,76% |
| Gradient Boosting | 84,13% | 84,38% | 83,87% | 84,38% | 90,73% |
| SVM Radial | 84,13% | 90,62% | 77,42% | 85,29% | 92,14% |

A Regressão Logística teve o melhor equilíbrio geral no cenário 80/20, enquanto o Random Forest apresentou a maior AUC.

## Interpretação dos resultados

O resultado principal foi que o painel **pruned_top_11** se mostrou mais adequado do que o painel fixo de 10 variáveis.

Isso aconteceu porque ele conseguiu:

- reduzir redundância entre variáveis;
- manter boa capacidade de previsão;
- melhorar a sensitividade;
- manter custo operacional aceitável;
- apresentar plausibilidade clínica.

A sensitividade foi especialmente importante porque, em um problema de triagem, é desejável identificar corretamente os casos positivos.

## Faz sentido na prática?

Sim, desde que o modelo seja interpretado como uma ferramenta de **apoio à triagem**, e não como substituto de exames clínicos ou de imagem.

O trabalho não afirma causalidade. Ou seja, uma variável preditiva não significa automaticamente que ela seja a causa da doença.

A ideia é usar o modelo como apoio para indicar padrões associados à presença de cálculo biliar.

## Limitações

As principais limitações foram:

- base pequena;
- dados de centro único;
- possível instabilidade no ranking das variáveis;
- presença de variáveis fortemente redundantes;
- ausência de validação externa;
- o modelo não substitui avaliação clínica especializada.

## Conclusão

A principal conclusão é que não era ideal assumir automaticamente um corte fixo de 10 variáveis.

O painel **pruned_top_11** apresentou melhor equilíbrio entre desempenho, estabilidade e custo-benefício.

Mesmo usando apenas 11 variáveis, o painel conseguiu bons resultados e se mostrou mais útil para uma proposta de triagem clínica.

## Como explicar na apresentação

Nesta base, o objetivo foi prever a presença de cálculo biliar usando variáveis clínicas, laboratoriais e corporais.

O diferencial do trabalho foi não aceitar automaticamente o corte de 10 variáveis. Em vez disso, foram testados vários painéis, considerando desempenho, custo e redundância.

O painel escolhido foi o pruned_top_11, com 11 variáveis. Ele teve acurácia de 74,41%, sensitividade de 81,60%, F1-score de 75,22% e AUC de 87,04%.

A conclusão é que esse painel teve melhor custo-benefício do que o painel fixo de 10 variáveis e pode ser usado como apoio à triagem, mas não substitui exames médicos. 