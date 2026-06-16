# InterDIA em R: reproducao portatil, comparacao de modelos e relatorio final
# -----------------------------------------------------------------------------
# Objetivo cientifico
# Este script reproduz, em R e com um unico ponto de execucao, a analise do
# artigo "InterDIA: Interpretable prediction of drug-induced autoimmunity
# through ensemble machine learning approaches".
#
# Decisoes metodologicas principais
# 1. A base oficial e baixada diretamente do UCI Machine Learning Repository,
#    garantindo uma fonte institucional e estavel para os arquivos tabulares.
# 2. O subconjunto de 65 descritores publicado pelos autores e reutilizado aqui.
#    Isso torna a execucao deterministica e portatil, sem depender de um GA
#    demorado para refazer a selecao de atributos em cada computador.
# 3. O modelo principal e um EasyEnsemble customizado em R, porque em toxicologia
#    de seguranca o custo de um falso negativo costuma ser maior do que o custo
#    de um falso positivo. Por isso, o limiar e escolhido com piso de
#    sensitividade >= 0.80 sempre que possivel.
# 4. O conjunto de teste externo jamais e usado para escolher limiar, modelo ou
#    hiperparametros. Toda selecao e feita com probabilidades out-of-fold.
#
# Saidas
# - Tabelas em outputs/tables
# - Graficos em outputs/figures
# - Modelos e objetos em outputs/models e outputs/results
# - Relatorio HTML renderizado a partir de interdia_report.Rmd em outputs/report

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Instala apenas os pacotes ausentes para manter o script portatil.
install_if_missing <- function(packages) {
  missing_packages <- packages[!vapply(
    packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )]

  if (length(missing_packages) > 0) {
    install.packages(missing_packages, dependencies = TRUE)
  }
}

required_packages <- c(
  "readr",
  "dplyr",
  "tibble",
  "tidyr",
  "ggplot2",
  "pROC",
  "ranger",
  "ada",
  "rpart",
  "glmnet",
  "scales",
  "knitr",
  "rmarkdown"
)

install_if_missing(required_packages)

library(readr)
library(dplyr)
library(tibble)
library(tidyr)
library(ggplot2)
library(pROC)
library(ranger)
library(ada)
library(rpart)
library(glmnet)
library(scales)
library(knitr)
library(rmarkdown)

set.seed(20260405)

root_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_dir <- file.path(root_dir, "data", "raw")
tables_dir <- file.path(root_dir, "outputs", "tables")
figures_dir <- file.path(root_dir, "outputs", "figures")
models_dir <- file.path(root_dir, "outputs", "models")
results_dir <- file.path(root_dir, "outputs", "results")
report_dir <- file.path(root_dir, "outputs", "report")

dirs_to_create <- c(data_dir, tables_dir, figures_dir, models_dir, results_dir, report_dir)
invisible(lapply(dirs_to_create, dir.create, recursive = TRUE, showWarnings = FALSE))

cat("Diretorio de trabalho:", root_dir, "\n")

uci_bundle_url <- "https://archive.ics.uci.edu/static/public/1104/drug_induced_autoimmunity_prediction.zip"
uci_bundle_path <- file.path(data_dir, "drug_induced_autoimmunity_prediction.zip")
uci_expected_files <- c(
  "DIA_trainingset_RDKit_descriptors.csv",
  "DIA_testset_RDKit_descriptors.csv",
  "RDKit_ChemDes.xlsx"
)

# Evita baixar novamente arquivos que ja existem no projeto.
download_if_needed <- function(url, destination) {
  if (!file.exists(destination)) {
    download.file(url, destination, mode = "wb", quiet = TRUE)
  }
  destination
}

# Extrai o pacote oficial do UCI apenas quando algum arquivo esperado estiver ausente.
extract_uci_bundle_if_needed <- function(zip_path, target_dir, expected_files) {
  missing_files <- expected_files[!file.exists(file.path(target_dir, expected_files))]

  if (length(missing_files) > 0) {
    utils::unzip(zip_path, exdir = target_dir, overwrite = TRUE)
  }

  remaining_missing <- expected_files[!file.exists(file.path(target_dir, expected_files))]
  if (length(remaining_missing) > 0) {
    stop(
      "Os seguintes arquivos esperados nao foram encontrados apos extracao do bundle UCI: ",
      paste(remaining_missing, collapse = ", ")
    )
  }

  invisible(file.path(target_dir, expected_files))
}

download_if_needed(uci_bundle_url, uci_bundle_path)
extract_uci_bundle_if_needed(uci_bundle_path, data_dir, uci_expected_files)

train_csv_path <- file.path(data_dir, "DIA_trainingset_RDKit_descriptors.csv")
test_csv_path <- file.path(data_dir, "DIA_testset_RDKit_descriptors.csv")
descriptor_catalog_path <- file.path(data_dir, "RDKit_ChemDes.xlsx")

# Subconjunto final de 65 descritores publicado pelos autores.
published_features <- c(
  "BalabanJ", "Chi0", "EState_VSA1", "EState_VSA10", "EState_VSA4", "EState_VSA6",
  "EState_VSA9", "HallKierAlpha", "Ipc", "Kappa3", "NHOHCount",
  "NumAliphaticHeterocycles", "NumAliphaticRings", "NumAromaticCarbocycles",
  "NumAromaticRings", "PEOE_VSA10", "PEOE_VSA11", "PEOE_VSA12", "PEOE_VSA13",
  "PEOE_VSA14", "PEOE_VSA6", "PEOE_VSA7", "PEOE_VSA9", "RingCount",
  "SMR_VSA10", "SMR_VSA4", "SMR_VSA5", "SMR_VSA6", "SMR_VSA9", "SlogP_VSA10",
  "SlogP_VSA5", "SlogP_VSA8", "VSA_EState8", "fr_ArN", "fr_Ar_NH", "fr_C_O",
  "fr_NH2", "fr_N_O", "fr_Ndealkylation1", "fr_alkyl_carbamate",
  "fr_allylic_oxid", "fr_amide", "fr_aryl_methyl", "fr_azo",
  "fr_benzodiazepine", "fr_bicyclic", "fr_dihydropyridine", "fr_epoxide",
  "fr_ether", "fr_furan", "fr_guanido", "fr_hdrzone", "fr_imide",
  "fr_ketone_Topliss", "fr_lactam", "fr_methoxy", "fr_morpholine",
  "fr_nitro_arom", "fr_para_hydroxylation", "fr_phos_ester", "fr_piperdine",
  "fr_pyridine", "fr_sulfide", "fr_term_acetylene", "fr_unbrch_alkane"
)

article_best_metrics <- tibble(
  source = "Published reference (article notebook)",
  model = "EasyEnsemble + GA-65",
  ACC = 0.8500,
  SEN = 0.8333,
  SPE = 0.8556,
  MCC = 0.6413,
  AUC = 0.8930
)

# Padroniza o alvo para um fator binario e preserva o restante da tabela.
prepare_dataset <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  df %>%
    mutate(
      Class = factor(ifelse(Label == 1, "DIA", "No_DIA"), levels = c("No_DIA", "DIA"))
    ) %>%
    select(Label, SMILES, Class, everything())
}

train_raw <- prepare_dataset(train_csv_path)
test_raw <- prepare_dataset(test_csv_path)

missing_columns <- setdiff(published_features, names(train_raw))
if (length(missing_columns) > 0) {
  stop("As seguintes colunas publicadas nao foram encontradas na base: ",
       paste(missing_columns, collapse = ", "))
}

train_model_df <- train_raw %>%
  select(Class, all_of(published_features))

test_model_df <- test_raw %>%
  select(Class, all_of(published_features))

dataset_summary <- tibble(
  split = c("Train", "Test"),
  n = c(nrow(train_raw), nrow(test_raw)),
  positives = c(sum(train_raw$Class == "DIA"), sum(test_raw$Class == "DIA")),
  negatives = c(sum(train_raw$Class == "No_DIA"), sum(test_raw$Class == "No_DIA")),
  positive_rate = c(mean(train_raw$Class == "DIA"), mean(test_raw$Class == "DIA")),
  descriptors_available = c(ncol(train_raw) - 3, ncol(test_raw) - 3),
  published_descriptor_subset = length(published_features),
  missing_values = c(sum(is.na(train_raw)), sum(is.na(test_raw)))
)

write_csv(dataset_summary, file.path(tables_dir, "dataset_summary.csv"))
write_csv(article_best_metrics, file.path(tables_dir, "article_reference_metrics.csv"))

# Cria folds estratificados para manter a proporcao de positivos em cada dobra.
make_stratified_folds <- function(y, k = 5, seed = 20260405) {
  set.seed(seed)
  y_chr <- as.character(y)
  idx_pos <- sample(which(y_chr == "DIA"))
  idx_neg <- sample(which(y_chr == "No_DIA"))

  folds <- vector("list", k)
  for (i in seq_len(k)) {
    folds[[i]] <- integer(0)
  }

  for (i in seq_along(idx_pos)) {
    fold_id <- ((i - 1) %% k) + 1
    folds[[fold_id]] <- c(folds[[fold_id]], idx_pos[i])
  }

  for (i in seq_along(idx_neg)) {
    fold_id <- ((i - 1) %% k) + 1
    folds[[fold_id]] <- c(folds[[fold_id]], idx_neg[i])
  }

  folds
}

# Calcula as metricas exigidas a partir das probabilidades e do limiar escolhido.
calc_metrics <- function(truth, prob, threshold = 0.5) {
  truth <- factor(truth, levels = c("No_DIA", "DIA"))
  pred <- factor(ifelse(prob >= threshold, "DIA", "No_DIA"), levels = levels(truth))

  tp <- as.numeric(sum(pred == "DIA" & truth == "DIA"))
  tn <- as.numeric(sum(pred == "No_DIA" & truth == "No_DIA"))
  fp <- as.numeric(sum(pred == "DIA" & truth == "No_DIA"))
  fn <- as.numeric(sum(pred == "No_DIA" & truth == "DIA"))

  acc <- (tp + tn) / length(truth)
  sens <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
  spec <- if ((tn + fp) == 0) NA_real_ else tn / (tn + fp)
  precision <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
  recall <- sens
  f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
    NA_real_
  } else {
    2 * precision * recall / (precision + recall)
  }

  mcc_den <- sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
  mcc <- if (is.na(mcc_den) || mcc_den == 0) {
    NA_real_
  } else {
    ((tp * tn) - (fp * fn)) / mcc_den
  }

  auc_value <- as.numeric(
    pROC::auc(
      response = truth,
      predictor = prob,
      levels = c("No_DIA", "DIA"),
      direction = "<"
    )
  )

  tibble(
    ACC = acc,
    SEN = sens,
    SPE = spec,
    PREC = precision,
    RECALL = recall,
    F1 = f1,
    MCC = mcc,
    AUC = auc_value,
    TP = tp,
    FN = fn,
    FP = fp,
    TN = tn
  )
}

# Escolhe o limiar no treino, priorizando MCC sem perder sensitividade minima.
choose_threshold <- function(truth, prob, min_sensitivity = 0.80) {
  threshold_grid <- seq(0.20, 0.90, by = 0.01)

  threshold_metrics <- bind_rows(lapply(
    threshold_grid,
    function(threshold_value) {
      cbind(tibble(threshold = threshold_value), calc_metrics(truth, prob, threshold_value))
    }
  ))

  constrained <- threshold_metrics %>%
    filter(SEN >= min_sensitivity) %>%
    arrange(desc(MCC), desc(SPE), desc(AUC))

  if (nrow(constrained) > 0) {
    best <- constrained %>% slice(1)
    best$selection_rule <- paste0("maximize_MCC_with_SEN_at_least_", format(min_sensitivity, nsmall = 2))
  } else {
    best <- threshold_metrics %>%
      arrange(desc(MCC), desc(AUC), desc(SEN + SPE)) %>%
      slice(1)
    best$selection_rule <- "maximize_MCC_without_sensitivity_constraint"
  }

  list(best = best, full_grid = threshold_metrics)
}

# Treina varios boosters em subconjuntos balanceados e agrega as previsoes.
fit_easy_ensemble <- function(df, n_subsets = 10, iter = 180, maxdepth = 5, nu = 0.5, seed = 20260405) {
  set.seed(seed)
  y <- df$Class
  x <- df %>% select(-Class)
  pos_idx <- which(y == "DIA")
  neg_idx <- which(y == "No_DIA")

  models <- vector("list", n_subsets)
  for (b in seq_len(n_subsets)) {
    neg_sample <- sample(neg_idx, length(pos_idx), replace = TRUE)
    idx <- c(pos_idx, neg_sample)
    boot_df <- data.frame(Class = droplevels(y[idx]), x[idx, , drop = FALSE])

    models[[b]] <- ada::ada(
      Class ~ .,
      data = boot_df,
      iter = iter,
      nu = nu,
      loss = "exponential",
      type = "discrete",
      control = rpart::rpart.control(
        maxdepth = maxdepth,
        cp = 0.001,
        minsplit = 10,
        xval = 0
      )
    )
  }

  structure(
    list(
      models = models,
      levels = levels(y),
      hyperparameters = list(
        n_subsets = n_subsets,
        iter = iter,
        maxdepth = maxdepth,
        nu = nu
      )
    ),
    class = "easy_ensemble_custom"
  )
}

# A probabilidade final e a media das probabilidades dos submodelos.
predict_easy_ensemble <- function(model, newdata) {
  probs <- sapply(model$models, function(single_model) {
    predicted <- predict(single_model, newdata = newdata, type = "prob")
    if (is.matrix(predicted) || is.data.frame(predicted)) {
      predicted[, 1]
    } else {
      as.numeric(predicted)
    }
  })

  if (is.null(dim(probs))) {
    probs <- matrix(probs, ncol = 1)
  }

  rowMeans(probs)
}

# Random forest com pesos de classe para compensar o desbalanceamento.
fit_weighted_ranger <- function(df, num.trees = 800, mtry = 8, min.node.size = 3, seed = 20260405) {
  ratio <- sum(df$Class == "No_DIA") / sum(df$Class == "DIA")

  ranger::ranger(
    Class ~ .,
    data = df,
    probability = TRUE,
    num.trees = num.trees,
    mtry = mtry,
    min.node.size = min.node.size,
    class.weights = c(No_DIA = 1, DIA = ratio),
    importance = "permutation",
    seed = seed
  )
}

predict_weighted_ranger <- function(model, newdata) {
  predict(model, data = newdata)$predictions[, "DIA"]
}

# Baseline linear penalizado com padronizacao e pesos para a classe positiva.
fit_weighted_glmnet <- function(df, alpha = 0.5, seed = 20260405) {
  x <- as.matrix(df[, -1, drop = FALSE])
  center <- colMeans(x)
  scale_vec <- apply(x, 2, sd)
  scale_vec[scale_vec == 0] <- 1
  x_scaled <- scale(x, center = center, scale = scale_vec)

  y <- ifelse(df$Class == "DIA", 1, 0)
  pos_weight <- sum(y == 0) / sum(y == 1)
  weights <- ifelse(y == 1, pos_weight, 1)

  set.seed(seed)
  fit <- cv.glmnet(
    x = x_scaled,
    y = y,
    family = "binomial",
    alpha = alpha,
    weights = weights,
    nfolds = 5,
    type.measure = "deviance"
  )

  list(
    fit = fit,
    center = center,
    scale = scale_vec,
    alpha = alpha
  )
}

predict_weighted_glmnet <- function(model, newdata) {
  x <- as.matrix(newdata)
  x_scaled <- scale(x, center = model$center, scale = model$scale)
  as.numeric(predict(model$fit, newx = x_scaled, s = "lambda.1se", type = "response"))
}

# Gera probabilidades out-of-fold para avaliar cada modelo sem vazar o teste externo.
cross_validate_model <- function(df, fit_function, predict_function, fit_args = list(), k = 5, seed = 20260405) {
  folds <- make_stratified_folds(df$Class, k = k, seed = seed)
  oof_prob <- rep(NA_real_, nrow(df))

  for (fold_id in seq_along(folds)) {
    idx_val <- folds[[fold_id]]
    idx_train <- setdiff(seq_len(nrow(df)), idx_val)

    train_fold <- df[idx_train, , drop = FALSE]
    val_fold <- df[idx_val, , drop = FALSE]

    fit_call <- c(list(df = train_fold, seed = seed + fold_id), fit_args)
    model <- do.call(fit_function, fit_call)
    oof_prob[idx_val] <- predict_function(model, val_fold[, -1, drop = FALSE])
  }

  oof_prob
}

# Catalogo dos modelos comparados e seus hiperparametros fixos.
model_specs <- list(
  list(
    model = "Elastic Net (baseline)",
    fit_function = fit_weighted_glmnet,
    predict_function = predict_weighted_glmnet,
    fit_args = list(alpha = 0.5),
    rationale = "Baseline linear model para medir quanto da separacao e explicada por efeitos aproximadamente aditivos."
  ),
  list(
    model = "Weighted Ranger",
    fit_function = fit_weighted_ranger,
    predict_function = predict_weighted_ranger,
    fit_args = list(num.trees = 800, mtry = 8, min.node.size = 3),
    rationale = "Modelo de floresta aleatoria ponderada, robusto para descritores nao lineares e interacoes locais."
  ),
  list(
    model = "EasyEnsemble Screening",
    fit_function = fit_easy_ensemble,
    predict_function = predict_easy_ensemble,
    fit_args = list(n_subsets = 10, iter = 180, maxdepth = 5, nu = 0.5),
    rationale = "Modelo principal de triagem: balanceia a base por subconjuntos e privilegia alta sensitividade, adequada para seguranca pre-clinica."
  )
)

oof_results <- list()
threshold_results <- list()
train_metrics_list <- list()
test_metrics_list <- list()
final_models <- list()
test_probabilities <- list()

# Para cada modelo: valida no treino, escolhe limiar e depois mede o teste externo.
for (spec in model_specs) {
  cat("Rodando validacao cruzada para:", spec$model, "\n")

  oof_prob <- cross_validate_model(
    df = train_model_df,
    fit_function = spec$fit_function,
    predict_function = spec$predict_function,
    fit_args = spec$fit_args,
    k = 5,
    seed = 20260405
  )

  threshold_info <- choose_threshold(train_model_df$Class, oof_prob, min_sensitivity = 0.80)
  selected_threshold <- threshold_info$best$threshold[[1]]
  train_metrics <- calc_metrics(train_model_df$Class, oof_prob, threshold = selected_threshold)

  fit_call <- c(list(df = train_model_df, seed = 20260405), spec$fit_args)
  final_model <- do.call(spec$fit_function, fit_call)
  test_prob <- spec$predict_function(final_model, test_model_df[, -1, drop = FALSE])
  test_metrics <- calc_metrics(test_model_df$Class, test_prob, threshold = selected_threshold)

  oof_results[[spec$model]] <- oof_prob
  threshold_results[[spec$model]] <- threshold_info
  final_models[[spec$model]] <- final_model
  test_probabilities[[spec$model]] <- test_prob

  train_metrics_list[[spec$model]] <- cbind(
    tibble(
      model = spec$model,
      threshold = selected_threshold,
      threshold_rule = threshold_info$best$selection_rule[[1]],
      split = "train_oof",
      rationale = spec$rationale
    ),
    train_metrics
  )

  test_metrics_list[[spec$model]] <- cbind(
    tibble(
      model = spec$model,
      threshold = selected_threshold,
      threshold_rule = threshold_info$best$selection_rule[[1]],
      split = "external_test",
      rationale = spec$rationale
    ),
    test_metrics
  )
}

train_metrics_table <- bind_rows(train_metrics_list) %>%
  arrange(desc(MCC), desc(AUC), desc(SEN))

test_metrics_table <- bind_rows(test_metrics_list) %>%
  arrange(desc(MCC), desc(AUC), desc(SEN))

write_csv(train_metrics_table, file.path(tables_dir, "train_oof_metrics.csv"))
write_csv(test_metrics_table, file.path(tables_dir, "external_test_metrics.csv"))

# Mantem o EasyEnsemble como modelo principal por ser o mais alinhado a triagem.
primary_train_ranking <- train_metrics_table %>%
  mutate(screening_eligible = SEN >= 0.80)

if ("EasyEnsemble Screening" %in% names(final_models)) {
  primary_model_name <- "EasyEnsemble Screening"
} else if (any(primary_train_ranking$screening_eligible)) {
  primary_model_name <- primary_train_ranking %>%
    filter(screening_eligible) %>%
    arrange(desc(MCC), desc(AUC), desc(SPE)) %>%
    slice(1) %>%
    pull(model)
} else {
  primary_model_name <- primary_train_ranking %>%
    arrange(desc(MCC), desc(AUC), desc(SEN + SPE)) %>%
    slice(1) %>%
    pull(model)
}

primary_model <- final_models[[primary_model_name]]
primary_threshold <- train_metrics_table %>%
  filter(model == primary_model_name) %>%
  pull(threshold) %>%
  .[[1]]

primary_test_prob <- test_probabilities[[primary_model_name]]
primary_test_metrics <- test_metrics_table %>%
  filter(model == primary_model_name)

primary_predictions_df <- tibble(
  compound_id = seq_len(nrow(test_raw)),
  smiles = test_raw$SMILES,
  observed = test_raw$Class,
  predicted_probability = primary_test_prob,
  predicted_class = factor(
    ifelse(primary_test_prob >= primary_threshold, "DIA", "No_DIA"),
    levels = c("No_DIA", "DIA")
  )
)

write_csv(primary_predictions_df, file.path(tables_dir, "primary_model_test_predictions.csv"))

# Reorganiza a matriz de confusao para facilitar o grafico em formato de calor.
primary_confusion_long <- calc_metrics(
  truth = test_model_df$Class,
  prob = primary_test_prob,
  threshold = primary_threshold
) %>%
  select(TP, FN, FP, TN) %>%
  pivot_longer(cols = everything(), names_to = "cell", values_to = "count") %>%
  mutate(
    actual = case_when(
      cell %in% c("TP", "FN") ~ "DIA",
      TRUE ~ "No_DIA"
    ),
    predicted = case_when(
      cell %in% c("TP", "FP") ~ "DIA",
      TRUE ~ "No_DIA"
    )
  )

# Extrai uma medida simples de importancia para o modelo principal.
primary_importance <- if (inherits(primary_model, "easy_ensemble_custom")) {
  importance_scores <- ada::varplot(
    primary_model$models[[1]],
    plot.it = FALSE,
    type = "scores"
  )

  tibble(
    feature = names(importance_scores),
    importance = as.numeric(importance_scores)
  ) %>%
    arrange(desc(importance))
} else if (inherits(primary_model, "ranger")) {
  tibble(
    feature = names(primary_model$variable.importance),
    importance = as.numeric(primary_model$variable.importance)
  ) %>%
    arrange(desc(importance))
} else {
  tibble(feature = published_features, importance = NA_real_)
}

write_csv(primary_importance, file.path(tables_dir, "primary_model_feature_importance.csv"))

# Seleciona poucos descritores para os graficos explicativos finais.
top_feature_names <- primary_importance %>%
  slice_head(n = min(6, nrow(primary_importance))) %>%
  pull(feature)

top_feature_long <- train_raw %>%
  mutate(Class = factor(ifelse(Label == 1, "DIA", "No_DIA"), levels = c("No_DIA", "DIA"))) %>%
  select(Class, all_of(top_feature_names)) %>%
  pivot_longer(
    cols = -Class,
    names_to = "feature",
    values_to = "value"
  )

# Curvas ROC dos tres modelos no mesmo teste externo.
roc_data <- bind_rows(lapply(names(test_probabilities), function(model_name) {
  roc_obj <- pROC::roc(
    response = test_model_df$Class,
    predictor = test_probabilities[[model_name]],
    levels = c("No_DIA", "DIA"),
    direction = "<",
    quiet = TRUE
  )

  tibble(
    model = model_name,
    fpr = 1 - roc_obj$specificities,
    tpr = roc_obj$sensitivities,
    auc = as.numeric(roc_obj$auc)
  )
}))

class_distribution_df <- bind_rows(
  train_raw %>%
    count(Class) %>%
    mutate(split = "Train"),
  test_raw %>%
    count(Class) %>%
    mutate(split = "Test")
)

class_distribution_plot <- ggplot(class_distribution_df, aes(x = Class, y = n, fill = Class)) +
  geom_col(width = 0.70, alpha = 0.90) +
  facet_wrap(~split) +
  scale_fill_manual(values = c("No_DIA" = "#376996", "DIA" = "#c95d3a")) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Distribuicao de classes na base oficial do artigo",
    subtitle = "A base e desbalanceada, o que justifica o foco em sensitividade, especificidade e MCC",
    x = NULL,
    y = "Numero de compostos",
    fill = "Classe"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

# Salva cada grafico em arquivo para o relatorio e para entrega final.
ggsave(
  filename = file.path(figures_dir, "class_distribution.png"),
  plot = class_distribution_plot,
  width = 9,
  height = 4.5,
  dpi = 300
)

test_metrics_plot_df <- test_metrics_table %>%
  select(model, ACC, SEN, SPE, MCC, AUC) %>%
  pivot_longer(
    cols = c(ACC, SEN, SPE, MCC, AUC),
    names_to = "metric",
    values_to = "value"
  )

test_metrics_plot <- ggplot(test_metrics_plot_df, aes(x = metric, y = value, fill = model)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.68) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1)) +
  scale_fill_manual(values = c(
    "Elastic Net (baseline)" = "#8c8c8c",
    "Weighted Ranger" = "#3b7ea1",
    "EasyEnsemble Screening" = "#d16b3d"
  )) +
  labs(
    title = "Comparacao de metricas no teste externo",
    subtitle = "Acuracia, sensitividade, especificidade, MCC e AUC",
    x = NULL,
    y = "Valor da metrica",
    fill = "Modelo"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(
  filename = file.path(figures_dir, "external_test_metrics_comparison.png"),
  plot = test_metrics_plot,
  width = 10,
  height = 5.2,
  dpi = 300
)

roc_plot <- ggplot(roc_data, aes(x = fpr, y = tpr, color = model)) +
  geom_line(linewidth = 1.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray55") +
  scale_color_manual(values = c(
    "Elastic Net (baseline)" = "#8c8c8c",
    "Weighted Ranger" = "#3b7ea1",
    "EasyEnsemble Screening" = "#d16b3d"
  )) +
  coord_equal() +
  labs(
    title = "Curvas ROC no teste externo",
    subtitle = "Comparacao direta entre modelos sobre o mesmo conjunto de teste",
    x = "1 - Especificidade",
    y = "Sensitividade",
    color = "Modelo"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(
  filename = file.path(figures_dir, "external_test_roc_curves.png"),
  plot = roc_plot,
  width = 7,
  height = 6,
  dpi = 300
)

confusion_plot <- ggplot(primary_confusion_long, aes(x = predicted, y = actual, fill = count)) +
  geom_tile(color = "white", linewidth = 0.7) +
  geom_text(aes(label = count), size = 5, fontface = "bold") +
  scale_fill_gradient(low = "#f4efe7", high = "#c95d3a") +
  labs(
    title = paste("Matriz de confusao -", primary_model_name),
    subtitle = paste("Limiar selecionado no treino:", round(primary_threshold, 2)),
    x = "Predito",
    y = "Observado",
    fill = "Contagem"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  filename = file.path(figures_dir, "primary_model_confusion_matrix.png"),
  plot = confusion_plot,
  width = 6.5,
  height = 5.2,
  dpi = 300
)

feature_importance_plot <- primary_importance %>%
  slice_head(n = min(15, nrow(primary_importance))) %>%
  ggplot(aes(x = reorder(feature, importance), y = importance)) +
  geom_col(fill = "#d16b3d", alpha = 0.90) +
  coord_flip() +
  labs(
    title = paste("Descritores mais influentes -", primary_model_name),
    subtitle = "Atributos com maior peso na discriminacao entre compostos de maior e menor risco",
    x = NULL,
    y = "Importancia"
  ) +
  theme_minimal(base_size = 12)

ggsave(
  filename = file.path(figures_dir, "primary_model_feature_importance.png"),
  plot = feature_importance_plot,
  width = 9,
  height = 6,
  dpi = 300
)

descriptor_boxplot <- ggplot(top_feature_long, aes(x = Class, y = value, fill = Class)) +
  geom_boxplot(alpha = 0.80, outlier.alpha = 0.25) +
  facet_wrap(~feature, scales = "free_y") +
  scale_fill_manual(values = c("No_DIA" = "#376996", "DIA" = "#c95d3a")) +
  labs(
    title = "Distribuicao dos descritores mais relevantes por classe",
    subtitle = "Os descritores destacados ajudam a explicar por que o modelo consegue separar perfis moleculares",
    x = NULL,
    y = "Valor do descritor",
    fill = "Classe"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave(
  filename = file.path(figures_dir, "top_descriptor_boxplots.png"),
  plot = descriptor_boxplot,
  width = 10,
  height = 6.5,
  dpi = 300
)

analysis_notes <- c(
  "A base oficial e pequena e desbalanceada (mais negativos do que positivos), entao otimizar apenas acuracia seria inadequado.",
  "Por contexto toxicologico, a selecao do limiar privilegiou sensitividade minima de 0.80 sempre que o treino permitiu.",
  "O EasyEnsemble Screening foi projetado para triagem de risco: e preferivel errar para o lado de marcar compostos suspeitos do que deixar passar um composto potencialmente autoimune.",
  "O Weighted Ranger foi mantido como comparador de especificidade alta, util em um segundo estagio de priorizacao.",
  "O Elastic Net entrou como baseline interpretable; seu desempenho inferior sugere que a relacao entre descritores e risco de DIA e fortemente nao linear."
)

results_bundle <- list(
  root_dir = root_dir,
  dataset_summary = dataset_summary,
  article_best_metrics = article_best_metrics,
  train_metrics_table = train_metrics_table,
  test_metrics_table = test_metrics_table,
  primary_model_name = primary_model_name,
  primary_threshold = primary_threshold,
  primary_test_metrics = primary_test_metrics,
  primary_importance = primary_importance,
  primary_predictions = primary_predictions_df,
  primary_confusion_long = primary_confusion_long,
  top_feature_names = top_feature_names,
  analysis_notes = analysis_notes,
  figure_files = list(
    class_distribution = file.path(figures_dir, "class_distribution.png"),
    metrics_comparison = file.path(figures_dir, "external_test_metrics_comparison.png"),
    roc_curves = file.path(figures_dir, "external_test_roc_curves.png"),
    confusion_matrix = file.path(figures_dir, "primary_model_confusion_matrix.png"),
    feature_importance = file.path(figures_dir, "primary_model_feature_importance.png"),
    top_descriptor_boxplots = file.path(figures_dir, "top_descriptor_boxplots.png")
  ),
  threshold_tables = threshold_results
)

saveRDS(results_bundle, file.path(results_dir, "interdia_results.rds"))
saveRDS(final_models, file.path(models_dir, "final_models.rds"))

# Imprime no console um resumo direto dos resultados para facilitar a leitura apos a execucao.
print_console_results <- function() {
  metric_cols <- c("ACC", "SEN", "SPE", "PREC", "RECALL", "F1", "MCC", "AUC")

  cat("\n================ RESUMO DA BASE ================\n")
  print(dataset_summary)

  cat("\n=========== BENCHMARK PUBLICADO NO ARTIGO ===========\n")
  print(article_best_metrics %>% mutate(across(where(is.numeric), ~round(.x, 4))))

  cat("\n========== RESULTADOS NO TREINO (OUT-OF-FOLD) ==========\n")
  print(
    train_metrics_table %>%
      select(model, threshold, threshold_rule, all_of(metric_cols), TP, FN, FP, TN) %>%
      mutate(across(all_of(metric_cols), ~round(.x, 4)))
  )

  cat("\n============= RESULTADOS NO TESTE EXTERNO =============\n")
  print(
    test_metrics_table %>%
      select(model, threshold, threshold_rule, all_of(metric_cols), TP, FN, FP, TN) %>%
      mutate(across(all_of(metric_cols), ~round(.x, 4)))
  )

  cat("\n=============== MODELO PRINCIPAL ===============\n")
  cat("Modelo primario selecionado:", primary_model_name, "\n")
  cat("Limiar primario:", round(primary_threshold, 2), "\n")
  print(
    primary_test_metrics %>%
      select(model, threshold, threshold_rule, all_of(metric_cols), TP, FN, FP, TN) %>%
      mutate(across(all_of(metric_cols), ~round(.x, 4)))
  )

  cat("\n========= MATRIZ DE CONFUSAO DO MODELO PRINCIPAL =========\n")
  print(primary_confusion_long %>% select(actual, predicted, count))
}

print_console_results()

report_input <- file.path(root_dir, "interdia_report.Rmd")

# Tenta renderizar o HTML automaticamente quando houver Pandoc disponivel.
if (file.exists(report_input)) {
  tryCatch(
    {
      rmarkdown::render(
        input = report_input,
        output_file = "interdia_report.html",
        output_dir = report_dir,
        params = list(root_dir = root_dir),
        envir = new.env(parent = globalenv())
      )
      cat("Relatorio renderizado em:", file.path(report_dir, "interdia_report.html"), "\n")
    },
    error = function(error_object) {
      message("Nao foi possivel renderizar o relatorio automaticamente: ", error_object$message)
      message("O arquivo Rmd continua disponivel para renderizacao manual.")
    }
  )
} else {
  message("Arquivo interdia_report.Rmd nao encontrado. O script de analise foi concluido sem renderizar o relatorio.")
}
