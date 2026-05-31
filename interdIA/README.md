# InterDIA — Previsão de Autoimunidade Induzida por Fármacos

## Objetivo do trabalho

O objetivo deste trabalho foi aplicar técnicas de mineração de dados para prever se determinados compostos químicos apresentam risco de causar autoimunidade induzida por fármacos.

A ideia principal foi analisar descritores moleculares dos compostos e verificar se esses padrões químicos poderiam indicar maior risco de desencadear respostas autoimunes.

## Base de dados

A base utilizada foi disponibilizada no UCI Machine Learning Repository.

Ela contém compostos químicos representados por descritores moleculares. Cada composto possui uma classificação indicando se está associado ou não à autoimunidade induzida por fármacos.

A base foi dividida em dois conjuntos:

| Conjunto | Total | Positivos | Negativos | Taxa de positivos |
|---|---:|---:|---:|---:|
| Treino | 477 | 118 | 359 | 24,7% |
| Teste | 120 | 30 | 90 | 25,0% |

Foram utilizados os mesmos 65 descritores moleculares publicados no artigo de referência.

## Problema analisado

O problema trabalhado foi de **classificação supervisionada**.

A pergunta principal foi:

> Com base nos descritores moleculares de um composto, é possível prever se ele apresenta risco de autoimunidade induzida por fármacos?

Esse tipo de análise pode ser útil em etapas iniciais do desenvolvimento de medicamentos, ajudando a identificar compostos que merecem maior atenção antes de avançarem para fases posteriores.

## Desafio da base

A base é desbalanceada, pois existem menos compostos positivos do que negativos.

Isso significa que a acurácia sozinha não é suficiente para avaliar o modelo. Um modelo poderia acertar muitos compostos negativos e ainda assim falhar justamente nos casos mais importantes: os compostos com possível risco autoimune.

Por isso, a análise deu atenção especial à sensitividade, especificidade, MCC e AUC.

## Metodologia

As principais etapas realizadas foram:

1. Carregamento da base oficial;
2. Separação entre treino e teste externo;
3. Uso do subconjunto de 65 descritores moleculares;
4. Treinamento de diferentes modelos;
5. Escolha do limiar de classificação com base no treino;
6. Avaliação final no conjunto de teste externo;
7. Análise dos descritores mais importantes;
8. Comparação com o benchmark publicado.

## Modelos testados

Foram comparados três modelos principais:

| Modelo | Função na análise |
|---|---|
| Elastic Net | Modelo linear usado como baseline |
| Weighted Ranger | Floresta aleatória ponderada |
| EasyEnsemble Screening | Modelo principal para triagem em base desbalanceada |

O modelo escolhido como principal foi o **EasyEnsemble Screening**.

## Escolha do limiar

O limiar de classificação não foi fixado automaticamente em 0,50.

A estratégia foi escolher um limiar que mantivesse boa sensitividade, porque, neste problema, deixar passar um composto potencialmente perigoso seria mais grave do que gerar alguns alertas falsos.

O limiar final escolhido para o modelo principal foi **0,49**.

## Métricas utilizadas

As principais métricas avaliadas foram:

| Métrica | O que indica |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensitividade | Capacidade de identificar compostos positivos |
| Especificidade | Capacidade de identificar compostos negativos |
| Precisão | Proporção de positivos previstos corretamente |
| F1-score | Equilíbrio entre precisão e sensitividade |
| MCC | Qualidade geral da classificação em base desbalanceada |
| AUC | Capacidade geral de separação entre as classes |

## Resultados principais

No teste externo, o modelo **EasyEnsemble Screening** apresentou o melhor desempenho geral.

| Modelo | Acurácia | Sensitividade | Especificidade | F1-score | MCC | AUC |
|---|---:|---:|---:|---:|---:|---:|
| EasyEnsemble Screening | 0,808 | 0,900 | 0,778 | 0,701 | 0,601 | 0,897 |
| Weighted Ranger | 0,758 | 0,833 | 0,733 | 0,633 | 0,499 | 0,883 |
| Elastic Net | 0,250 | 0,933 | 0,022 | 0,384 | -0,107 | 0,560 |

## Interpretação dos resultados

O melhor modelo foi o **EasyEnsemble Screening**, porque conseguiu equilibrar bem a identificação de compostos positivos e negativos.

O resultado foi considerado forte por três motivos:

1. apresentou **AUC alta**, indicando boa separação entre as classes;
2. teve **sensitividade de 0,900**, importante para triagem de risco;
3. manteve **especificidade de 0,778**, evitando excesso de falsos alarmes.

Em outras palavras, o modelo conseguiu identificar grande parte dos compostos de risco sem classificar quase tudo como perigoso.

## Descritores mais importantes

Alguns dos descritores moleculares mais relevantes foram:

| Descritor | Importância |
|---|---:|
| Ipc | 0,0599 |
| Chi0 | 0,0582 |
| SlogP_VSA5 | 0,0550 |
| EState_VSA1 | 0,0538 |
| HallKierAlpha | 0,0535 |
| RingCount | 0,0534 |
| BalabanJ | 0,0531 |
| Kappa3 | 0,0511 |

Esses descritores representam características químicas e estruturais dos compostos, como conectividade molecular, presença de anéis e propriedades relacionadas à superfície molecular.

## Conclusão

A análise mostrou que o modelo EasyEnsemble Screening foi o mais adequado para prever risco de autoimunidade induzida por fármacos.

O principal ponto do trabalho foi mostrar que, em bases desbalanceadas e ligadas à segurança, o melhor modelo não deve ser escolhido apenas pela acurácia.

Neste caso, métricas como sensitividade, especificidade, MCC e AUC foram mais importantes para avaliar se o modelo realmente seria útil em uma situação prática de triagem toxicológica.

## Como explicar na apresentação

Nesta base, o objetivo foi prever se um composto químico poderia estar associado à autoimunidade induzida por fármacos.

A base era desbalanceada, com menos compostos positivos do que negativos. Por isso, a análise priorizou métricas além da acurácia, principalmente sensitividade e AUC.

Foram testados três modelos: Elastic Net, Weighted Ranger e EasyEnsemble Screening. O melhor resultado foi do EasyEnsemble Screening, que atingiu AUC de 0,897, sensitividade de 0,900 e especificidade de 0,778 no teste externo.

A conclusão principal é que o modelo conseguiu bom equilíbrio entre detectar compostos de risco e evitar excesso de falsos alarmes.