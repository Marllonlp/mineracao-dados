# Gallstone Disease Prediction — Predição de Cálculo Biliar

## Objetivo do trabalho

O objetivo deste trabalho foi prever a presença de cálculo biliar a partir de variáveis clínicas, laboratoriais e de composição corporal.

A análise não se limitou a treinar modelos. A principal pergunta foi:

> É realmente necessário usar um painel fixo de 10 variáveis ou existe uma combinação mais adequada?

Por isso, o estudo comparou diferentes painéis de variáveis e avaliou o equilíbrio entre desempenho, estabilidade, custo de coleta e plausibilidade clínica.

## Base de dados

A base utilizada foi a **Gallstone Disease Prediction**, disponível no UCI Machine Learning Repository.

| Informação | Valor |
|---|---:|
| Registros | 319 |
| Variáveis preditoras | 38 |
| Variável-alvo | Gallstone |
| Tipo de problema | Classificação supervisionada |

A variável-alvo indica se o paciente possui ou não cálculo biliar.

## Metodologia

A análise seguiu estas etapas:

1. leitura e validação da base;
2. análise exploratória das variáveis;
3. avaliação da relevância univariada;
4. verificação de redundância entre variáveis;
5. criação de painéis candidatos;
6. comparação dos painéis por validação cruzada;
7. escolha do painel recomendado;
8. avaliação de diferentes modelos de classificação.

Foram comparados quatro tipos de painel:

| Painel | Descrição |
|---|---|
| `full_38` | Usa todas as 38 variáveis |
| `raw_top_k` | Usa as variáveis mais importantes pelo ranking bruto |
| `pruned_top_k` | Usa variáveis importantes após remover redundância |
| `raw_top_10` | Painel de referência com 10 variáveis |

## Métricas utilizadas

As principais métricas avaliadas foram:

| Métrica | Interpretação |
|---|---|
| Acurácia | Percentual geral de acertos |
| Sensibilidade | Capacidade de identificar pacientes com cálculo biliar |
| Especificidade | Capacidade de identificar pacientes sem cálculo biliar |
| F1-score | Equilíbrio entre precisão e sensibilidade |
| AUC | Capacidade geral de separação entre as classes |

Neste problema, a sensibilidade é especialmente importante, porque o modelo pode ser interpretado como apoio à triagem.

## Resultados principais

O painel recomendado foi o **pruned_top_11**, com 11 variáveis.

| Painel | Acurácia | Sensibilidade | F1-score | AUC | Nº de variáveis | Custo |
|---|---:|---:|---:|---:|---:|---:|
| `pruned_top_11` | 74,41% | 81,60% | 75,22% | 87,04% | 11 | 10,0 |

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

## Comparação com o painel de 10 variáveis

O painel de referência era o `raw_top_10`, com 10 variáveis.

| Painel | Acurácia | Sensibilidade | F1-score | AUC |
|---|---:|---:|---:|---:|
| `raw_top_10` | 71,16% | 74,13% | 70,03% | 86,78% |
| `pruned_top_11` | 74,41% | 81,60% | 75,22% | 87,04% |

O painel `pruned_top_11` apresentou melhor equilíbrio geral. Assim, a conclusão foi que usar exatamente 10 variáveis não era a melhor decisão para esta base.

## Arquivos principais

| Arquivo ou pasta | Conteúdo |
|---|---|
| `gallstone.csv` | Base de dados usada na análise |
| `analise_gallstone.R` | Script principal da análise |
| `relatorio_gallstone.Rmd` | Fonte do relatório |
| `relatorio_gallstone.pdf` | Relatório final em PDF |
| `graficos/` | Figuras geradas durante a análise |
| `resultados/` | Tabelas e objetos de apoio |
| `tests/` | Testes automatizados do script |

## Conclusão

O melhor resultado não veio do menor número de variáveis, mas do equilíbrio entre desempenho estatístico, custo de coleta, estabilidade e sentido clínico.

O painel `pruned_top_11` deve ser interpretado como ferramenta de apoio à triagem, não como substituto de avaliação médica especializada.
