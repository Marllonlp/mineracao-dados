# Gallstone Disease Prediction - Predição de Cálculo Biliar

## Objetivo do trabalho

O objetivo deste trabalho foi prever a presença de cálculo biliar usando variáveis clínicas, laboratoriais e de composição corporal.

O ponto principal do trabalho não foi apenas treinar modelos. A pergunta mais importante foi:

> É realmente necessário usar um painel fixo de 10 variáveis ou existe uma combinação melhor?

Por isso, a análise comparou diferentes conjuntos de variáveis e avaliou qual deles entregava melhor equilíbrio entre desempenho, estabilidade, custo de coleta e sentido clínico.

---

## Base de dados

A base utilizada foi a **Gallstone Disease Prediction**, disponível no UCI Machine Learning Repository.

| Informação | Valor |
|---|---:|
| Registros | 319 |
| Variáveis preditoras | 38 |
| Variável alvo | Gallstone |
| Tipo de problema | Classificação supervisionada |

A variável alvo indica se o paciente possui ou não cálculo biliar.

---

## Resultado esperado

O resultado esperado era encontrar um painel de variáveis que não fosse grande demais, mas que ainda mantivesse bom desempenho.

Na prática, queríamos um conjunto que equilibrasse:

- boa capacidade de previsão;
- menor redundância entre variáveis;
- custo de coleta aceitável;
- estabilidade dos resultados;
- plausibilidade clínica.

Isso é importante porque usar muitas variáveis pode deixar o modelo mais caro, mais redundante e nem sempre melhora o resultado.

---

## Metodologia usada

A metodologia seguiu estas etapas principais:

1. análise inicial da base;
2. identificação da variável alvo;
3. análise da relevância das variáveis;
4. verificação de redundância entre variáveis;
5. criação de painéis candidatos;
6. comparação dos painéis;
7. escolha do painel recomendado;
8. teste com diferentes modelos de classificação;
9. avaliação por múltiplas métricas.

Foram comparados quatro tipos de painel:

| Painel | O que significa |
|---|---|
| full_38 | Usa todas as 38 variáveis |
| raw_top_k | Usa as variáveis mais importantes pelo ranking bruto |
| pruned_top_k | Usa variáveis importantes após remover redundância |
| raw_top_10 | Painel de referência com 10 variáveis |

A ideia foi verificar se o painel fixo de 10 variáveis realmente era a melhor escolha.

---

## Métricas usadas

As principais métricas foram:

| Métrica | Interpretação |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensibilidade | Capacidade de identificar pacientes com cálculo biliar |
| Especificidade | Capacidade de identificar pacientes sem cálculo biliar |
| F1-score | Equilíbrio entre precisão e sensibilidade |
| AUC | Capacidade geral de separação entre as classes |

Neste problema, a sensibilidade é muito importante, porque a base pode ser vista como apoio à triagem. Em triagem médica, é desejável identificar corretamente os casos positivos.

---

## Resultado principal

O painel recomendado foi o **pruned_top_11**, com 11 variáveis.

Esse painel teve melhor equilíbrio entre desempenho, custo-benefício e estabilidade do que assumir automaticamente um corte fixo de 10 variáveis.

| Painel | Acurácia | Sensibilidade | F1-score | AUC | Nº de variáveis | Custo |
|---|---:|---:|---:|---:|---:|---:|
| pruned_top_11 | 74,41% | 81,60% | 75,22% | 87,04% | 11 | 10,0 |

As variáveis recomendadas no cenário 80/20 foram:

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

---

## Comparação com o painel de 10 variáveis

O painel de referência era o **raw_top_10**, com 10 variáveis.

| Painel | Acurácia | Sensibilidade | F1-score | AUC |
|---|---:|---:|---:|---:|
| raw_top_10 | 71,16% | 74,13% | 70,03% | 86,78% |
| pruned_top_11 | 74,41% | 81,60% | 75,22% | 87,04% |

O painel **pruned_top_11** foi melhor em acurácia, sensibilidade e F1-score.

Então, a conclusão foi que usar exatamente 10 variáveis não era a melhor decisão para esta base. O painel com 11 variáveis teve melhor resultado e ainda manteve um custo aceitável.

---

## Modelos avaliados

Depois da escolha do painel, foram avaliados diferentes modelos de classificação:

- Regressão Logística;
- Random Forest;
- AdaBoost;
- Gradient Boosting;
- MLP;
- SVM Radial;
- Decision Tree;
- Naive Bayes;
- KNN.

No cenário 80/20, a Regressão Logística teve o melhor equilíbrio geral, enquanto o Random Forest apresentou a maior AUC.

| Modelo | Acurácia | Sensibilidade | Especificidade | F1-score | AUC |
|---|---:|---:|---:|---:|---:|
| Regressão Logística | 92,06% | 96,88% | 87,10% | 92,54% | 90,62% |
| Random Forest | 88,89% | 93,75% | 83,87% | 89,55% | 94,76% |
| Gradient Boosting | 84,13% | 84,38% | 83,87% | 84,38% | 90,73% |
| SVM Radial | 84,13% | 90,62% | 77,42% | 85,29% | 92,14% |

---

## Interpretação

O principal resultado foi que o melhor painel não foi simplesmente o menor painel.

O painel recomendado funcionou melhor porque conseguiu:

- reduzir redundância entre variáveis;
- manter boa capacidade de previsão;
- melhorar a sensibilidade;
- manter custo operacional aceitável;
- preservar sentido clínico.

Também é importante destacar que o modelo não deve ser interpretado como diagnóstico médico. Ele serve como apoio à triagem e à análise de padrões.

---

## Limitações

As principais limitações foram:

- a base é pequena;
- os dados vêm de um único centro;
- não houve validação externa;
- algumas variáveis de composição corporal são muito redundantes;
- o modelo não substitui exames clínicos ou exames de imagem.

---

## Conclusão

A principal conclusão é que não era ideal assumir automaticamente um corte fixo de 10 variáveis.

O painel **pruned_top_11** apresentou melhor equilíbrio entre desempenho, sensibilidade, estabilidade e custo-benefício.

Portanto, para esta base, um painel pequeno e bem selecionado foi mais útil do que simplesmente escolher um número fixo de variáveis.
