# InterDIA — Previsão de Autoimunidade Induzida por Fármacos

## Objetivo do trabalho

O objetivo deste trabalho foi aplicar técnicas de mineração de dados para prever se determinados compostos químicos apresentam risco de causar autoimunidade induzida por fármacos.

A análise utiliza descritores moleculares dos compostos e verifica se esses padrões químicos ajudam a identificar maior risco de respostas autoimunes.

## Base de dados

A base foi disponibilizada no UCI Machine Learning Repository. Ela contém compostos químicos representados por descritores moleculares, com classificação indicando associação ou não com autoimunidade induzida por fármacos.

| Conjunto | Total | Positivos | Negativos | Taxa de positivos |
|---|---:|---:|---:|---:|
| Treino | 477 | 118 | 359 | 24,7% |
| Teste | 120 | 30 | 90 | 25,0% |

Foram utilizados os mesmos 65 descritores moleculares publicados no artigo de referência.

## Problema analisado

O problema é de **classificação supervisionada**.

A pergunta principal foi:

> Com base nos descritores moleculares de um composto, é possível prever se ele apresenta risco de autoimunidade induzida por fármacos?

Esse tipo de análise pode ser útil em etapas iniciais do desenvolvimento de medicamentos, ajudando a identificar compostos que exigem atenção antes de avançarem para fases posteriores.

## Metodologia

As principais etapas foram:

1. carregamento da base oficial;
2. separação entre treino e teste externo;
3. uso do subconjunto de 65 descritores moleculares;
4. treinamento de diferentes modelos;
5. escolha do limiar de classificação com base no treino;
6. avaliação final no conjunto de teste externo;
7. análise dos descritores mais importantes;
8. comparação com o benchmark publicado.

## Modelos avaliados

Foram comparados três modelos principais:

| Modelo | Função na análise |
|---|---|
| Elastic Net | Modelo linear usado como baseline |
| Weighted Ranger | Floresta aleatória ponderada |
| EasyEnsemble Screening | Modelo principal para triagem em base desbalanceada |

O modelo escolhido como principal foi o **EasyEnsemble Screening**.

## Métricas utilizadas

As principais métricas avaliadas foram:

| Métrica | O que indica |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensibilidade | Capacidade de identificar compostos positivos |
| Especificidade | Capacidade de identificar compostos negativos |
| Precisão | Proporção de positivos previstos corretamente |
| F1-score | Equilíbrio entre precisão e sensibilidade |
| MCC | Qualidade geral da classificação em base desbalanceada |
| AUC | Capacidade geral de separação entre as classes |

## Resultados principais

No teste externo, o modelo **EasyEnsemble Screening** apresentou o melhor desempenho geral.

| Modelo | Acurácia | Sensibilidade | Especificidade | F1-score | MCC | AUC |
|---|---:|---:|---:|---:|---:|---:|
| EasyEnsemble Screening | 0,808 | 0,900 | 0,778 | 0,701 | 0,601 | 0,897 |
| Weighted Ranger | 0,758 | 0,833 | 0,733 | 0,633 | 0,499 | 0,883 |
| Elastic Net | 0,250 | 0,933 | 0,022 | 0,384 | -0,107 | 0,560 |

O limiar final escolhido para o modelo principal foi **0,49**, priorizando boa sensibilidade sem eliminar a especificidade.

## Arquivos principais

| Arquivo ou pasta | Conteúdo |
|---|---|
| `data/raw/` | Arquivos brutos e descritores moleculares |
| `interdia_analysis.R` | Script reprodutível da análise |
| `interdia_report.Rmd` | Fonte do relatório |
| `interdia_report.pdf` | Relatório final em PDF |
| `outputs/figures/` | Figuras geradas pelo pipeline |
| `outputs/tables/` | Tabelas de resultados |
| `outputs/results/` | Objeto de apoio usado pelo relatório |

## Conclusão

O modelo **EasyEnsemble Screening** foi o mais adequado para prever risco de autoimunidade induzida por fármacos.

O principal ponto do trabalho foi mostrar que, em bases desbalanceadas e ligadas à segurança, o melhor modelo não deve ser escolhido apenas pela acurácia. Métricas como sensibilidade, especificidade, MCC e AUC são essenciais para avaliar se o modelo realmente ajuda em uma situação prática de triagem toxicológica.
