# Predição de Risco de Consumo de Drogas

## Autores
- Eduardo Rodrigues da Silva
- Otávio de Queiroz Franco
- Marlon Neves da Mota

## Descrição do Projeto
Este projeto tem como objetivo realizar a predição de risco de consumo de diversas drogas com base na base de dados `UCI Drug Consumption (Quantified)`. A nossa análise tenta superar as métricas do artigo base (`DrugConsumption.pdf`) lidando de forma extensiva com o problema do desbalanceamento dos dados através da técnica de oversampling (SMOTE, ADASYN) e modelos balanceados com pesos, comparando os resultados da "Nossa Análise" com um modelo treinado através dos **dados brutos** (sem balanceamento) e um "Baseline" simulando a abordagem descrita no artigo original.

## Instruções de Execução

1. **Pré-requisitos**:
   - É necessário ter o **R** instalado em sua máquina (versão recomendada: 4.1.0 ou superior).
   - É necessário ter o **Pandoc** instalado para que a geração do relatório HTML (a partir do `.Rmd`) aconteça com sucesso (ex no Ubuntu: `sudo apt install pandoc`).
   - Conexão com a internet para que o script baixe automaticamente os pacotes e a base de dados se necessário.

2. **Como Executar**:
   - Abra o terminal na pasta raiz do projeto (onde se encontra o arquivo `analise_drug_consumption.R`).
   - Execute o script principal utilizando o seguinte comando:
     ```bash
     Rscript analise_drug_consumption.R
     ```
   
   O script automaticamente:
   - Checará se os pacotes necessários estão instalados e os instalará usando um condicional, caso não estejam.
   - Baixará a base de dados `drug_consumption.data` da UCI.
   - Executará todo o pipeline de treinamento, avaliando as métricas, os modelos com e sem balanceamento de dados.
   - Irá exportar as tabelas para a pasta `/tables` e os gráficos para `/figures`.
   - Renderizará o arquivo `relatorio_drug_consumption.Rmd` em um arquivo final `.html`.

## Estrutura de Arquivos
- `analise_drug_consumption.R`: Script principal comentado e com a execução da pipeline completa.
- `relatorio_drug_consumption.Rmd`: Relatório R Markdown contendo todas as análises explicativas, vantagens da análise e gráficos obrigatórios comparativos (Acurácia, Sensitividade, Especificidade e Dados Brutos vs Balanceado).
- `data/`: Pasta contendo a base de dados e a tabela extraída do artigo base.
- `figures/`: Gráficos gerados.
- `tables/`: Tabelas com as métricas geradas.
- `output/`: Arquivos `.rds` com os resultados serializados.
