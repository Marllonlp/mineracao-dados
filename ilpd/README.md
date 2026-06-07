# ILPD - Predição de Doença Hepática

## Objetivo do trabalho

O objetivo deste trabalho foi prever se um paciente apresenta ou não doença hepática usando informações demográficas e exames bioquímicos.

O ponto principal do trabalho foi lidar com uma base desbalanceada. A maioria dos registros pertence à classe de pacientes doentes, então a acurácia sozinha poderia dar uma visão incompleta do desempenho.

Por isso, a análise comparou diferentes modelos e avaliou várias métricas, como sensibilidade, especificidade, F1-score e AUC.

---

## Base de dados

A base utilizada foi a **Indian Liver Patient Dataset - ILPD**.

Ela contém registros de pacientes com variáveis relacionadas à função hepática.

| Informação | Valor |
|---|---:|
| Total de registros | 583 |
| Total de colunas | 11 |
| Pacientes doentes | 416 |
| Pacientes saudáveis | 167 |
| Percentual de doentes | 71,36% |
| Percentual de saudáveis | 28,64% |

A variável alvo original foi convertida para duas classes:

| Valor original | Classe usada |
|---|---|
| 1 | Doente |
| 2 | Saudável |

---

## Problema analisado

O problema é de **classificação supervisionada**.

A pergunta principal foi:

> Com base em características demográficas e bioquímicas, é possível prever se um paciente possui doença hepática?

Esse tipo de análise pode ser usado como apoio à triagem, ajudando a identificar padrões associados à presença de doença hepática.

---

## Resultado esperado

Como a base é desbalanceada, o resultado esperado não era apenas obter a maior acurácia.

O objetivo era encontrar modelos que equilibrassem:

- identificação de pacientes doentes;
- identificação de pacientes saudáveis;
- bom desempenho geral;
- avaliação mais justa das classes;
- menor risco de escolher um modelo enganoso por causa do desbalanceamento.

Isso é importante porque 71,36% dos registros são de pacientes doentes. Um modelo poderia favorecer essa classe e parecer bom pela acurácia, mesmo errando muitos pacientes saudáveis.

---

## Metodologia usada

A metodologia seguiu estas etapas principais:

1. carregamento da base;
2. renomeação das colunas;
3. conversão da variável `Gender` para fator;
4. conversão da variável alvo para Doente e Saudável;
5. verificação de valores ausentes;
6. tratamento dos 4 valores ausentes em `Albumin_and_Globulin_Ratio`;
7. separação estratificada entre treino e teste;
8. validação cruzada estratificada com 10 folds;
9. tratamento do desbalanceamento com upsampling;
10. imputação por mediana;
11. centralização e padronização dos dados;
12. treinamento dos modelos;
13. avaliação final no conjunto de teste.

A análise foi feita em três cenários:

| Cenário | Descrição |
|---|---|
| Base completa | Todos os pacientes |
| Homens | Apenas pacientes do sexo masculino |
| Mulheres | Apenas pacientes do sexo feminino |

Essa divisão permitiu verificar se os modelos se comportavam de forma diferente dependendo do grupo analisado.

---

## Modelos avaliados

Foram comparados diferentes modelos de classificação:

- Regressão Logística;
- Random Forest;
- SVM Radial;
- Naive Bayes;
- XGBoost.

Os resultados finais priorizam os modelos com desempenho mais relevante nas tabelas comparativas.

---

## Métricas usadas

As principais métricas foram:

| Métrica | Interpretação |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensibilidade | Capacidade de identificar pacientes doentes |
| Especificidade | Capacidade de identificar pacientes saudáveis |
| Precisão | Proporção de previsões positivas corretas |
| F1-score | Equilíbrio entre precisão e sensibilidade |
| AUC | Capacidade geral de separação entre as classes |

Neste problema, sensibilidade e especificidade são importantes porque a base envolve saúde e possui classes desbalanceadas.

---

## Resultados principais

Os melhores modelos por cenário foram:

| Cenário | Melhor modelo | Acurácia | Sensibilidade | Especificidade | F1-score | AUC |
|---|---|---:|---:|---:|---:|---:|
| Base completa | Regressão Logística | 68,4% | 62,1% | 84,0% | 73,7% | 76,8% |
| Homens | Random Forest | 75,0% | 82,5% | 54,3% | 82,9% | 82,2% |
| Mulheres | Random Forest | 59,5% | 63,0% | 53,3% | 66,7% | 66,4% |

Na base completa, a Regressão Logística foi escolhida pelo critério composto, porque apresentou melhor equilíbrio geral, principalmente pela especificidade de 84,0%.

No cenário masculino, o melhor modelo foi o Random Forest. Esse foi o melhor cenário geral da análise, com acurácia de 75,0%, sensibilidade de 82,5% e AUC de 82,2%.

No cenário feminino, o melhor modelo também foi o Random Forest, mas os resultados foram mais baixos. Isso provavelmente aconteceu porque havia menos registros de mulheres, deixando o treinamento mais instável.

---

## Comparação com o artigo

O artigo de referência apresentou acurácias próximas de 71% a 76%, dependendo do cenário e do modelo.

Neste projeto, os resultados de acurácia ficaram abaixo do artigo, mas a análise foi mais completa porque avaliou múltiplas métricas, tratou o desbalanceamento e comparou os cenários por sexo.

| Cenário | Melhor acurácia do artigo | Melhor acurácia do projeto | Houve melhoria em acurácia? |
|---|---:|---:|---|
| Base completa | 75,3% | 68,4% | Não |
| Homens | 76,5% | 75,0% | Não |
| Mulheres | 71,4% | 59,5% | Não |

Mesmo sem superar o artigo em acurácia, a análise mostrou que escolher modelo apenas pela acurácia pode ser inadequado em uma base médica desbalanceada.

---

## Interpretação

A principal interpretação é que o melhor modelo depende do cenário analisado.

Na base completa, a Regressão Logística teve melhor equilíbrio pelo critério composto. Para homens e mulheres, o Random Forest teve melhor desempenho.

O ponto mais importante é que a acurácia sozinha não foi suficiente. Em uma base médica, é necessário observar se o modelo consegue identificar corretamente tanto os pacientes doentes quanto os saudáveis.

---

## Limitações

As principais limitações foram:

- a base é pequena;
- as classes são desbalanceadas;
- há menor quantidade de pacientes mulheres;
- os resultados podem variar conforme a divisão treino/teste;
- não houve validação externa;
- o modelo não substitui diagnóstico médico.

---

## Conclusão

A análise mostrou que a base ILPD exige cuidado na escolha dos modelos e das métricas.

O melhor resultado geral apareceu no cenário masculino com Random Forest. Na base completa, a Regressão Logística foi escolhida por apresentar melhor equilíbrio entre as métricas.

Portanto, a principal conclusão é que, em bases médicas desbalanceadas, o melhor modelo não deve ser escolhido apenas pela acurácia. É necessário considerar sensibilidade, especificidade, F1-score e AUC para entender melhor o comportamento do modelo.
