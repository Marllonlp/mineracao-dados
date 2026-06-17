# Análise de Dados do Indian Liver Patient Dataset - ILPD

Este projeto contém uma análise completa em R do **Indian Liver Patient Dataset (ILPD)**, com foco na predição de doença hepática a partir de variáveis demográficas e bioquímicas.

A análise foi construída com base no artigo **"Um Estudo sobre o Dataset Indian Liver Patient Dataset (ILPD)"** e busca melhorar a entrega original por meio de validação cruzada, tratamento do desbalanceamento, múltiplas métricas, gráficos, tabelas e comparação entre cenários.

## Estrutura do projeto

```text
ilpd_projeto/
├── analise_ilpd.R
├── relatorio_ilpd.Rmd
├── README.md
├── dados/
│   └── coloque_aqui_o_CSV_do_ILPD.csv
├── resultados/
│   └── arquivos CSV gerados pela análise
└── graficos/
    └── arquivos PNG gerados pela análise
```

## Base de dados

A base incluída em `dados/` contém o ILPD em formato CSV sem cabeçalho, conforme a estrutura original. O script renomeia automaticamente as colunas para:

1. `Age`
2. `Gender`
3. `Total_Bilirubin`
4. `Direct_Bilirubin`
5. `Alkaline_Phosphatase`
6. `Alamine_Aminotransferase`
7. `Aspartate_Aminotransferase`
8. `Total_Proteins`
9. `Albumin`
10. `Albumin_and_Globulin_Ratio`
11. `Selector`

A variável `Selector` é convertida para:

- `Doente`: pacientes com doença hepática;
- `Saudavel`: pacientes sem doença hepática.

## Pacotes utilizados

O script verifica automaticamente se os pacotes estão instalados. Caso algum pacote esteja ausente, ele será instalado automaticamente antes de ser carregado.

Principais pacotes utilizados:

- `tidyverse`
- `caret`
- `ranger`
- `e1071`
- `kernlab`
- `naivebayes`
- `xgboost`
- `pROC`
- `vip`
- `knitr`
- `kableExtra`
- `rmarkdown`

## Ordem correta de execução

Há apenas um script principal de análise.

### 1. Abrir o projeto no RStudio

Abra a pasta `ilpd_projeto/` no RStudio e confirme que o arquivo CSV está dentro da pasta `dados/`.

### 2. Executar o script principal

No console do RStudio, execute:

```r
source("analise_ilpd.R")
```

Esse comando irá:

- carregar e preparar a base ILPD;
- verificar e tratar valores ausentes no fluxo de modelagem;
- gerar análise exploratória;
- separar os dados em treino e teste com estratificação;
- treinar modelos com validação cruzada estratificada de 10 folds;
- aplicar balanceamento por upsampling dentro da validação cruzada;
- avaliar os modelos no conjunto de teste;
- calcular acurácia, sensitividade, especificidade, precisão, recall, F1 e AUC;
- gerar tabelas CSV na pasta `resultados/`;
- gerar gráficos PNG na pasta `graficos/`;
- repetir a análise para base completa, homens e mulheres;
- comparar os resultados com as acurácias aproximadas do artigo.

### 3. Gerar o relatório

Depois de executar o script, abra `relatorio_ilpd.Rmd` no RStudio e clique em **Knit**.

Também é possível executar:

```r
rmarkdown::render("relatorio_ilpd.Rmd")
```

Se o relatório for renderizado antes da execução do script, ele tentará executar `analise_ilpd.R` automaticamente para gerar os arquivos necessários.

## Modelos avaliados

O projeto testa os seguintes modelos:

- Regressão Logística;
- Random Forest;
- SVM com kernel radial;
- Naive Bayes;
- XGBoost.

## Cenários avaliados

A análise é repetida em três cenários:

1. base completa;
2. apenas pacientes homens;
3. apenas pacientes mulheres.

Nos cenários por gênero, a variável `Gender` é removida automaticamente quando fica constante, evitando problemas de modelagem.

## Estratégia contra vazamento de dados

Para evitar vazamento de dados, o conjunto de teste é separado antes da modelagem final. As etapas de imputação, padronização, remoção de variáveis de variância zero, balanceamento e ajuste de hiperparâmetros ocorrem dentro do fluxo de treinamento e validação cruzada.

O conjunto de teste é usado apenas para a avaliação final.

## Métricas geradas

A tabela comparativa final contém:

```text
Cenario | Modelo | Acuracia | Sensitividade | Especificidade | Precisao | Recall | F1 | AUC
```

Como a base é desbalanceada, a escolha do melhor modelo não se baseia apenas em acurácia. O script também calcula um `Score_Geral`, considerando acurácia, sensitividade, especificidade, F1-score e AUC.

## Principais arquivos gerados

Na pasta `resultados/`:

- `tabela_comparativa_final.csv`
- `metricas_todos_os_modelos.csv`
- `melhores_modelos_por_cenario.csv`
- `comparacao_com_artigo.csv`
- `resumo_estatistico.csv`
- `valores_ausentes.csv`
- `matriz_correlacao.csv`
- tabelas específicas por cenário

Na pasta `graficos/`:

- `distribuicao_classes.png`
- `distribuicao_genero.png`
- `distribuicao_variaveis_numericas.png`
- `matriz_correlacao.png`
- `acuracia_modelos_completa.png`
- `sensitividade_especificidade_completa.png`
- `curva_roc_melhores_modelos_completa.png`
- `importancia_variaveis_melhor_modelo_completa.png`
- gráficos equivalentes para homens e mulheres
- `comparacao_acuracia_artigo.png`

## Observações importantes

- Os resultados podem variar ligeiramente conforme a versão do R, dos pacotes e do sistema operacional.
- O script usa `set.seed(123)` para aumentar a reprodutibilidade.
- A instalação de pacotes como `xgboost` pode demorar na primeira execução.
- Caso algum modelo falhe por problema de instalação ou ambiente, o script registra a falha em arquivos de erro dentro de `resultados/` e continua executando os demais modelos.

## Objetivo acadêmico

Este projeto foi preparado para ser simples de executar, organizado e defensável em uma apresentação acadêmica. Ele valoriza a interpretação das métricas em um problema de saúde, especialmente porque falsos negativos e falsos positivos têm impactos diferentes na avaliação de pacientes com possível doença hepática.
