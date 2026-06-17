<!-- README reescrito para estilo portfólio -->
# Portfólio — Temática em Mineração de Dados

Bem-vindo ao portfólio do curso **Temática em Mineração de Dados**. Aqui você encontra os projetos desenvolvidos no semestre, com foco em objetivos, abordagens, resultados e reprodutibilidade. Este repositório é pensado para ser consultado por recrutadores, colegas e avaliadores que queiram entender rapidamente o impacto prático de cada trabalho.

---

## Sobre este portfólio

- **Formato:** resumo executivo de cada projeto + código/relatório na pasta correspondente.
- **Público-alvo:** pesquisadores, analistas e times de produto interessados em aplicações de mineração de dados.
- **Linguagem principal:** R (scripts e relatórios em RMarkdown).

---

## Competências e ferramentas

- **Técnicas:** pré-processamento, engenharia de atributos, seleção de variáveis, balanceamento, modelagem supervisionada, validação cruzada, interpretação de modelos.
- **Modelos usados:** Random Forest, Elastic Net, SVM, XGBoost, ensembles, métodos de screening.
- **Ferramentas:** R, tidyverse, caret, ranger, glmnet, caretEnsemble, ROCR, ggplot2.

---

## Projetos selecionados

- **[cartao_credito](cartao_credito/):** previsão de inadimplência; foco em engenharia de atributos, RFE e ajuste de limiar para priorizar sensibilidade.
- **[interdIA](interdIA/):** pipeline reproduzível para triagem toxicológica; destaque para avaliação em teste externo e otimização de sensibilidade.
- **[drug_consumption](drug_consumption/):** análise por substância com tratamentos específicos para classes desbalanceadas e ensemble de modelos.
- **[gallstone](gallstone/):** seleção de painéis preditivos otimizando custo-benefício e estabilidade clínica.
- **[ilpd](ilpd/):** estudo de detecção de doença hepática com comparação por subgrupos (homens/mulheres) e análise de robustez.
- **[cream_cheese](cream_cheese/):** análise sensorial focada em atributos que explicam cremosidade; combina ANOVA, PCA e clustering.

Cada pasta contém scripts, outputs (figuras/tabelas) e um relatório com os principais achados.

---

## Destaques (resultados resumidos)

- InterDIA: AUC ~ 0.90 e sensibilidade elevada no teste externo (pipeline reprodutível).
- Cartão de crédito: limiar ajustado melhorou sensibilidade sem sacrificar demasiadamente a especificidade.
- Gallstone: painel pruned_top_11 fornece bom equilíbrio entre desempenho e custo de coleta.
- Cream Cheese: identificação de atributos sensoriais fortemente correlacionados com cremosidade.

---

## Como explorar este repositório

1. Navegue pelas pastas listadas em **Projetos selecionados**.
2. Abra os RMarkdown (`.Rmd`) correspondentes para ver análises interativas e código reprodutível.
3. Para reproduzir um relatório localmente:

```bash
# instalar dependências (exemplo)
Rscript -e "install.packages(c('tidyverse','rmarkdown','caret','ranger','glmnet'))"

# renderizar um relatório (exemplo para cream_cheese)
Rscript -e "rmarkdown::render('cream_cheese/relatorio_cream_cheese.Rmd')"
```

---

## Contato

- Autor(es): Equipe do curso — Temática em Mineração de Dados
- E-mail de contato: exemplo@universidade.edu (substitua pelo contato real)

---

Se quiser, posso ajustar o tom (mais técnico, mais visual, ou em inglês), incluir badges de métricas automáticas ou gerar uma versão em PDF pronta para apresentação.
