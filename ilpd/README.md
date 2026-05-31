# ILPD — Predição de Doença Hepática

## Objetivo do trabalho

O objetivo deste trabalho foi aplicar técnicas de mineração de dados na base **Indian Liver Patient Dataset — ILPD**, buscando prever se um paciente apresenta ou não doença hepática.

A análise comparou diferentes modelos de classificação, tratou o desbalanceamento das classes e avaliou os resultados usando métricas além da acurácia.

## Base de dados

A base utilizada foi a **Indian Liver Patient Dataset — ILPD**.

Ela contém registros de pacientes com variáveis demográficas e bioquímicas relacionadas à função hepática.

Resumo da base:

| Informação | Valor |
|---|---:|
| Total de registros | 583 |
| Total de colunas | 11 |
| Pacientes doentes | 416 |
| Pacientes saudáveis | 167 |
| Percentual de doentes | 71,36% |
| Percentual de saudáveis | 28,64% |

A variável alvo original foi convertida para duas classes mais interpretáveis:

| Valor original | Classe usada |
|---|---|
| 1 | Doente |
| 2 | Saudável |

## Variáveis utilizadas

As principais variáveis analisadas foram:

- Age;
- Gender;
- Total_Bilirubin;
- Direct_Bilirubin;
- Alkaline_Phosphatase;
- Alamine_Aminotransferase;
- Aspartate_Aminotransferase;
- Total_Proteins;
- Albumin;
- Albumin_and_Globulin_Ratio;
- Selector.

A variável **Albumin_and_Globulin_Ratio** apresentou 4 valores ausentes, que foram tratados por imputação pela mediana dentro do fluxo de treinamento.

## Problema analisado

O problema trabalhado foi de **classificação supervisionada**.

A pergunta principal foi:

> Com base em características demográficas e bioquímicas, é possível prever se um paciente possui doença hepática?

Esse tipo de análise pode ser usado como apoio à triagem, ajudando a identificar padrões associados à presença de doença hepática.

## Desafio da base

O principal desafio foi o **desbalanceamento das classes**.

A maioria dos registros pertence à classe de pacientes doentes. Isso significa que um modelo poderia parecer bom apenas por prever muitos pacientes como doentes.

Por isso, a acurácia sozinha não foi suficiente. Foram avaliadas também sensitividade, especificidade, F1-score e AUC.

## Metodologia

As principais etapas realizadas foram:

1. Carregamento da base;
2. Renomeação das colunas;
3. Conversão da variável `Gender` para fator;
4. Conversão da variável alvo para as classes Doente e Saudável;
5. Verificação de valores ausentes;
6. Separação estratificada entre treino e teste;
7. Validação cruzada estratificada com 10 folds;
8. Tratamento do desbalanceamento com upsampling;
9. Imputação por mediana;
10. Centralização e padronização dos dados;
11. Treinamento dos modelos;
12. Avaliação final no conjunto de teste.

## Cenários avaliados

A análise foi feita em três cenários:

| Cenário | Descrição |
|---|---|
| Base completa | Todos os pacientes |
| Homens | Apenas pacientes do sexo masculino |
| Mulheres | Apenas pacientes do sexo feminino |

Essa divisão permitiu verificar se os modelos se comportavam de forma diferente dependendo do grupo analisado.

## Modelos testados

Foram comparados diferentes modelos de classificação:

| Modelo | Tipo |
|---|---|
| Regressão Logística | Modelo linear |
| Random Forest | Modelo baseado em árvores |
| SVM Radial | Máquina de vetores de suporte |
| Naive Bayes | Modelo probabilístico |
| XGBoost | Modelo baseado em boosting |

## Métricas utilizadas

As principais métricas avaliadas foram:

| Métrica | O que indica |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensitividade | Capacidade de identificar pacientes doentes |
| Especificidade | Capacidade de identificar pacientes saudáveis |
| Precisão | Proporção de previsões positivas corretas |
| Recall | Mesmo conceito da sensitividade |
| F1-score | Equilíbrio entre precisão e recall |
| AUC | Capacidade geral de separação entre as classes |

## Resultados principais

A tabela abaixo mostra os principais resultados obtidos:

| Cenário | Melhor modelo | Acurácia | Sensitividade | Especificidade | F1-score | AUC |
|---|---|---:|---:|---:|---:|---:|
| Base completa | Regressão Logística | 68,4% | 62,1% | 84,0% | 73,7% | 76,8% |
| Homens | Random Forest | 75,0% | 82,5% | 54,3% | 82,9% | 82,2% |
| Mulheres | Random Forest | 59,5% | 63,0% | 53,3% | 66,7% | 66,4% |

## Resultado na base completa

Na base completa, o melhor modelo pelo critério composto foi a **Regressão Logística**.

| Modelo | Acurácia | Sensitividade | Especificidade | F1-score | AUC |
|---|---:|---:|---:|---:|---:|
| Random Forest | 73,0% | 83,1% | 48,0% | 81,4% | 78,0% |
| Regressão Logística | 68,4% | 62,1% | 84,0% | 73,7% | 76,8% |
| SVM Radial | 66,1% | 66,1% | 66,0% | 73,5% | 74,5% |
| Naive Bayes | 64,9% | 58,9% | 80,0% | 70,5% | 72,3% |

Embora o Random Forest tenha maior acurácia e sensitividade, a Regressão Logística foi escolhida pelo critério composto porque apresentou melhor equilíbrio geral, principalmente com maior especificidade.

## Resultado no cenário masculino

No cenário com apenas pacientes homens, o melhor modelo foi o **Random Forest**.

| Modelo | Acurácia | Sensitividade | Especificidade | F1-score | AUC |
|---|---:|---:|---:|---:|---:|
| Random Forest | 75,0% | 82,5% | 54,3% | 82,9% | 82,2% |
| SVM Radial | 68,9% | 63,9% | 82,9% | 75,1% | 78,3% |
| Regressão Logística | 63,6% | 56,7% | 82,9% | 69,6% | 75,2% |
| Naive Bayes | 48,5% | 32,0% | 94,3% | 47,7% | 73,0% |

Esse foi o melhor cenário geral da análise, com maior score composto.

## Resultado no cenário feminino

No cenário com apenas pacientes mulheres, o melhor modelo também foi o **Random Forest**.

| Modelo | Acurácia | Sensitividade | Especificidade | F1-score | AUC |
|---|---:|---:|---:|---:|---:|
| Random Forest | 59,5% | 63,0% | 53,3% | 66,7% | 66,4% |
| SVM Radial | 54,8% | 51,8% | 60,0% | 59,6% | 66,2% |
| Regressão Logística | 50,0% | 37,0% | 73,3% | 48,8% | 65,7% |
| Naive Bayes | 50,0% | 25,9% | 93,3% | 40,0% | 38,0% |

Esse foi o cenário mais fraco, provavelmente porque o subconjunto feminino era menor, tornando o treinamento mais instável.

## Comparação com o artigo

O artigo de referência apresentou acurácias próximas de 71% a 76%, dependendo do cenário e do modelo utilizado.

Neste projeto, os resultados de acurácia ficaram abaixo do artigo, mas a análise foi mais completa porque avaliou várias métricas, tratou o desbalanceamento e comparou diferentes cenários.

| Cenário | Melhor acurácia do artigo | Melhor acurácia do projeto | Houve melhoria em acurácia? |
|---|---:|---:|---|
| Base completa | 75,3% | 68,4% | Não |
| Homens | 76,5% | 75,0% | Não |
| Mulheres | 71,4% | 59,5% | Não |

Mesmo sem superar o artigo em acurácia, a análise deixou claro que escolher modelo apenas por acurácia pode ser inadequado em uma base médica desbalanceada.

## Interpretação dos resultados

A principal interpretação é que o melhor modelo depende do cenário analisado.

Na base completa, a Regressão Logística teve melhor equilíbrio pelo score geral. Para homens e mulheres, o Random Forest teve melhor desempenho.

O cenário masculino apresentou o melhor resultado geral, enquanto o cenário feminino teve desempenho mais limitado por causa da menor quantidade de registros.

## Limitações

As principais limitações foram:

- base pequena;
- classes desbalanceadas;
- menor quantidade de pacientes mulheres;
- resultados sensíveis à divisão treino/teste;
- ausência de validação externa;
- o modelo não substitui diagnóstico médico.

## Conclusão

A análise mostrou que a base ILPD exige cuidado na escolha dos modelos e das métricas.

Acurácia sozinha não foi suficiente para avaliar o desempenho, porque o problema envolve saúde e classes desbalanceadas.

A melhor abordagem foi comparar os modelos usando múltiplas métricas, principalmente sensitividade, especificidade, F1-score e AUC.

O melhor resultado geral apareceu no cenário masculino com Random Forest, enquanto na base completa a Regressão Logística teve melhor equilíbrio pelo critério composto.

## Como explicar na apresentação

Nesta base, o objetivo foi prever doença hepática usando dados demográficos e bioquímicos dos pacientes.

O principal desafio foi o desbalanceamento, porque havia muito mais pacientes doentes do que saudáveis. Por isso, a análise não usou apenas acurácia.

Foram testados modelos como Regressão Logística, Random Forest, SVM Radial e Naive Bayes. A base foi analisada em três cenários: completa, homens e mulheres.

Na base completa, o melhor modelo pelo critério composto foi a Regressão Logística. No cenário masculino e feminino, o melhor modelo foi o Random Forest.

A conclusão principal é que, em bases médicas, o modelo precisa equilibrar a identificação de pacientes doentes com a capacidade de reconhecer pacientes saudáveis.