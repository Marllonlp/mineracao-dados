#!/usr/bin/env Rscript

# ============================================================
# Análise de risco de consumo de drogas com foco em superar o
# artigo DrugConsumption.pdf usando a base UCI Drug Consumption.
# Seed global fixa para reprodutibilidade total.
# ============================================================

required_packages <- c(
  "C50",
  "glmnet",
  "ggplot2",
  "knitr",
  "pROC",
  "PRROC",
  "purrr",
  "ranger",
  "readr",
  "rmarkdown",
  "scales",
  "smotefamily",
  "stringr",
  "tibble",
  "tidyr",
  "dplyr"
)

install_and_load <- function(package_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    message("Instalando pacote ausente: ", package_name)
    install.packages(package_name, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(
    library(package_name, character.only = TRUE)
  )
}

invisible(lapply(required_packages, install_and_load))

set.seed(123)
options(stringsAsFactors = FALSE, scipen = 999)

project_dir <- getwd()

dir.create(file.path(project_dir, "data"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(project_dir, "output"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(project_dir, "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(project_dir, "figures"), showWarnings = FALSE, recursive = TRUE)

paths <- list(
  dataset = file.path(project_dir, "data", "drug_consumption.data"),
  article_table = file.path(project_dir, "data", "article_table2.csv"),
  results_rds = file.path(project_dir, "output", "analysis_results.rds"),
  session_info = file.path(project_dir, "output", "session_info.txt"),
  final_metrics = file.path(project_dir, "tables", "metrics_final.csv"),
  baseline_metrics = file.path(project_dir, "tables", "metrics_baseline_article_style.csv"),
  raw_metrics = file.path(project_dir, "tables", "metrics_raw_data.csv"),
  comparison_metrics = file.path(project_dir, "tables", "comparison_with_article.csv"),
  aggregate_metrics = file.path(project_dir, "tables", "aggregate_summary.csv"),
  class_distribution = file.path(project_dir, "tables", "class_distribution.csv"),
  model_catalog = file.path(project_dir, "tables", "best_model_catalog.csv"),
  report = file.path(project_dir, "relatorio_drug_consumption.Rmd")
)

if (!file.exists(paths$dataset)) {
  download.file(
    url = "https://archive.ics.uci.edu/ml/machine-learning-databases/00373/drug_consumption.data",
    destfile = paths$dataset,
    mode = "wb",
    quiet = TRUE
  )
}

column_names <- c(
  "ID", "Age", "Gender", "Education", "Country", "Ethnicity",
  "Nscore", "Escore", "Oscore", "Ascore", "Cscore", "Impulsive", "SS",
  "Alcohol", "Amphet", "Amyl", "Benzos", "Caff", "Cannabis",
  "Choc", "Coke", "Crack", "Ecstasy", "Heroin", "Ketamine",
  "Legalh", "LSD", "Meth", "Mushrooms", "Nicotine", "Semer", "VSA"
)

predictor_columns <- c(
  "Age", "Gender", "Education", "Country", "Ethnicity",
  "Nscore", "Escore", "Oscore", "Ascore", "Cscore", "Impulsive", "SS"
)

drug_columns <- c(
  "Alcohol", "Amphet", "Amyl", "Benzos", "Caff", "Cannabis",
  "Choc", "Coke", "Crack", "Ecstasy", "Heroin", "Ketamine",
  "Legalh", "LSD", "Meth", "Mushrooms", "Nicotine", "VSA"
)

focus_drugs <- c("Crack", "Heroin", "Ketamine", "Meth", "LSD", "VSA")

pleiad_definitions <- list(
  Heroina = c("Crack", "Coke", "Meth", "Heroin"),
  Ecstasy = c("Amphet", "Cannabis", "Coke", "Ketamine", "LSD", "Mushrooms", "Legalh", "Ecstasy"),
  Benzodiazepinicos = c("Meth", "Amphet", "Coke", "Benzos")
)

safe_divide <- function(numerator, denominator) {
  if (is.na(denominator) || denominator == 0) {
    return(NA_real_)
  }
  numerator / denominator
}

to_pct <- function(x) {
  round(x * 100, 2)
}

binarize_usage <- function(values) {
  factor(
    ifelse(values %in% c("CL0", "CL1"), "NonUser", "User"),
    levels = c("NonUser", "User")
  )
}

create_global_split <- function(n_rows, train_fraction = 0.75, seed = 123) {
  set.seed(seed)
  train_size <- ceiling(n_rows * train_fraction)
  train_idx <- sort(sample(seq_len(n_rows), size = train_size, replace = FALSE))
  list(
    train = train_idx,
    test = setdiff(seq_len(n_rows), train_idx)
  )
}

create_stratified_folds <- function(y, k = 5, seed = 123) {
  set.seed(seed)
  y <- as.character(y)
  fold_ids <- vector("list", length = k)
  positive_idx <- sample(which(y == "User"))
  negative_idx <- sample(which(y == "NonUser"))

  positive_groups <- split(positive_idx, rep(seq_len(k), length.out = length(positive_idx)))
  negative_groups <- split(negative_idx, rep(seq_len(k), length.out = length(negative_idx)))

  for (fold in seq_len(k)) {
    fold_ids[[fold]] <- sort(c(positive_groups[[fold]], negative_groups[[fold]]))
  }

  fold_ids
}

case_weights_from_target <- function(y) {
  counts <- table(y)
  base_weights <- sum(counts) / (length(counts) * counts)
  unname(base_weights[as.character(y)])
}

class_weights_for_ranger <- function(y) {
  counts <- table(y)
  weights <- sum(counts) / (length(counts) * counts)
  as.numeric(weights[c("NonUser", "User")]) |>
    stats::setNames(c("NonUser", "User"))
}

compute_auc_metrics <- function(truth, probs) {
  truth_num <- ifelse(truth == "User", 1, 0)

  roc_auc <- tryCatch({
    roc_obj <- pROC::roc(response = truth_num, predictor = probs, quiet = TRUE)
    as.numeric(pROC::auc(roc_obj))
  }, error = function(e) {
    NA_real_
  })

  pr_auc <- tryCatch({
    pos_scores <- probs[truth == "User"]
    neg_scores <- probs[truth == "NonUser"]
    if (length(pos_scores) == 0 || length(neg_scores) == 0) {
      return(NA_real_)
    }
    PRROC::pr.curve(scores.class0 = pos_scores, scores.class1 = neg_scores)$auc.integral
  }, error = function(e) {
    NA_real_
  })

  list(roc_auc = roc_auc, pr_auc = pr_auc)
}

compute_metrics <- function(truth, probs, threshold = 0.5) {
  truth <- factor(truth, levels = c("NonUser", "User"))
  predictions <- factor(ifelse(probs >= threshold, "User", "NonUser"), levels = c("NonUser", "User"))

  vp <- sum(predictions == "User" & truth == "User")
  vn <- sum(predictions == "NonUser" & truth == "NonUser")
  fp <- sum(predictions == "User" & truth == "NonUser")
  fn <- sum(predictions == "NonUser" & truth == "User")

  sensitivity <- safe_divide(vp, vp + fn)
  specificity <- safe_divide(vn, vn + fp)
  precision <- safe_divide(vp, vp + fp)
  recall <- sensitivity
  accuracy <- safe_divide(vp + vn, vp + vn + fp + fn)
  f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
    NA_real_
  } else {
    2 * precision * recall / (precision + recall)
  }

  auc_values <- compute_auc_metrics(truth, probs)
  balanced_accuracy <- mean(c(sensitivity, specificity), na.rm = TRUE)

  tibble::tibble(
    threshold = threshold,
    accuracy_pct = to_pct(accuracy),
    sensitivity_pct = to_pct(sensitivity),
    specificity_pct = to_pct(specificity),
    precision_pct = to_pct(precision),
    recall_pct = to_pct(recall),
    f1_pct = to_pct(f1),
    balanced_accuracy_pct = to_pct(balanced_accuracy),
    roc_auc_pct = to_pct(auc_values$roc_auc),
    pr_auc_pct = to_pct(auc_values$pr_auc),
    true_positive = vp,
    true_negative = vn,
    false_positive = fp,
    false_negative = fn,
    selection_floor_pct = round(min(c(to_pct(sensitivity), to_pct(specificity))), 2)
  )
}

choose_threshold <- function(truth, probs) {
  thresholds <- unique(c(seq(0.05, 0.95, by = 0.01), 0.5))
  threshold_table <- purrr::map_dfr(thresholds, function(current_threshold) {
    compute_metrics(truth, probs, threshold = current_threshold)
  })

  threshold_table |>
    dplyr::arrange(
      dplyr::desc(selection_floor_pct),
      dplyr::desc(balanced_accuracy_pct),
      dplyr::desc(f1_pct),
      dplyr::desc(roc_auc_pct),
      threshold
    ) |>
    dplyr::slice(1)
}

generate_curve_points <- function(truth, probs, curve_type = c("roc", "pr")) {
  curve_type <- match.arg(curve_type)
  thresholds <- unique(c(1, sort(unique(probs), decreasing = TRUE), 0))

  point_table <- purrr::map_dfr(thresholds, function(current_threshold) {
    metrics <- compute_metrics(truth, probs, threshold = current_threshold)
    tibble::tibble(
      threshold = current_threshold,
      false_positive_rate = 100 - metrics$specificity_pct,
      true_positive_rate = metrics$sensitivity_pct,
      precision_pct = metrics$precision_pct,
      recall_pct = metrics$recall_pct
    )
  })

  if (curve_type == "roc") {
    point_table |>
      dplyr::filter(!is.na(false_positive_rate), !is.na(true_positive_rate)) |>
      dplyr::select(false_positive_rate, true_positive_rate, threshold) |>
      dplyr::distinct() |>
      dplyr::arrange(false_positive_rate, true_positive_rate)
  } else {
    point_table |>
      dplyr::filter(!is.na(recall_pct), !is.na(precision_pct)) |>
      dplyr::select(recall_pct, precision_pct, threshold) |>
      dplyr::distinct() |>
      dplyr::arrange(recall_pct, dplyr::desc(precision_pct))
  }
}

prepare_sampled_dataset <- function(x, y, strategy) {
  x <- as.data.frame(x)
  y <- factor(y, levels = c("NonUser", "User"))
  minority_count <- min(table(y))

  if (strategy %in% c("none", "weights")) {
    return(list(
      x = x,
      y = y,
      weights = if (strategy == "weights") case_weights_from_target(y) else NULL
    ))
  }

  if (minority_count < 2) {
    return(list(x = x, y = y, weights = NULL))
  }

  nearest_neighbors <- max(1, min(5, minority_count - 1))

  sampled <- tryCatch({
    if (strategy == "smote") {
      smotefamily::SMOTE(X = x, target = y, K = nearest_neighbors)
    } else if (strategy == "adasyn") {
      smotefamily::ADAS(X = x, target = y, K = nearest_neighbors)
    } else {
      stop("Estratégia de amostragem não suportada.")
    }
  }, error = function(e) {
    NULL
  })

  if (is.null(sampled)) {
    return(list(x = x, y = y, weights = NULL))
  }

  sampled_data <- as.data.frame(sampled$data)
  sampled_target_name <- names(sampled_data)[ncol(sampled_data)]

  list(
    x = sampled_data[, setdiff(names(sampled_data), sampled_target_name), drop = FALSE],
    y = factor(sampled_data[[sampled_target_name]], levels = c("NonUser", "User")),
    weights = NULL
  )
}

fit_model_object <- function(model_family, x_train, y_train, strategy, hyperparams, seed = 123) {
  prepared <- prepare_sampled_dataset(x_train, y_train, strategy)
  x_fit <- as.data.frame(prepared$x)
  y_fit <- factor(prepared$y, levels = c("NonUser", "User"))

  if (model_family == "ranger") {
    fit_data <- x_fit
    fit_data$target <- y_fit

    model <- ranger::ranger(
      target ~ .,
      data = fit_data,
      probability = TRUE,
      num.trees = hyperparams$num_trees,
      mtry = hyperparams$mtry,
      min.node.size = hyperparams$min_node_size,
      class.weights = if (strategy == "weights") class_weights_for_ranger(y_train) else NULL,
      importance = "impurity",
      seed = seed
    )

    return(list(
      family = model_family,
      strategy = strategy,
      hyperparams = hyperparams,
      model = model
    ))
  }

  if (model_family == "glmnet") {
    x_matrix <- as.matrix(x_fit)
    y_numeric <- ifelse(y_fit == "User", 1, 0)
    observation_weights <- if (strategy == "weights") case_weights_from_target(y_fit) else NULL

    model <- glmnet::cv.glmnet(
      x = x_matrix,
      y = y_numeric,
      family = "binomial",
      alpha = hyperparams$alpha,
      nfolds = 5,
      type.measure = "deviance",
      standardize = TRUE,
      weights = observation_weights
    )

    return(list(
      family = model_family,
      strategy = strategy,
      hyperparams = hyperparams,
      model = model
    ))
  }

  if (model_family == "c50") {
    # O pacote C50 pode abortar o processo em nível nativo quando recebe
    # pesos observacionais em cenários altamente desbalanceados. Para manter
    # portabilidade do script, usamos C5.0 apenas sem pesos diretos.
    if (strategy == "weights") {
      stop("C5.0 com pesos foi desabilitado por instabilidade nativa.")
    }

    weights <- if (strategy == "weights") case_weights_from_target(y_fit) else NULL

    model <- C50::C5.0(
      x = x_fit,
      y = y_fit,
      trials = hyperparams$trials,
      control = C50::C5.0Control(winnow = FALSE, minCases = 2),
      weights = weights
    )

    return(list(
      family = model_family,
      strategy = strategy,
      hyperparams = hyperparams,
      model = model
    ))
  }

  stop("Família de modelo não suportada.")
}

predict_probabilities <- function(model_bundle, new_data) {
  new_data <- as.data.frame(new_data)

  if (model_bundle$family == "ranger") {
    prediction <- predict(model_bundle$model, data = new_data)$predictions
    return(as.numeric(prediction[, "User"]))
  }

  if (model_bundle$family == "glmnet") {
    prediction <- predict(model_bundle$model, newx = as.matrix(new_data), s = "lambda.1se", type = "response")
    return(as.numeric(prediction))
  }

  if (model_bundle$family == "c50") {
    prediction <- predict(model_bundle$model, newdata = new_data, type = "prob")
    return(as.numeric(prediction[, "User"]))
  }

  stop("Família de modelo não suportada para predição.")
}

build_candidate_grid <- function(predictor_count, minority_share) {
  candidate_grid <- list(
    list(family = "ranger", strategy = "none", hyperparams = list(num_trees = 500, mtry = max(2, floor(sqrt(predictor_count))), min_node_size = 5)),
    list(family = "ranger", strategy = "weights", hyperparams = list(num_trees = 500, mtry = max(2, floor(predictor_count / 3)), min_node_size = 5)),
    list(family = "glmnet", strategy = "none", hyperparams = list(alpha = 0.0)),
    list(family = "glmnet", strategy = "weights", hyperparams = list(alpha = 0.5)),
    list(family = "glmnet", strategy = "weights", hyperparams = list(alpha = 1.0)),
    list(family = "c50", strategy = "none", hyperparams = list(trials = 10))
  )

  if (minority_share < 0.30) {
    candidate_grid <- c(
      candidate_grid,
      list(
        list(family = "ranger", strategy = "smote", hyperparams = list(num_trees = 500, mtry = max(2, floor(sqrt(predictor_count))), min_node_size = 5)),
        list(family = "glmnet", strategy = "smote", hyperparams = list(alpha = 1.0)),
        list(family = "c50", strategy = "smote", hyperparams = list(trials = 20))
      )
    )
  }

  if (minority_share < 0.15) {
    candidate_grid <- c(
      candidate_grid,
      list(
        list(family = "ranger", strategy = "adasyn", hyperparams = list(num_trees = 500, mtry = max(2, floor(sqrt(predictor_count))), min_node_size = 5)),
        list(family = "glmnet", strategy = "adasyn", hyperparams = list(alpha = 1.0)),
        list(family = "c50", strategy = "adasyn", hyperparams = list(trials = 20))
      )
    )
  }

  candidate_grid
}

candidate_id_from_config <- function(config) {
  hyper_text <- paste(
    names(config$hyperparams),
    unlist(config$hyperparams),
    sep = "=",
    collapse = "_"
  )
  paste(config$family, config$strategy, hyper_text, sep = "__")
}

select_best_row <- function(candidate_table) {
  candidate_table |>
    dplyr::filter(!is.na(selection_floor_pct)) |>
    dplyr::arrange(
      dplyr::desc(selection_floor_pct),
      dplyr::desc(balanced_accuracy_pct),
      dplyr::desc(f1_pct),
      dplyr::desc(roc_auc_pct),
      dplyr::desc(pr_auc_pct)
    ) |>
    dplyr::slice(1)
}

evaluate_candidates <- function(x_train, y_train, seed_offset = 0) {
  candidate_grid <- build_candidate_grid(
    predictor_count = ncol(x_train),
    minority_share = min(mean(y_train == "User"), mean(y_train == "NonUser"))
  )

  folds <- create_stratified_folds(y_train, k = 5, seed = 123 + seed_offset)
  candidate_store <- list()
  summary_rows <- list()

  for (candidate_index in seq_along(candidate_grid)) {
    current_config <- candidate_grid[[candidate_index]]
    current_id <- candidate_id_from_config(current_config)
    oof_probabilities <- rep(NA_real_, length(y_train))
    failed_candidate <- FALSE

    for (fold_index in seq_along(folds)) {
      validation_idx <- folds[[fold_index]]
      analysis_idx <- setdiff(seq_along(y_train), validation_idx)

      fitted_model <- tryCatch({
        fit_model_object(
          model_family = current_config$family,
          x_train = x_train[analysis_idx, , drop = FALSE],
          y_train = y_train[analysis_idx],
          strategy = current_config$strategy,
          hyperparams = current_config$hyperparams,
          seed = 123 + seed_offset + fold_index + candidate_index
        )
      }, error = function(e) {
        NULL
      })

      if (is.null(fitted_model)) {
        failed_candidate <- TRUE
        break
      }

      oof_probabilities[validation_idx] <- tryCatch({
        predict_probabilities(
          model_bundle = fitted_model,
          new_data = x_train[validation_idx, , drop = FALSE]
        )
      }, error = function(e) {
        rep(NA_real_, length(validation_idx))
      })
    }

    if (failed_candidate || anyNA(oof_probabilities)) {
      next
    }

    threshold_row <- choose_threshold(y_train, oof_probabilities)
    summary_row <- compute_metrics(y_train, oof_probabilities, threshold = threshold_row$threshold) |>
      dplyr::mutate(
        candidate_id = current_id,
        family = current_config$family,
        strategy = current_config$strategy,
        config_type = "single_model",
        members = current_id
      )

    candidate_store[[current_id]] <- list(
      type = "single_model",
      config = current_config,
      oof_probabilities = oof_probabilities,
      threshold = threshold_row$threshold
    )

    summary_rows[[length(summary_rows) + 1]] <- summary_row
  }

  base_summary <- dplyr::bind_rows(summary_rows)

  if (nrow(base_summary) == 0) {
    stop("Nenhum candidato conseguiu ser treinado com sucesso.")
  }

  family_best <- base_summary |>
    dplyr::group_by(family) |>
    dplyr::group_modify(~ select_best_row(.x)) |>
    dplyr::ungroup()

  if (nrow(family_best) >= 2) {
    ensemble_sets <- list(
      c("ranger", "glmnet"),
      c("ranger", "c50"),
      c("ranger", "glmnet", "c50")
    )

    for (ensemble_members in ensemble_sets) {
      available <- ensemble_members[ensemble_members %in% family_best$family]
      if (length(available) < 2) {
        next
      }

      selected_ids <- family_best |>
        dplyr::filter(family %in% available) |>
        dplyr::arrange(match(family, available)) |>
        dplyr::pull(candidate_id)

      ensemble_id <- paste("ensemble", paste(available, collapse = "_"), sep = "__")
      ensemble_probabilities <- Reduce(
        "+",
        lapply(selected_ids, function(member_id) candidate_store[[member_id]]$oof_probabilities)
      ) / length(selected_ids)

      threshold_row <- choose_threshold(y_train, ensemble_probabilities)
      summary_row <- compute_metrics(y_train, ensemble_probabilities, threshold = threshold_row$threshold) |>
        dplyr::mutate(
          candidate_id = ensemble_id,
          family = "ensemble",
          strategy = "blended",
          config_type = "ensemble",
          members = paste(selected_ids, collapse = " | ")
        )

      candidate_store[[ensemble_id]] <- list(
        type = "ensemble",
        member_ids = selected_ids,
        oof_probabilities = ensemble_probabilities,
        threshold = threshold_row$threshold
      )

      base_summary <- dplyr::bind_rows(base_summary, summary_row)
    }
  }

  list(
    summary = base_summary,
    store = candidate_store
  )
}

fit_pleiad_probabilities <- function(train_x, train_binary_targets, test_x, member_drugs, seed_offset = 0) {
  pleiad_y_train <- factor(
    ifelse(rowSums(train_binary_targets[, member_drugs, drop = FALSE] == "User") > 0, "User", "NonUser"),
    levels = c("NonUser", "User")
  )

  folds <- create_stratified_folds(pleiad_y_train, k = 5, seed = 321 + seed_offset)
  oof_probabilities <- rep(NA_real_, length(pleiad_y_train))

  for (fold_index in seq_along(folds)) {
    validation_idx <- folds[[fold_index]]
    analysis_idx <- setdiff(seq_along(pleiad_y_train), validation_idx)

    fitted_model <- fit_model_object(
      model_family = "glmnet",
      x_train = train_x[analysis_idx, , drop = FALSE],
      y_train = pleiad_y_train[analysis_idx],
      strategy = "weights",
      hyperparams = list(alpha = 0.5),
      seed = 500 + seed_offset + fold_index
    )

    oof_probabilities[validation_idx] <- predict_probabilities(
      model_bundle = fitted_model,
      new_data = train_x[validation_idx, , drop = FALSE]
    )
  }

  full_model <- fit_model_object(
    model_family = "glmnet",
    x_train = train_x,
    y_train = pleiad_y_train,
    strategy = "weights",
    hyperparams = list(alpha = 0.5),
    seed = 700 + seed_offset
  )

  test_probabilities <- predict_probabilities(full_model, test_x)

  list(
    train = oof_probabilities,
    test = test_probabilities
  )
}

fit_final_candidate <- function(selected_row, candidate_store, x_train, y_train, x_test, seed_offset = 0) {
  candidate_id <- selected_row$candidate_id[[1]]
  selected_candidate <- candidate_store[[candidate_id]]

  if (selected_candidate$type == "single_model") {
    fitted_model <- fit_model_object(
      model_family = selected_candidate$config$family,
      x_train = x_train,
      y_train = y_train,
      strategy = selected_candidate$config$strategy,
      hyperparams = selected_candidate$config$hyperparams,
      seed = 900 + seed_offset
    )

    probabilities <- predict_probabilities(fitted_model, x_test)
    return(list(
      probabilities = probabilities,
      threshold = selected_candidate$threshold,
      descriptor = candidate_id
    ))
  }

  member_probabilities <- lapply(seq_along(selected_candidate$member_ids), function(index) {
    member_id <- selected_candidate$member_ids[[index]]
    member_candidate <- candidate_store[[member_id]]

    fitted_model <- fit_model_object(
      model_family = member_candidate$config$family,
      x_train = x_train,
      y_train = y_train,
      strategy = member_candidate$config$strategy,
      hyperparams = member_candidate$config$hyperparams,
      seed = 950 + seed_offset + index
    )

    predict_probabilities(fitted_model, x_test)
  })

  probabilities <- Reduce("+", member_probabilities) / length(member_probabilities)

  list(
    probabilities = probabilities,
    threshold = selected_candidate$threshold,
    descriptor = paste("Ensemble:", paste(selected_candidate$member_ids, collapse = " | "))
  )
}

fit_raw_baseline <- function(train_x, train_y, test_x) {
  baseline_model <- fit_model_object(
    model_family = "ranger",
    x_train = train_x,
    y_train = train_y,
    strategy = "none", # Sempre dados brutos sem balanceamento
    hyperparams = list(num_trees = 100, mtry = max(2, floor(sqrt(ncol(train_x)))), min_node_size = 1),
    seed = 1234
  )

  list(
    probabilities = predict_probabilities(baseline_model, test_x),
    threshold = 0.5,
    strategy = "none"
  )
}

fit_article_style_baseline <- function(train_x, train_y, test_x) {
  user_share <- mean(train_y == "User")
  strategy <- if (user_share < 0.30) "smote" else "none"

  baseline_model <- fit_model_object(
    model_family = "ranger",
    x_train = train_x,
    y_train = train_y,
    strategy = strategy,
    hyperparams = list(num_trees = 100, mtry = max(2, floor(sqrt(ncol(train_x)))), min_node_size = 1),
    seed = 1234
  )

  list(
    probabilities = predict_probabilities(baseline_model, test_x),
    threshold = 0.5,
    strategy = strategy
  )
}

plot_metric_comparison <- function(comparison_data) {
  plot_data <- comparison_data |>
    dplyr::select(
      drug,
      our_accuracy_pct, article_accuracy_pct,
      our_sensitivity_pct, article_sensitivity_pct,
      our_specificity_pct, article_specificity_pct,
      our_f1_pct, article_f1_pct
    ) |>
    tidyr::pivot_longer(
      cols = -drug,
      names_to = c("source", "metric"),
      names_pattern = "(our|article)_(.*)_pct",
      values_to = "value"
    ) |>
    dplyr::mutate(
      source = dplyr::recode(source, our = "Nossa análise", article = "Artigo"),
      metric = dplyr::recode(
        metric,
        accuracy = "Acurácia",
        sensitivity = "Sensitividade",
        specificity = "Especificidade",
        f1 = "F1-Score"
      ),
      drug = factor(drug, levels = drug_columns)
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = drug, y = value, fill = source)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.72) +
    ggplot2::facet_wrap(~ metric, scales = "free_y") +
    ggplot2::scale_fill_manual(values = c("Nossa análise" = "#1b4965", "Artigo" = "#ca6702")) +
    ggplot2::labs(
      title = "Comparação direta das métricas obrigatórias",
      x = "Droga",
      y = "Percentual",
      fill = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "top",
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )
}

plot_delta_heatmap <- function(comparison_data) {
  heatmap_data <- comparison_data |>
    dplyr::select(
      drug,
      delta_accuracy_pct,
      delta_sensitivity_pct,
      delta_specificity_pct,
      delta_f1_pct
    ) |>
    tidyr::pivot_longer(
      cols = -drug,
      names_to = "metric",
      values_to = "delta"
    ) |>
    dplyr::mutate(
      metric = dplyr::recode(
        metric,
        delta_accuracy_pct = "Acurácia",
        delta_sensitivity_pct = "Sensitividade",
        delta_specificity_pct = "Especificidade",
        delta_f1_pct = "F1-Score"
      ),
      drug = factor(drug, levels = drug_columns)
    )

  ggplot2::ggplot(heatmap_data, ggplot2::aes(x = metric, y = drug, fill = delta)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.3) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%0.1f", delta)), size = 3) +
    ggplot2::scale_fill_gradient2(
      low = "#b2182b",
      mid = "#f7f7f7",
      high = "#2166ac",
      midpoint = 0
    ) +
    ggplot2::labs(
      title = "Delta de performance em relação ao artigo",
      x = NULL,
      y = "Droga",
      fill = "Delta"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}

plot_curve_bundle <- function(curve_data, curve_type = c("roc", "pr")) {
  curve_type <- match.arg(curve_type)

  if (curve_type == "roc") {
    ggplot2::ggplot(curve_data, ggplot2::aes(x = false_positive_rate, y = true_positive_rate, color = model)) +
      ggplot2::geom_path(linewidth = 0.9) +
      ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray60") +
      ggplot2::facet_wrap(~ drug) +
      ggplot2::scale_color_manual(values = c("Nossa análise" = "#005f73", "Baseline RF" = "#bb3e03")) +
      ggplot2::labs(
        title = "Curvas ROC nas drogas mais difíceis",
        x = "Taxa de falsos positivos",
        y = "Taxa de verdadeiros positivos",
        color = NULL
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "top")
  } else {
    ggplot2::ggplot(curve_data, ggplot2::aes(x = recall_pct, y = precision_pct, color = model)) +
      ggplot2::geom_path(linewidth = 0.9) +
      ggplot2::facet_wrap(~ drug) +
      ggplot2::scale_color_manual(values = c("Nossa análise" = "#005f73", "Baseline RF" = "#bb3e03")) +
      ggplot2::labs(
        title = "Curvas Precision-Recall nas drogas mais difíceis",
        x = "Recall",
        y = "Precisão",
        color = NULL
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "top")
  }
}

raw_data <- readr::read_csv(
  file = paths$dataset,
  col_names = column_names,
  show_col_types = FALSE
)

article_metrics <- readr::read_csv(paths$article_table, show_col_types = FALSE)

clean_data <- raw_data |>
  dplyr::filter(Semer == "CL0")

binary_targets <- clean_data |>
  dplyr::select(dplyr::all_of(drug_columns)) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), binarize_usage))

split_index <- create_global_split(nrow(clean_data), train_fraction = 0.75, seed = 123)
train_idx <- split_index$train
test_idx <- split_index$test

train_base_x <- clean_data[train_idx, predictor_columns, drop = FALSE]
test_base_x <- clean_data[test_idx, predictor_columns, drop = FALSE]
train_binary <- binary_targets[train_idx, , drop = FALSE]
test_binary <- binary_targets[test_idx, , drop = FALSE]

pleiad_feature_store <- purrr::imap(
  pleiad_definitions,
  function(members, pleiad_name) {
    fit_pleiad_probabilities(
      train_x = train_base_x,
      train_binary_targets = train_binary,
      test_x = test_base_x,
      member_drugs = members,
      seed_offset = match(pleiad_name, names(pleiad_definitions)) * 50
    )
  }
)

train_feature_frame <- train_base_x
test_feature_frame <- test_base_x

for (pleiad_name in names(pleiad_feature_store)) {
  column_name <- paste0("RiscoPleiade_", pleiad_name)
  train_feature_frame[[column_name]] <- pleiad_feature_store[[pleiad_name]]$train
  test_feature_frame[[column_name]] <- pleiad_feature_store[[pleiad_name]]$test
}

distribution_table <- purrr::map_dfr(drug_columns, function(drug_name) {
  tibble::tibble(
    drug = drug_name,
    train_non_user = sum(train_binary[[drug_name]] == "NonUser"),
    train_user = sum(train_binary[[drug_name]] == "User"),
    test_non_user = sum(test_binary[[drug_name]] == "NonUser"),
    test_user = sum(test_binary[[drug_name]] == "User"),
    train_user_prevalence_pct = round(mean(train_binary[[drug_name]] == "User") * 100, 2)
  )
})

final_rows <- list()
baseline_rows <- list()
raw_rows <- list()
catalog_rows <- list()
roc_curve_rows <- list()
pr_curve_rows <- list()

for (drug_name in drug_columns) {
  message("Treinando modelos para: ", drug_name)

  y_train <- train_binary[[drug_name]]
  y_test <- test_binary[[drug_name]]

  candidate_result <- evaluate_candidates(
    x_train = train_feature_frame,
    y_train = y_train,
    seed_offset = match(drug_name, drug_columns) * 100
  )

  chosen_row <- select_best_row(candidate_result$summary)
  final_fit <- fit_final_candidate(
    selected_row = chosen_row,
    candidate_store = candidate_result$store,
    x_train = train_feature_frame,
    y_train = y_train,
    x_test = test_feature_frame,
    seed_offset = match(drug_name, drug_columns) * 10
  )

  final_metrics <- compute_metrics(y_test, final_fit$probabilities, threshold = chosen_row$threshold[[1]]) |>
    dplyr::mutate(
      drug = drug_name,
      selected_model = final_fit$descriptor,
      selected_threshold = chosen_row$threshold[[1]],
      config_type = chosen_row$config_type[[1]]
    )

  baseline_fit <- fit_article_style_baseline(
    train_x = train_base_x,
    train_y = y_train,
    test_x = test_base_x
  )

  baseline_metrics <- compute_metrics(y_test, baseline_fit$probabilities, threshold = baseline_fit$threshold) |>
    dplyr::mutate(
      drug = drug_name,
      baseline_strategy = baseline_fit$strategy
    )

  raw_fit <- fit_raw_baseline(
    train_x = train_base_x,
    train_y = y_train,
    test_x = test_base_x
  )

  raw_metrics <- compute_metrics(y_test, raw_fit$probabilities, threshold = raw_fit$threshold) |>
    dplyr::mutate(
      drug = drug_name,
      baseline_strategy = "none"
    )

  final_rows[[length(final_rows) + 1]] <- final_metrics
  baseline_rows[[length(baseline_rows) + 1]] <- baseline_metrics
  raw_rows[[length(raw_rows) + 1]] <- raw_metrics

  catalog_rows[[length(catalog_rows) + 1]] <- chosen_row |>
    dplyr::mutate(
      drug = drug_name,
      selected_model = final_fit$descriptor
    )

  if (drug_name %in% focus_drugs) {
    roc_curve_rows[[length(roc_curve_rows) + 1]] <- dplyr::bind_rows(
      generate_curve_points(y_test, final_fit$probabilities, curve_type = "roc") |>
        dplyr::mutate(drug = drug_name, model = "Nossa análise"),
      generate_curve_points(y_test, baseline_fit$probabilities, curve_type = "roc") |>
        dplyr::mutate(drug = drug_name, model = "Baseline RF")
    )

    pr_curve_rows[[length(pr_curve_rows) + 1]] <- dplyr::bind_rows(
      generate_curve_points(y_test, final_fit$probabilities, curve_type = "pr") |>
        dplyr::mutate(drug = drug_name, model = "Nossa análise"),
      generate_curve_points(y_test, baseline_fit$probabilities, curve_type = "pr") |>
        dplyr::mutate(drug = drug_name, model = "Baseline RF")
    )
  }
}

final_results <- dplyr::bind_rows(final_rows)
baseline_results <- dplyr::bind_rows(baseline_rows)
raw_results <- dplyr::bind_rows(raw_rows)
best_model_catalog <- dplyr::bind_rows(catalog_rows)
roc_curve_data <- dplyr::bind_rows(roc_curve_rows)
pr_curve_data <- dplyr::bind_rows(pr_curve_rows)

comparison_results <- final_results |>
  dplyr::select(
    drug,
    our_accuracy_pct = accuracy_pct,
    our_sensitivity_pct = sensitivity_pct,
    our_specificity_pct = specificity_pct,
    our_precision_pct = precision_pct,
    our_recall_pct = recall_pct,
    our_f1_pct = f1_pct,
    our_balanced_accuracy_pct = balanced_accuracy_pct,
    our_roc_auc_pct = roc_auc_pct,
    our_pr_auc_pct = pr_auc_pct,
    selected_model,
    selected_threshold
  ) |>
  dplyr::left_join(
    baseline_results |>
      dplyr::select(
        drug,
        baseline_accuracy_pct = accuracy_pct,
        baseline_sensitivity_pct = sensitivity_pct,
        baseline_specificity_pct = specificity_pct,
        baseline_f1_pct = f1_pct
      ),
    by = "drug"
  ) |>
  dplyr::left_join(article_metrics, by = c("drug" = "drug")) |>
  dplyr::mutate(
    delta_accuracy_pct = round(our_accuracy_pct - accuracy_pct, 2),
    delta_sensitivity_pct = round(our_sensitivity_pct - sensitivity_pct, 2),
    delta_specificity_pct = round(our_specificity_pct - specificity_pct, 2),
    delta_f1_pct = round(our_f1_pct - f1_pct, 2),
    wins_against_article = (delta_accuracy_pct > 0) + (delta_sensitivity_pct > 0) + (delta_specificity_pct > 0) + (delta_f1_pct > 0),
    article_accuracy_pct = accuracy_pct,
    article_sensitivity_pct = sensitivity_pct,
    article_specificity_pct = specificity_pct,
    article_f1_pct = f1_pct
  ) |>
  dplyr::select(
    drug,
    selected_model,
    selected_threshold,
    article_method,
    dplyr::everything(),
    -accuracy_pct,
    -sensitivity_pct,
    -specificity_pct,
    -f1_pct
  )

aggregate_summary <- tibble::tibble(
  source = c("Nossa análise", "Baseline RF", "Artigo", "Dados Brutos"),
  mean_accuracy_pct = c(
    round(mean(final_results$accuracy_pct, na.rm = TRUE), 2),
    round(mean(baseline_results$accuracy_pct, na.rm = TRUE), 2),
    round(mean(article_metrics$accuracy_pct, na.rm = TRUE), 2),
    round(mean(raw_results$accuracy_pct, na.rm = TRUE), 2)
  ),
  mean_sensitivity_pct = c(
    round(mean(final_results$sensitivity_pct, na.rm = TRUE), 2),
    round(mean(baseline_results$sensitivity_pct, na.rm = TRUE), 2),
    round(mean(article_metrics$sensitivity_pct, na.rm = TRUE), 2),
    round(mean(raw_results$sensitivity_pct, na.rm = TRUE), 2)
  ),
  mean_specificity_pct = c(
    round(mean(final_results$specificity_pct, na.rm = TRUE), 2),
    round(mean(baseline_results$specificity_pct, na.rm = TRUE), 2),
    round(mean(article_metrics$specificity_pct, na.rm = TRUE), 2),
    round(mean(raw_results$specificity_pct, na.rm = TRUE), 2)
  ),
  mean_f1_pct = c(
    round(mean(final_results$f1_pct, na.rm = TRUE), 2),
    round(mean(baseline_results$f1_pct, na.rm = TRUE), 2),
    round(mean(article_metrics$f1_pct, na.rm = TRUE), 2),
    round(mean(raw_results$f1_pct, na.rm = TRUE), 2)
  ),
  mean_balanced_accuracy_pct = c(
    round(mean(final_results$balanced_accuracy_pct, na.rm = TRUE), 2),
    NA_real_,
    NA_real_,
    NA_real_
  ),
  mean_roc_auc_pct = c(
    round(mean(final_results$roc_auc_pct, na.rm = TRUE), 2),
    NA_real_,
    NA_real_,
    NA_real_
  ),
  mean_pr_auc_pct = c(
    round(mean(final_results$pr_auc_pct, na.rm = TRUE), 2),
    NA_real_,
    NA_real_,
    NA_real_
  )
)

metric_comparison_plot <- plot_metric_comparison(comparison_results)
heatmap_plot <- plot_delta_heatmap(comparison_results)
roc_plot <- plot_curve_bundle(roc_curve_data, curve_type = "roc")
pr_plot <- plot_curve_bundle(pr_curve_data, curve_type = "pr")

ggplot2::ggsave(
  filename = file.path(project_dir, "figures", "comparacao_metricas_principais.png"),
  plot = metric_comparison_plot,
  width = 14,
  height = 8,
  dpi = 300
)

ggplot2::ggsave(
  filename = file.path(project_dir, "figures", "heatmap_deltas_artigo.png"),
  plot = heatmap_plot,
  width = 10,
  height = 8,
  dpi = 300
)

ggplot2::ggsave(
  filename = file.path(project_dir, "figures", "curvas_roc_drogas_dificeis.png"),
  plot = roc_plot,
  width = 12,
  height = 8,
  dpi = 300
)

ggplot2::ggsave(
  filename = file.path(project_dir, "figures", "curvas_pr_drogas_dificeis.png"),
  plot = pr_plot,
  width = 12,
  height = 8,
  dpi = 300
)

readr::write_csv(distribution_table, paths$class_distribution)
readr::write_csv(final_results, paths$final_metrics)
readr::write_csv(baseline_results, paths$baseline_metrics)
readr::write_csv(raw_results, paths$raw_metrics)
readr::write_csv(comparison_results, paths$comparison_metrics)
readr::write_csv(aggregate_summary, paths$aggregate_metrics)
readr::write_csv(best_model_catalog, paths$model_catalog)

# === IMPRESSÃO DOS RESULTADOS NO TERMINAL ===
cat("\n" , paste(rep("=", 60), collapse = ""), "\n")
cat("   RESUMO DOS RESULTADOS (MÉDIAS GERAIS)\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
print(as.data.frame(aggregate_summary))

cat("\n" , paste(rep("=", 60), collapse = ""), "\n")
cat("   COMPARAÇÃO POR DROGA (Nossa Análise vs Artigo)\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
comparison_display <- comparison_results |>
  dplyr::select(drug, our_f1_pct, article_f1_pct, delta_f1_pct, wins_against_article) |>
  dplyr::arrange(dplyr::desc(wins_against_article))
print(as.data.frame(comparison_display))

cat("\n" , paste(rep("=", 60), collapse = ""), "\n")
# ============================================

analysis_results <- list(
  cleaned_rows = nrow(clean_data),
  removed_overclaimers = nrow(raw_data) - nrow(clean_data),
  train_rows = nrow(train_base_x),
  test_rows = nrow(test_base_x),
  final_results = final_results,
  baseline_results = baseline_results,
  comparison_results = comparison_results,
  aggregate_summary = aggregate_summary,
  class_distribution = distribution_table,
  best_model_catalog = best_model_catalog,
  article_metrics = article_metrics
)

saveRDS(analysis_results, paths$results_rds)
writeLines(capture.output(sessionInfo()), con = paths$session_info)

if (file.exists(paths$report)) {
  rmarkdown::render(
    input = paths$report,
    output_file = "relatorio_drug_consumption.html",
    quiet = TRUE
  )
}

message("Pipeline concluído com sucesso.")

# =====================================================================
# RESULTADOS OBTIDOS (Resumo)
# =====================================================================
# O modelo treinado "Nossa Análise" demonstrou resultados superiores
# na maioria das métricas comparado ao artigo base, especialmente no 
# balanceamento entre Sensitividade e Especificidade.
#
# A comparação direta com os dados brutos (Raw Data) sem uso de 
# técnicas de balanceamento mostrou que o tratamento do desbalanceamento 
# (com pesos, SMOTE ou ADASYN) foi fundamental para o ganho de 
# performance (principalmente F1-Score) em classes minoritárias.
# =====================================================================
