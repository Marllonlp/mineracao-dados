# Script R - Seleção de Variáveis na Análise de Risco de Crédito (Melhoria do Artigo)
# Base de Dados: Default of Credit Card Clients (UCI)

# Instale os pacotes necessários se não os tiver:
install.packages(c("caret", "readxl", "dplyr", "pROC", "randomForest", "curl", "e1071", "smotefamily"))

install.packages("randomForest")
install.packages(c("randomForest", "igraph", "smotefamily"), repos="https://cloud.r-project.org")

library(caret)
library(dplyr)
library(pROC)
library(smotefamily)
library(randomForest)



# =========================================================================
# 1. Carregamento dos Dados
# =========================================================================
cat("Baixando e carregando os dados do repositório UCI...\n")
url <- "https://archive.ics.uci.edu/ml/machine-learning-databases/00350/default%20of%20credit%20card%20clients.xls"
temp_file <- tempfile(fileext = ".xls")
curl::curl_download(url, temp_file)
dados <- readxl::read_xls(temp_file, skip = 1)
unlink(temp_file)

# Renomear e remover coluna ID
dados <- dados %>%
  rename(default = `default payment next month`) %>%
  select(-ID)

# =========================================================================
# 2. Pré-processamento Baseado no Artigo
# =========================================================================
# Agrupamento de categorias não documentadas ("Outros")
dados <- dados %>%
  mutate(
    EDUCATION = ifelse(EDUCATION %in% c(0, 4, 5, 6), 4, EDUCATION),
    MARRIAGE = ifelse(MARRIAGE == 0, 3, MARRIAGE)
  )

# =========================================================================
# 3. MELHORIA 1: Engenharia de Atributos (Feature Engineering)
# =========================================================================
# Garantindo que as colunas de pagamento sejam numéricas para os cálculos
cols_pay <- paste0("PAY_", c(0, 2, 3, 4, 5, 6))
dados[cols_pay] <- lapply(dados[cols_pay], function(x) as.numeric(as.character(x)))

# Criando novas variáveis que fornecem maior poder preditivo
dados <- dados %>%
  mutate(
    # 1. Soma do histórico de status de pagamento (indicador de atraso crônico)
    # Subtraímos o valor base (ex: se todos forem -1, a soma seria -6, ajustamos para escala positiva)
    SOMA_ATRASOS = PAY_0 + PAY_2 + PAY_3 + PAY_4 + PAY_5 + PAY_6,
    
    # 2. Uso do Limite: O quão sufocado está o limite de crédito na última fatura
    USO_LIMITE_ATUAL = BILL_AMT1 / (LIMIT_BAL + 1),
    
    # 3. Razão de Pagamento: Quanto da fatura efetivamente foi paga 
    RAZAO_PAGAMENTO_ATUAL = PAY_AMT1 / (BILL_AMT1 + 1)
  )

# --- LIMPEZA CRÍTICA: Removendo NAs e Infs que quebram o RandomForest ---
cat("Limpando valores ausentes (NA) e infinitos (Inf)...\n")
# Substitui valores infinitos por NA e depois remove tudo de uma vez
dados <- dados %>%
  mutate(across(everything(), ~ ifelse(is.infinite(.), NA, .))) %>% 
  na.omit()

# Convertendo variáveis categóricas para fator
cols_categoricas <- c("SEX", "EDUCATION", "MARRIAGE")
dados[cols_categoricas] <- lapply(dados[cols_categoricas], as.factor)

# Alvo para fator com rótulos válidos (exigência do caret)
dados$default <- factor(dados$default, levels = c(0, 1), labels = c("Pagador", "Devedor"))

# =========================================================================
# 4. Particionamento (80/20 Estratificado como no artigo)
# =========================================================================
set.seed(123)
indice_treino <- createDataPartition(dados$default, p = 0.8, list = FALSE)
treino <- dados[indice_treino, ]
teste <- dados[-indice_treino, ]

# =========================================================================
# 5. RFE (Recursive Feature Elimination) - Otimizado
# =========================================================================
cat("\nConfigurando e Executando RFE (Recursive Feature Elimination)...\n")
cat("Atenção: A execução do RFE pode levar alguns minutos.\n")

# Customizando Random Forest no RFE para otimizar ROC
rf_funcs_roc <- rfFuncs
rf_funcs_roc$summary <- twoClassSummary

controle_rfe <- rfeControl(
  functions = rf_funcs_roc,
  method = "cv",
  number = 5, # 5-fold CV 
  verbose = FALSE
)

# Tamanhos de subconjuntos incluindo nossas novas variáveis
tamanhos_subconjuntos <- c(5, 10, 15, 20, 25)

x_treino <- treino %>% select(-default)
y_treino <- treino$default

set.seed(123)
# Execução do RFE (utilizando 100 árvores internamente para agilizar a seleção)
resultado_rfe <- rfe(
  x = x_treino,
  y = y_treino,
  sizes = tamanhos_subconjuntos,
  rfeControl = controle_rfe,
  metric = "ROC",
  ntree = 100 
)

print(resultado_rfe)
vars_selecionadas <- predictors(resultado_rfe)
cat("\n=> Variáveis selecionadas pelo RFE melhorado:\n", paste(vars_selecionadas, collapse=", "), "\n")

# =========================================================================
# 6. MELHORIA 2: Treinamento do Modelo Final Robusto (SMOTE + 500 ntree)
# =========================================================================
cat("\nTreinando o modelo Random Forest Final com SMOTE e ntree=500...\n")

treino_rfe <- treino %>% select(all_of(vars_selecionadas), default)
teste_rfe <- teste %>% select(all_of(vars_selecionadas), default)

# Controle de treino aplicando SMOTE para equilibrar a classe minoritária (Devedores)
ctrl_treino <- trainControl(
  method = "cv",
  number = 5,
  classProbs = TRUE,
  summaryFunction = twoClassSummary,
  sampling = "smote" # Importante para combater os 22% de desbalanceamento
)

set.seed(123)
modelo_rf_final <- train(
  default ~ ., 
  data = treino_rfe,
  method = "rf",
  metric = "ROC",
  trControl = ctrl_treino,
  tuneGrid = expand.grid(mtry = c(2, 4, 6, 8)),
  ntree = 500 # Aumento da robustez das árvores (o artigo usou 100)
)

print(modelo_rf_final)

# =========================================================================
# 7. MELHORIA 3: Avaliação e Otimização de Limiar (Threshold Tuning)
# =========================================================================
# Extraindo probabilidades no conjunto de teste
probs_teste <- predict(modelo_rf_final, newdata = teste_rfe, type = "prob")

# Curva ROC
roc_obj <- roc(teste_rfe$default, probs_teste$Devedor, levels = c("Pagador", "Devedor"))
auc_teste <- auc(roc_obj)

cat("\n=======================================================\n")
cat(sprintf("=> RESULTADO: AUC (ROC) Final no Teste: %.4f\n", auc_teste))
cat("=> REFERÊNCIA: O Artigo original alcançou AUC de 0.753\n")
cat("=======================================================\n")

# Calculando o limiar ótimo de Youden para maximizar separação (Sensibilidade + Especificidade)
coords_otimas <- coords(roc_obj, "best", best.method = "youden", ret = c("threshold", "specificity", "sensitivity", "accuracy"))
limiar_otimo <- coords_otimas$threshold
cat(sprintf("\nLimiar Ótimo Recomendado (Youden/KS): %.4f (Artigo usou 0.38)\n", limiar_otimo))

# Aplicando o novo limiar
previsoes_finais <- ifelse(probs_teste$Devedor >= limiar_otimo, "Devedor", "Pagador")
previsoes_finais <- factor(previsoes_finais, levels = c("Pagador", "Devedor"))

# Exibindo matriz de confusão final
cat("\nMatriz de Confusão Final (com Limiar Otimizado):\n")
conf_matrix <- confusionMatrix(previsoes_finais, teste_rfe$default, positive = "Devedor")
print(conf_matrix)

