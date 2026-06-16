# Cream Cheese — Mineração de Dados Sensorial

## Objetivo do trabalho

O objetivo deste trabalho foi analisar dados sensoriais de cream cheese para identificar padrões associados à percepção de cremosidade.

A análise buscou responder três perguntas principais:

- quais atributos diferenciam os produtos;
- quais características estão mais associadas à cremosidade;
- quais produtos formam perfis sensoriais semelhantes.

## Base de dados

A base utilizada é a **Creaminess of Cream Cheese**, com dados de perfil sensorial. O conjunto contém avaliações de produtos por provadores em diferentes réplicas.

| Informação | Valor |
|---|---:|
| Observações | 240 |
| Variáveis originais | 29 |
| Produtos | 10 |
| Provadores | 8 |
| Réplicas | 3 |
| Atributos sensoriais analisados | 23 |
| Valores ausentes | 0 |

A variável central da análise foi `MCreaminess`, que representa a cremosidade percebida na boca.

## Metodologia

A análise seguiu estas etapas:

1. leitura da base em formato SPSS;
2. validação da estrutura dos dados;
3. análise de diferenças sensoriais entre produtos;
4. correlações com a variável `MCreaminess`;
5. ranking dos produtos por cremosidade média;
6. segmentação por agrupamento hierárquico;
7. análise de componentes principais;
8. regras simples para alta cremosidade;
9. avaliação de efeitos de controle, como produto, provador, sessão e ordem de serviço.

## Técnicas utilizadas

As principais técnicas foram:

| Técnica | Finalidade |
|---|---|
| ANOVA | Verificar quais atributos diferenciam os produtos |
| Correlação | Medir associação entre atributos e cremosidade |
| Regressão linear | Avaliar contribuição conjunta de atributos sensoriais |
| Clusterização hierárquica | Agrupar produtos com perfis semelhantes |
| PCA | Resumir a paisagem sensorial em poucos eixos |
| Árvore de decisão | Interpretar regras simples associadas à cremosidade |

## Resultados principais

A análise mostrou que os produtos possuem assinaturas sensoriais próprias. Em especial:

- 18 dos 23 atributos apresentaram efeito de produto com `p < 0,05`;
- `MCreaminess` teve correlação positiva com `MFat`, `MButter`, `MSweet`, `MSalt` e `MCream`;
- `MCreaminess` teve correlação negativa com `MChalky`, `NOldmilk`, `EGrainy`, `MGrainy` e `MSour`;
- o modelo linear exploratório com os atributos mais correlacionados atingiu R² ajustado de 0,264;
- a segmentação separou os produtos em três grupos sensoriais principais.

O produto com maior média de cremosidade foi o **04 - D-CH**, enquanto produtos com maior percepção farinácea ou granulada tenderam a apresentar menor cremosidade.

## Interpretação

A cremosidade percebida parece estar mais próxima de uma experiência sensorial gordurosa, amanteigada e lisa. Por outro lado, atributos farináceos, granulados ou associados a leite envelhecido aparecem como sinais negativos.

Esse resultado é útil para posicionamento sensorial, controle de qualidade e comparação entre formulações. Ainda assim, a análise deve ser interpretada como exploratória, pois correlação não implica causalidade.

## Arquivos principais

| Arquivo ou pasta | Conteúdo |
|---|---|
| `SPSS_CreamCheese.zip` | Base original em formato SPSS |
| `cheese.xls` | Base em formato Excel |
| `cream_cheese_mining.R` | Script principal da análise |
| `relatorio_cream_cheese.Rmd` | Fonte do relatório |
| `relatorio_cream_cheese.pdf` | Relatório final em PDF |
| `cream_cheese_outputs/figures/` | Figuras geradas pela análise |
| `cream_cheese_outputs/tables/` | Tabelas de apoio |

## Conclusão

A mineração dos dados sensoriais indicou que a cremosidade é influenciada por um conjunto coerente de atributos ligados a gordura, textura lisa e menor percepção farinácea.

O trabalho também mostrou que os produtos podem ser organizados em segmentos sensoriais úteis para comparação, formulação e controle de qualidade.
