# Análise de Inadimplência em Cartão de Crédito

## Objetivo do trabalho

O objetivo deste trabalho foi aplicar técnicas de mineração de dados para prever a inadimplência de clientes de cartão de crédito.

A análise buscou identificar quais clientes tinham maior chance de se tornarem inadimplentes no mês seguinte, utilizando informações financeiras, histórico de pagamento e técnicas de aprendizado de máquina.

## Base de dados

A base utilizada foi a **Default of Credit Card Clients**, disponível no UCI Machine Learning Repository.

Ela contém dados de **30.000 clientes de cartão de crédito de Taiwan**, coletados em 2005. A base possui variáveis relacionadas a:

- limite de crédito;
- histórico de pagamento;
- valores das faturas;
- valores pagos;
- informações pessoais dos clientes;
- indicação se o cliente se tornou inadimplente no mês seguinte.

A variável principal analisada foi a inadimplência, ou seja, se o cliente pagou ou não sua obrigação no período seguinte.

## Problema analisado

O problema trabalhado foi de **classificação supervisionada**.

Isso significa que o modelo recebeu exemplos anteriores de clientes pagadores e inadimplentes para aprender padrões e tentar prever novos casos.

A pergunta principal foi:

> Com base no histórico financeiro do cliente, é possível prever se ele tem risco de inadimplência?

## Metodologia

A análise seguiu as seguintes etapas:

1. Carregamento da base de dados;
2. Remoção da coluna de identificação;
3. Tratamento de categorias inconsistentes;
4. Conversão das variáveis categóricas;
5. Separação dos dados em treino e teste;
6. Criação de novas variáveis;
7. Seleção de atributos com RFE;
8. Treinamento do modelo Random Forest;
9. Balanceamento da base com SMOTE;
10. Ajuste do limiar de decisão do modelo.

## Técnicas utilizadas

As principais técnicas utilizadas foram:

### Random Forest

Modelo baseado em várias árvores de decisão. Ele combina o resultado de várias árvores para gerar uma classificação mais estável.

### RFE — Recursive Feature Elimination

Técnica usada para selecionar as variáveis mais relevantes para o modelo.

### SMOTE

Técnica usada para lidar com o desbalanceamento da base, criando exemplos sintéticos da classe minoritária.

No caso deste trabalho, a classe de clientes inadimplentes era menor do que a classe de clientes pagadores.

### Ajuste de limiar

Além do limiar padrão de 0,50, foram testados outros pontos de corte para melhorar a identificação dos clientes inadimplentes.

O limiar recomendado foi **0,38**, pois aumentou a sensibilidade do modelo.

## Variáveis criadas

Foram criadas três novas variáveis para melhorar a análise:

| Variável | Significado |
|---|---|
| SOMA_ATRASOS | Soma dos atrasos nos meses anteriores |
| USO_LIMITE_ATUAL | Proporção do limite de crédito utilizado |
| RAZAO_PAGAMENTO_ATUAL | Relação entre valor pago e valor da fatura |

Essas variáveis ajudaram a resumir melhor o comportamento financeiro dos clientes.

## Métricas utilizadas

As principais métricas avaliadas foram:

| Métrica | O que indica |
|---|---|
| Acurácia | Percentual geral de acertos do modelo |
| Sensibilidade | Capacidade de identificar clientes inadimplentes |
| Especificidade | Capacidade de identificar clientes pagadores |
| AUC | Capacidade geral do modelo de separar as classes |
| Matriz de confusão | Mostra os acertos e erros por classe |

Neste problema, a sensibilidade foi uma métrica muito importante, porque o principal objetivo era identificar clientes com maior risco de inadimplência.

## Resultados principais

O modelo final atingiu **AUC de 0,753**.

Com o limiar padrão de 0,50, a sensibilidade foi de **37,53%**.

Após ajustar o limiar para **0,38**, a sensibilidade subiu para **45,21%**, mantendo a especificidade acima de **90%**.

| Cenário | Acurácia | Sensibilidade | Especificidade | AUC |
|---|---:|---:|---:|---:|
| Artigo base | 81,78% | 37,53% | 94,35% | 0,753 |
| Modelo proposto — limiar 0,50 | 81,78% | 37,53% | 94,35% | 0,753 |
| Modelo proposto — limiar 0,38 | 80,61% | 45,21% | 90,67% | 0,753 |

## Interpretação dos resultados

O resultado mais importante não foi o aumento da acurácia, mas sim o aumento da sensibilidade.

Em problemas de crédito, identificar possíveis inadimplentes é mais importante do que apenas ter uma acurácia alta. Isso acontece porque a base possui mais clientes pagadores do que inadimplentes, o que pode fazer a acurácia parecer boa mesmo quando o modelo erra muitos devedores.

Com o ajuste do limiar, o modelo passou a identificar melhor os clientes de maior risco.

## Conclusão

A análise mostrou que a mineração de dados pode auxiliar na previsão de inadimplência em cartão de crédito.

O uso de Random Forest, RFE, SMOTE e ajuste de limiar tornou o modelo mais adequado para o contexto real de risco de crédito.

A principal conclusão é que, nesse tipo de problema, a acurácia sozinha não é suficiente. É necessário analisar métricas como sensibilidade, especificidade e AUC para entender se o modelo realmente ajuda na tomada de decisão.
