# Apresentação Final — Temática em Mineração de Dados

## Tema geral

Esta apresentação reúne os trabalhos desenvolvidos na disciplina de **Temática em Mineração de Dados**, com foco na aplicação de técnicas de análise de dados, pré-processamento, classificação, avaliação de modelos e interpretação de resultados.

O objetivo principal não é apresentar código, mas sim explicar:

- qual era o problema de cada base;
- como os dados foram preparados;
- quais modelos ou estratégias foram usados;
- quais métricas foram consideradas;
- quais resultados foram obtidos;
- quais conclusões podem ser tiradas a partir da análise.

---

## Organização dos trabalhos

Os trabalhos estão organizados por pastas no repositório. Este README reúne uma visão geral das bases analisadas, das metodologias usadas e dos principais resultados.

Cada trabalho possui sua própria pasta com os arquivos da análise, relatório e README individual.

---

# Estrutura em 3 partes

## Parte 1 — Introdução geral e metodologia comum

### Metodologia comum

Os trabalhos analisam bases de dados diferentes, mas todos seguem uma lógica parecida:

1. entendimento do problema;
2. análise inicial da base;
3. identificação da variável-alvo;
4. tratamento dos dados;
5. aplicação de modelos ou estratégias de classificação;
6. avaliação por métricas;
7. comparação dos resultados;
8. conclusão sobre o melhor modelo ou melhor abordagem.

### Contexto geral

A mineração de dados permite extrair padrões úteis a partir de bases reais. Nos trabalhos apresentados, foram analisadas bases ligadas a crédito, saúde, toxicologia, comportamento de consumo e análise sensorial.

Em todos os casos, a escolha do melhor modelo não foi feita apenas pela acurácia. Também foram consideradas métricas como sensibilidade, especificidade, F1-score, AUC, MCC e acurácia balanceada, dependendo do problema.

Isso é importante porque várias bases são desbalanceadas. Quando uma classe aparece muito mais do que a outra, a acurácia pode enganar. Por exemplo, um modelo pode ter boa acurácia geral, mas falhar justamente na classe mais importante.

### Métricas usadas nos trabalhos

| Métrica | O que indica |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensibilidade | Capacidade de identificar corretamente os casos positivos |
| Especificidade | Capacidade de identificar corretamente os casos negativos |
| Precisão | Proporção de previsões positivas que realmente estavam corretas |
| F1-score | Equilíbrio entre precisão e sensibilidade |
| AUC | Capacidade geral de separação entre as classes |
| MCC | Medida equilibrada para bases desbalanceadas |
| Acurácia balanceada | Média entre sensibilidade e especificidade |

# Parte 2 — Trabalhos individuais

Os trabalhos individuais foram organizados a partir dos seguintes pontos:

1. base de dados;
2. objetivo;
3. estratégia usada;
4. principais métricas;
5. principais resultados;
6. conclusão.

---

## 1. Base do Cartão de Crédito

### Problema

A base de cartão de crédito tem como objetivo prever a inadimplência de clientes, ou seja, identificar quais clientes possuem maior risco de não pagar a fatura no mês seguinte.

A base utilizada foi a **Default of Credit Card Clients**, com dados de clientes de Taiwan. O problema é uma tarefa de classificação binária:

- **Pagador**
- **Devedor**

### Estratégia usada

A análise utilizou Random Forest como modelo principal e aplicou melhorias em relação ao artigo de referência.

As principais melhorias foram:

- criação de novas variáveis por engenharia de atributos;
- seleção de variáveis com RFE;
- balanceamento da classe minoritária com SMOTE;
- aumento do número de árvores do Random Forest;
- ajuste do limiar de decisão.

### Principais resultados

O modelo final manteve AUC de **0,753**.

O cenário recomendado foi o limiar **0,38**, pois aumentou a sensibilidade de **37,53% para 45,21%**, mantendo a especificidade acima de **90%**.

### Conclusão

A análise foi mais útil do ponto de vista prático porque priorizou a identificação de devedores. Em risco de crédito, detectar clientes com risco de inadimplência é mais importante do que apenas manter uma acurácia geral alta.

---

## 2. InterDIA

### Problema

O trabalho InterDIA está relacionado à previsão de risco de autoimunidade induzida por fármacos. O objetivo é avaliar se compostos químicos apresentam sinais compatíveis com maior risco de desencadear respostas autoimunes.

A tarefa também é uma classificação binária:

- composto positivo para risco;
- composto negativo para risco.

### Estratégia usada

A análise manteve o desenho científico do artigo, mas criou uma versão mais portável e reprodutível em R.

Foram comparados três modelos principais:

- Elastic Net;
- Weighted Ranger;
- EasyEnsemble Screening.

A escolha do limiar não foi feita de forma fixa em 0,50. O limiar foi escolhido no treino, buscando alta sensibilidade, porque nesse tipo de problema é mais grave deixar passar um composto potencialmente perigoso.

### Principais resultados

O modelo principal escolhido foi o **EasyEnsemble Screening**.

No teste externo, ele obteve:

| Métrica | Resultado |
|---|---:|
| Acurácia | 80,8% |
| Sensibilidade | 90,0% |
| Especificidade | 77,8% |
| F1-score | 70,1% |
| MCC | 0,601 |
| AUC | 0,897 |

### Conclusão

O InterDIA foi forte porque combinou boa capacidade de separação, alta sensibilidade e avaliação honesta no conjunto de teste externo. Além disso, o pipeline ficou reprodutível e adequado para apresentação acadêmica.

---

## 3. Drug Consumption

### Problema

A base Drug Consumption busca prever o consumo de diferentes substâncias a partir de características dos respondentes.

A classificação foi feita considerando:

- **Não usuário**: classes CL0 e CL1;
- **Usuário**: classes CL2 a CL6.

A análise foi feita droga por droga, porque cada substância possui distribuição e dificuldade diferente.

### Estratégia usada

A análise comparou várias abordagens, em vez de usar apenas um modelo fixo.

Foram utilizadas estratégias como:

- Random Forest;
- glmnet;
- C5.0;
- pesos de classe;
- SMOTE;
- ADASYN;
- ensembles simples;
- ajuste de limiar por droga.

Também foram usadas meta-features de risco inspiradas no artigo original.

### Principais resultados

Na média geral, a análise proposta obteve:

| Abordagem | Acurácia | Sensibilidade | Especificidade | F1 | Acurácia balanceada | ROC | PR |
|---|---:|---:|---:|---:|---:|---:|---:|
| Nossa análise | 72,86% | 72,56% | 72,66% | 62,22% | 72,61% | 79,32% | 63,08% |
| Baseline RF | 81,52% | 59,70% | 68,78% | 60,26% | - | - | - |
| Artigo | 81,60% | 59,89% | 69,20% | 61,97% | - | - | - |

### Conclusão

Mesmo com acurácia média menor que o artigo, a análise proposta foi mais equilibrada, principalmente porque aumentou a sensibilidade e a especificidade de forma mais justa.

Nesse problema, olhar apenas para acurácia seria limitado, pois algumas drogas possuem classes muito desbalanceadas.

---

## 4. Gallstone Disease Prediction

### Problema

A base Gallstone Disease Prediction tem como objetivo prever a presença de cálculo biliar a partir de variáveis clínicas, laboratoriais e de composição corporal.

A pergunta principal do trabalho foi:

**é realmente necessário usar um painel fixo de 10 variáveis ou existe uma combinação melhor?**

### Estratégia usada

A análise comparou diferentes painéis de variáveis:

- painel com todas as variáveis;
- painéis com as principais variáveis ranqueadas;
- painéis podados por redundância;
- painel de referência com 10 variáveis.

A escolha do melhor painel considerou:

- desempenho;
- estabilidade;
- número de variáveis;
- custo operacional;
- plausibilidade clínica.

### Principais resultados

O painel recomendado foi o **pruned_top_11**, com 11 variáveis.

Esse painel apresentou melhor equilíbrio entre desempenho médio, estabilidade e custo-benefício do que assumir um corte fixo de 10 variáveis.

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

### Conclusão

A análise mostrou que o melhor resultado não vem necessariamente do menor número de variáveis, mas sim do equilíbrio entre desempenho estatístico, custo de coleta e sentido clínico.

O painel recomendado deve ser interpretado como ferramenta de triagem, não como substituto de avaliação médica especializada.

---

## 5. Indian Liver Patient Dataset — ILPD

### Problema

O ILPD é uma base relacionada à identificação de doença hepática. O objetivo é classificar pacientes como:

- **Doente**
- **Saudável**

A base possui 583 registros e é desbalanceada, com maior quantidade de pacientes doentes.

### Estratégia usada

A análise comparou diferentes modelos de classificação:

- Regressão Logística;
- Random Forest;
- SVM Radial;
- Naive Bayes;
- XGBoost.

A análise foi feita em três cenários:

1. base completa;
2. apenas pacientes homens;
3. apenas pacientes mulheres.

Foram usados tratamento de valores ausentes, padronização, validação cruzada, upsampling e avaliação final no conjunto de teste.

### Principais resultados

Os melhores modelos por cenário foram:

| Cenário | Melhor modelo | Acurácia | Sensibilidade | Especificidade | F1 | AUC |
|---|---|---:|---:|---:|---:|---:|
| Base completa | Regressão Logística | 68,4% | 62,1% | 84,0% | 73,7% | 76,8% |
| Homens | Random Forest | 75,0% | 82,5% | 54,3% | 82,9% | 82,2% |
| Mulheres | Random Forest | 59,5% | 63,0% | 53,3% | 66,7% | 66,4% |

### Conclusão

A análise mostrou que a escolha do melhor modelo depende do cenário. Acurácia sozinha não foi suficiente, porque a base é desbalanceada e envolve um problema de saúde.

Por isso, a avaliação considerou sensibilidade, especificidade, F1-score e AUC.

---

## 6. Cream Cheese

### Problema

A base Cream Cheese reúne avaliações sensoriais de diferentes produtos de cream cheese. O objetivo é identificar quais atributos diferenciam os produtos e quais características estão mais associadas à cremosidade percebida.

A variável central da análise foi:

- **MCreaminess**

### Estratégia usada

A análise combinou técnicas exploratórias e modelos interpretáveis para entender o perfil sensorial dos produtos.

Foram utilizadas estratégias como:

- ANOVA para comparar atributos entre produtos;
- correlações com a cremosidade;
- ranking médio por produto;
- clusterização hierárquica;
- PCA;
- árvore de decisão para regras simples de interpretação.

### Principais resultados

A análise mostrou que 18 dos 23 atributos sensoriais diferenciam os produtos de forma estatisticamente detectável.

Os atributos mais associados positivamente à cremosidade foram ligados a gordura, manteiga, doçura, sal e creme. Já atributos como farináceo, granulado, azedo e leite envelhecido tiveram associação negativa com a cremosidade.

O produto com maior média de cremosidade foi o **04 - D-CH**.

### Conclusão

A base mostrou que a percepção de cremosidade está ligada a um perfil sensorial gorduroso, amanteigado e mais liso. A análise também separou os produtos em grupos sensoriais úteis para comparação, formulação e controle de qualidade.

---

# Parte 3 — Comparação geral e fechamento

## Comparação entre os trabalhos

Apesar de cada base tratar de um problema diferente, todos os trabalhos mostram uma ideia em comum:

**em mineração de dados, o melhor modelo não é apenas aquele que tem maior acurácia, mas aquele que faz mais sentido para o problema.**

### Comparação geral

| Trabalho | Tipo de problema | Principal preocupação | Melhor estratégia |
|---|---|---|---|
| Cartão de Crédito | Risco financeiro | Detectar devedores | Random Forest com SMOTE e ajuste de limiar |
| InterDIA | Toxicologia | Alta sensibilidade para triagem | EasyEnsemble Screening |
| Drug Consumption | Comportamento de consumo | Equilíbrio por droga | Modelos diferentes por substância |
| Gallstone | Saúde / cálculo biliar | Custo-benefício das variáveis | Painel pruned_top_11 |
| ILPD | Saúde / doença hepática | Classes desbalanceadas | Escolha por cenário e múltiplas métricas |
| Cream Cheese | Análise sensorial | Entender atributos de cremosidade | ANOVA, correlação, PCA e clusterização |

---

## Principais aprendizados

A partir dos trabalhos, o grupo identificou alguns aprendizados importantes:

1. **Acurácia nem sempre é a melhor métrica.**  
   Em bases desbalanceadas, ela pode esconder erros importantes.

2. **Sensibilidade e especificidade precisam ser interpretadas conforme o problema.**  
   Em saúde e toxicologia, deixar passar um caso positivo pode ser mais grave.

3. **O limiar de decisão pode mudar bastante o resultado.**  
   Em vez de usar sempre 0,50, alguns trabalhos ajustaram o limiar conforme o objetivo.

4. **O pré-processamento influencia diretamente o desempenho.**  
   Tratamento de valores ausentes, balanceamento e padronização ajudam a tornar a comparação mais justa.

5. **Modelos diferentes podem funcionar melhor em cenários diferentes.**  
   Não existe um único algoritmo vencedor para todos os problemas.

6. **Interpretabilidade também importa.**  
   Em bases de saúde, crédito e toxicologia, é importante explicar por que o modelo chegou naquele resultado.

---

## Conclusão geral

Os trabalhos mostram que mineração de dados não se resume a aplicar um algoritmo. É necessário entender o problema, preparar corretamente os dados, escolher métricas adequadas e interpretar os resultados conforme o contexto.

Em vários casos, o modelo mais útil não foi simplesmente o de maior acurácia, mas aquele que apresentou melhor equilíbrio entre desempenho, sensibilidade, especificidade e aplicabilidade real.
