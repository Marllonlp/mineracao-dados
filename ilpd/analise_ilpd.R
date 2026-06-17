# ============================================================
# Analise de Dados do Indian Liver Patient Dataset - ILPD
# Arquivo principal: analise_ilpd.R
# ============================================================
# Este script executa uma analise completa de classificacao para
# predicao de doenca hepatica no dataset ILPD.
#
# Produtos gerados:
# - tabelas CSV na pasta resultados/
# - graficos PNG na pasta graficos/
# - resultados para tres cenarios: base completa, homens e mulheres
# ============================================================

# -----------------------------
# 1. Configuracoes iniciais
# -----------------------------

options(stringsAsFactors = FALSE)
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Semente fixa para garantir reprodutibilidade dos resultados.
set.seed(123)

# Pacotes utilizados no projeto.
pacotes <- c(
  "tidyverse",
  "caret",
  "ranger",
  "e1071",
  "kernlab",
  "naivebayes",
  "xgboost",
  "pROC",
  "vip",
  "scales"
)

# Verifica primeiro todos os pacotes ja instalados.
# Assim, o R instala somente o que realmente estiver faltando,
# evitando reinstalacoes desnecessarias e acelerando a execucao.
instalar_e_carregar_pacotes <- function(pacotes) {
  pacotes_instalados <- rownames(installed.packages())
  pacotes_faltantes <- setdiff(pacotes, pacotes_instalados)

  if (length(pacotes_faltantes) > 0) {
    message("Instalando pacotes ausentes: ", paste(pacotes_faltantes, collapse = ", "))
    install.packages(pacotes_faltantes, dependencies = TRUE)
  } else {
    message("Todos os pacotes necessarios ja estao instalados.")
  }

  invisible(
    lapply(
      pacotes,
      function(pacote) {
        suppressPackageStartupMessages(
          library(pacote, character.only = TRUE)
        )
      }
    )
  )
}

instalar_e_carregar_pacotes(pacotes)

# Criacao das pastas obrigatorias.
dir.create("dados", showWarnings = FALSE, recursive = TRUE)
dir.create("resultados", showWarnings = FALSE, recursive = TRUE)
dir.create("graficos", showWarnings = FALSE, recursive = TRUE)


# -----------------------------
# 2. Funcoes auxiliares
# -----------------------------

limpar_nome_arquivo <- function(texto) {
  texto <- iconv(texto, from = "", to = "ASCII//TRANSLIT")
  texto <- gsub("[^A-Za-z0-9]+", "_", texto)
  texto <- gsub("_+", "_", texto)
  texto <- gsub("^_|_$", "", texto)
  tolower(texto)
}

salvar_csv <- function(objeto, caminho) {
  readr::write_csv(objeto, caminho, na = "")
}

calcular_resumo_numerico <- function(base) {
  variaveis_numericas <- names(dplyr::select(base, where(is.numeric)))

  purrr::map_dfr(variaveis_numericas, function(var) {
    x <- base[[var]]
    tibble::tibble(
      Variavel = var,
      Media = mean(x, na.rm = TRUE),
      Mediana = median(x, na.rm = TRUE),
      Desvio_Padrao = sd(x, na.rm = TRUE),
      Minimo = min(x, na.rm = TRUE),
      Q1 = as.numeric(stats::quantile(x, 0.25, na.rm = TRUE)),
      Q3 = as.numeric(stats::quantile(x, 0.75, na.rm = TRUE)),
      Maximo = max(x, na.rm = TRUE),
      Ausentes = sum(is.na(x))
    )
  })
}

calcular_metricas <- function(modelo, teste, nome_modelo, nome_cenario) {
  predicao <- predict(modelo, newdata = teste, na.action = na.pass)
  predicao <- factor(predicao, levels = levels(teste$Selector))

  probabilidades <- tryCatch(
    predict(modelo, newdata = teste, type = "prob", na.action = na.pass),
    error = function(e) NULL
  )

  if (!is.null(probabilidades) && "Doente" %in% names(probabilidades)) {
    prob_doente <- probabilidades$Doente
  } else {
    prob_doente <- ifelse(predicao == "Doente", 1, 0)
  }

  matriz <- caret::confusionMatrix(
    data = predicao,
    reference = teste$Selector,
    positive = "Doente"
  )

  acuracia <- unname(matriz$overall["Accuracy"])
  sensibilidade <- unname(matriz$byClass["Sensitivity"])
  especificidade <- unname(matriz$byClass["Specificity"])
  precisao <- unname(matriz$byClass["Pos Pred Value"])
  recall <- sensibilidade

  f1 <- ifelse(
    is.na(precisao) || is.na(recall) || (precisao + recall) == 0,
    NA_real_,
    2 * precisao * recall / (precisao + recall)
  )

  auc <- tryCatch({
    roc_obj <- pROC::roc(
      response = teste$Selector,
      predictor = prob_doente,
      levels = c("Saudavel", "Doente"),
      quiet = TRUE
    )
    as.numeric(pROC::auc(roc_obj))
  }, error = function(e) NA_real_)

  tibble::tibble(
    Cenario = nome_cenario,
    Modelo = nome_modelo,
    Acuracia = acuracia,
    Sensitividade = sensibilidade,
    Especificidade = especificidade,
    Precisao = precisao,
    Recall = recall,
    F1 = f1,
    AUC = auc
  )
}

extrair_roc <- function(modelo, teste, nome_modelo, nome_cenario) {
  probabilidades <- tryCatch(
    predict(modelo, newdata = teste, type = "prob", na.action = na.pass),
    error = function(e) NULL
  )

  if (is.null(probabilidades) || !("Doente" %in% names(probabilidades))) {
    return(NULL)
  }

  roc_obj <- tryCatch({
    pROC::roc(
      response = teste$Selector,
      predictor = probabilidades$Doente,
      levels = c("Saudavel", "Doente"),
      quiet = TRUE
    )
  }, error = function(e) NULL)

  if (is.null(roc_obj)) {
    return(NULL)
  }

  tibble::tibble(
    Cenario = nome_cenario,
    Modelo = nome_modelo,
    Especificidade = roc_obj$specificities,
    Sensitividade = roc_obj$sensitivities,
    Falso_Positivo = 1 - roc_obj$specificities
  )
}

extrair_importancia <- function(modelo, nome_modelo, nome_cenario) {
  importancia <- tryCatch(
    caret::varImp(modelo, scale = TRUE)$importance,
    error = function(e) NULL
  )

  if (is.null(importancia)) {
    return(NULL)
  }

  importancia <- as.data.frame(importancia)
  importancia$Variavel <- rownames(importancia)

  colunas_numericas <- names(importancia)[sapply(importancia, is.numeric)]
  if (!("Overall" %in% names(importancia))) {
    importancia$Overall <- rowMeans(importancia[, colunas_numericas, drop = FALSE], na.rm = TRUE)
  }

  importancia %>%
    dplyr::select(Variavel, Overall) %>%
    dplyr::mutate(
      Cenario = nome_cenario,
      Modelo = nome_modelo
    ) %>%
    dplyr::arrange(dplyr::desc(Overall))
}


# -----------------------------
# 3. Carregamento e preparacao dos dados
# -----------------------------

arquivos_csv <- list.files("dados", pattern = "\\.csv$", full.names = TRUE)

if (length(arquivos_csv) == 0) {
  stop("Nenhum arquivo CSV foi encontrado na pasta dados/. Coloque a base ILPD nessa pasta e execute novamente.")
}

arquivo_dados <- arquivos_csv[1]

colunas_ilpd <- c(
  "Age",
  "Gender",
  "Total_Bilirubin",
  "Direct_Bilirubin",
  "Alkaline_Phosphatase",
  "Alamine_Aminotransferase",
  "Aspartate_Aminotransferase",
  "Total_Proteins",
  "Albumin",
  "Albumin_and_Globulin_Ratio",
  "Selector"
)

dados <- read.csv(
  arquivo_dados,
  header = FALSE,
  na.strings = c("", "NA", "?"),
  stringsAsFactors = FALSE
)

if (ncol(dados) != length(colunas_ilpd)) {
  stop("A base carregada nao possui 11 colunas. Verifique se o CSV corresponde ao ILPD original.")
}

names(dados) <- colunas_ilpd

dados <- dados %>%
  dplyr::mutate(
    Gender = factor(Gender),
    Selector = dplyr::case_when(
      Selector == 1 ~ "Doente",
      Selector == 2 ~ "Saudavel",
      TRUE ~ NA_character_
    ),
    Selector = factor(Selector, levels = c("Doente", "Saudavel"))
  )

# Remocao de linhas sem classe, se houver. O teste final continua separado depois.
dados <- dados %>% dplyr::filter(!is.na(Selector))


# -----------------------------
# 4. Analise exploratoria inicial
# -----------------------------

dimensao_base <- tibble::tibble(
  Linhas = nrow(dados),
  Colunas = ncol(dados)
)

estrutura_base <- tibble::tibble(
  Variavel = names(dados),
  Classe_R = purrr::map_chr(dados, ~ paste(class(.x), collapse = ", ")),
  Valores_Ausentes = purrr::map_int(dados, ~ sum(is.na(.x))),
  Valores_Distintos = purrr::map_int(dados, ~ dplyr::n_distinct(.x, na.rm = TRUE))
)

resumo_estatistico <- calcular_resumo_numerico(dados)

valores_ausentes <- tibble::tibble(
  Variavel = names(dados),
  Ausentes = purrr::map_int(dados, ~ sum(is.na(.x))),
  Percentual_Ausente = round(100 * Ausentes / nrow(dados), 2)
)

distribuicao_classes <- dados %>%
  dplyr::count(Selector, name = "Frequencia") %>%
  dplyr::mutate(Percentual = round(100 * Frequencia / sum(Frequencia), 2))

distribuicao_genero <- dados %>%
  dplyr::count(Gender, name = "Frequencia") %>%
  dplyr::mutate(Percentual = round(100 * Frequencia / sum(Frequencia), 2))

salvar_csv(dimensao_base, "resultados/dimensao_base.csv")
salvar_csv(estrutura_base, "resultados/estrutura_base.csv")
salvar_csv(resumo_estatistico, "resultados/resumo_estatistico.csv")
salvar_csv(valores_ausentes, "resultados/valores_ausentes.csv")
salvar_csv(distribuicao_classes, "resultados/distribuicao_classes.csv")
salvar_csv(distribuicao_genero, "resultados/distribuicao_genero.csv")

# Grafico da distribuicao das classes.
grafico_classes <- ggplot2::ggplot(distribuicao_classes, ggplot2::aes(x = Selector, y = Frequencia, fill = Selector)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::geom_text(ggplot2::aes(label = paste0(Frequencia, " (", Percentual, "%)")), vjust = -0.3) +
  ggplot2::labs(
    title = "Distribuicao das classes - ILPD",
    x = "Classe",
    y = "Frequencia"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave("graficos/distribuicao_classes.png", grafico_classes, width = 7, height = 5, dpi = 300)

# Grafico da distribuicao por genero.
grafico_genero <- ggplot2::ggplot(distribuicao_genero, ggplot2::aes(x = Gender, y = Frequencia, fill = Gender)) +
  ggplot2::geom_col(show.legend = FALSE) +
  ggplot2::geom_text(ggplot2::aes(label = paste0(Frequencia, " (", Percentual, "%)")), vjust = -0.3) +
  ggplot2::labs(
    title = "Distribuicao por genero - ILPD",
    x = "Genero",
    y = "Frequencia"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave("graficos/distribuicao_genero.png", grafico_genero, width = 7, height = 5, dpi = 300)

# Graficos de distribuicao das variaveis numericas.
variaveis_numericas <- names(dplyr::select(dados, where(is.numeric)))

grafico_distribuicoes <- dados %>%
  tidyr::pivot_longer(cols = dplyr::all_of(variaveis_numericas), names_to = "Variavel", values_to = "Valor") %>%
  ggplot2::ggplot(ggplot2::aes(x = Valor)) +
  ggplot2::geom_histogram(bins = 30, na.rm = TRUE) +
  ggplot2::facet_wrap(~ Variavel, scales = "free") +
  ggplot2::labs(
    title = "Distribuicao das variaveis numericas",
    x = "Valor",
    y = "Frequencia"
  ) +
  ggplot2::theme_minimal(base_size = 10)

ggplot2::ggsave("graficos/distribuicao_variaveis_numericas.png", grafico_distribuicoes, width = 12, height = 8, dpi = 300)

# Matriz de correlacao das variaveis numericas.
matriz_correlacao <- stats::cor(dplyr::select(dados, dplyr::all_of(variaveis_numericas)), use = "pairwise.complete.obs")
correlacao_df <- as.data.frame(as.table(matriz_correlacao))
names(correlacao_df) <- c("Variavel_1", "Variavel_2", "Correlacao")

salvar_csv(correlacao_df, "resultados/matriz_correlacao.csv")

grafico_correlacao <- ggplot2::ggplot(correlacao_df, ggplot2::aes(x = Variavel_1, y = Variavel_2, fill = Correlacao)) +
  ggplot2::geom_tile() +
  ggplot2::geom_text(ggplot2::aes(label = round(Correlacao, 2)), size = 2.8) +
  ggplot2::scale_fill_gradient2(low = "#2c7bb6", mid = "white", high = "#d7191c", midpoint = 0) +
  ggplot2::labs(
    title = "Matriz de correlacao das variaveis numericas",
    x = NULL,
    y = NULL,
    fill = "Correlacao"
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

ggplot2::ggsave("graficos/matriz_correlacao.png", grafico_correlacao, width = 10, height = 8, dpi = 300)


# -----------------------------
# 5. Funcao de modelagem por cenario
# -----------------------------

executar_cenario <- function(base_original, nome_cenario) {
  set.seed(123)

  base_cenario <- base_original

  if (nome_cenario == "Homens") {
    base_cenario <- base_cenario %>% dplyr::filter(Gender == "Male")
  }

  if (nome_cenario == "Mulheres") {
    base_cenario <- base_cenario %>% dplyr::filter(Gender == "Female")
  }

  # Remocao de preditores constantes, importante nos cenarios por genero.
  preditores <- setdiff(names(base_cenario), "Selector")
  preditores_constantes <- preditores[purrr::map_int(base_cenario[preditores], ~ dplyr::n_distinct(.x, na.rm = TRUE)) < 2]

  if (length(preditores_constantes) > 0) {
    base_cenario <- base_cenario %>% dplyr::select(-dplyr::all_of(preditores_constantes))
  }

  # Salva a distribuicao de classes por cenario.
  nome_limpo <- limpar_nome_arquivo(nome_cenario)

  dist_classes_cenario <- base_cenario %>%
    dplyr::count(Selector, name = "Frequencia") %>%
    dplyr::mutate(
      Cenario = nome_cenario,
      Percentual = round(100 * Frequencia / sum(Frequencia), 2)
    )

  salvar_csv(dist_classes_cenario, paste0("resultados/distribuicao_classes_", nome_limpo, ".csv"))

  grafico_classes_cenario <- ggplot2::ggplot(dist_classes_cenario, ggplot2::aes(x = Selector, y = Frequencia, fill = Selector)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(label = paste0(Frequencia, " (", Percentual, "%)")), vjust = -0.3) +
    ggplot2::labs(
      title = paste("Distribuicao das classes -", nome_cenario),
      x = "Classe",
      y = "Frequencia"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  ggplot2::ggsave(
    paste0("graficos/distribuicao_classes_", nome_limpo, ".png"),
    grafico_classes_cenario,
    width = 7,
    height = 5,
    dpi = 300
  )

  # Separacao treino/teste estratificada pela variavel-alvo.
  indice_treino <- caret::createDataPartition(base_cenario$Selector, p = 0.70, list = FALSE)
  treino <- base_cenario[indice_treino, ]
  teste <- base_cenario[-indice_treino, ]

  particao <- tibble::tibble(
    Cenario = nome_cenario,
    Conjunto = c("Treino", "Teste"),
    Linhas = c(nrow(treino), nrow(teste))
  )

  salvar_csv(particao, paste0("resultados/particao_", nome_limpo, ".csv"))

  # Validacao cruzada estratificada de 10 folds.
  # O balanceamento por upsampling ocorre dentro dos folds de treino,
  # evitando vazamento de dados para validacao e teste.
  controle <- caret::trainControl(
    method = "cv",
    number = 10,
    classProbs = TRUE,
    summaryFunction = caret::twoClassSummary,
    savePredictions = "final",
    sampling = "up",
    allowParallel = TRUE
  )

  pre_processamento <- c("zv", "medianImpute", "center", "scale")
  formula_modelo <- stats::as.formula("Selector ~ .")

  numero_preditores <- ncol(treino) - 1
  mtry_base <- max(1, floor(sqrt(numero_preditores)))

  grade_rf <- expand.grid(
    mtry = unique(pmax(1, c(mtry_base, mtry_base + 1, max(1, numero_preditores %/% 2)))),
    splitrule = c("gini", "extratrees"),
    min.node.size = c(1, 5)
  )

  grade_nb <- expand.grid(
    laplace = c(0, 1),
    usekernel = c(TRUE, FALSE),
    adjust = c(1)
  )

  grade_xgb <- expand.grid(
    nrounds = c(50, 100),
    max_depth = c(2, 3),
    eta = c(0.05, 0.10),
    gamma = 0,
    colsample_bytree = 0.8,
    min_child_weight = 1,
    subsample = 0.8
  )

  lista_modelos <- list(
    "Regressao Logistica" = list(
      method = "glm",
      args = list(family = stats::binomial())
    ),
    "Random Forest" = list(
      method = "ranger",
      args = list(tuneGrid = grade_rf, importance = "permutation", num.trees = 500)
    ),
    "SVM Radial" = list(
      method = "svmRadial",
      args = list(tuneLength = 4)
    ),
    "Naive Bayes" = list(
      method = "naive_bayes",
      args = list(tuneGrid = grade_nb)
    ),
    "XGBoost" = list(
      method = "xgbTree",
      args = list(tuneGrid = grade_xgb, verbose = FALSE)
    )
  )

  modelos_ajustados <- list()
  metricas <- list()
  curvas_roc <- list()
  importancias <- list()
  erros_modelos <- list()

  for (nome_modelo in names(lista_modelos)) {
    message("Treinando ", nome_modelo, " - ", nome_cenario, "...")

    especificacao <- lista_modelos[[nome_modelo]]

    argumentos_train <- c(
      list(
        form = formula_modelo,
        data = treino,
        method = especificacao$method,
        metric = "ROC",
        trControl = controle,
        preProcess = pre_processamento,
        na.action = quote(na.pass)
      ),
      especificacao$args
    )

    modelo <- tryCatch(
      do.call(caret::train, argumentos_train),
      error = function(e) {
        mensagem_erro <- paste("Falha no modelo", nome_modelo, "no cenario", nome_cenario, ":", e$message)
        message(mensagem_erro)
        erros_modelos[[length(erros_modelos) + 1]] <<- tibble::tibble(
          Cenario = nome_cenario,
          Modelo = nome_modelo,
          Erro = e$message
        )
        NULL
      }
    )

    if (is.null(modelo)) {
      next
    }

    modelos_ajustados[[nome_modelo]] <- modelo
    metricas[[nome_modelo]] <- calcular_metricas(modelo, teste, nome_modelo, nome_cenario)
    curvas_roc[[nome_modelo]] <- extrair_roc(modelo, teste, nome_modelo, nome_cenario)
    importancias[[nome_modelo]] <- extrair_importancia(modelo, nome_modelo, nome_cenario)
  }

  metricas_cenario <- dplyr::bind_rows(metricas) %>%
    dplyr::mutate(
      Score_Geral = rowMeans(
        dplyr::across(c(Acuracia, Sensitividade, Especificidade, F1, AUC)),
        na.rm = TRUE
      )
    ) %>%
    dplyr::arrange(dplyr::desc(Score_Geral))

  curvas_roc_cenario <- dplyr::bind_rows(curvas_roc)
  importancias_cenario <- dplyr::bind_rows(importancias)
  erros_cenario <- dplyr::bind_rows(erros_modelos)

  salvar_csv(metricas_cenario, paste0("resultados/metricas_modelos_", nome_limpo, ".csv"))
  salvar_csv(curvas_roc_cenario, paste0("resultados/curvas_roc_", nome_limpo, ".csv"))
  salvar_csv(importancias_cenario, paste0("resultados/importancia_variaveis_", nome_limpo, ".csv"))

  if (nrow(erros_cenario) > 0) {
    salvar_csv(erros_cenario, paste0("resultados/erros_modelos_", nome_limpo, ".csv"))
  }

  # Grafico comparando acuracia dos modelos.
  grafico_acuracia <- ggplot2::ggplot(metricas_cenario, ggplot2::aes(x = reorder(Modelo, Acuracia), y = Acuracia, fill = Modelo)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
    ggplot2::labs(
      title = paste("Acuracia dos modelos -", nome_cenario),
      x = "Modelo",
      y = "Acuracia"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  ggplot2::ggsave(
    paste0("graficos/acuracia_modelos_", nome_limpo, ".png"),
    grafico_acuracia,
    width = 9,
    height = 6,
    dpi = 300
  )

  # Grafico comparando sensitividade e especificidade.
  dados_sens_esp <- metricas_cenario %>%
    dplyr::select(Modelo, Sensitividade, Especificidade) %>%
    tidyr::pivot_longer(cols = c(Sensitividade, Especificidade), names_to = "Metrica", values_to = "Valor")

  grafico_sens_esp <- ggplot2::ggplot(dados_sens_esp, ggplot2::aes(x = reorder(Modelo, Valor), y = Valor, fill = Metrica)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
    ggplot2::labs(
      title = paste("Sensitividade e especificidade -", nome_cenario),
      x = "Modelo",
      y = "Valor"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  ggplot2::ggsave(
    paste0("graficos/sensitividade_especificidade_", nome_limpo, ".png"),
    grafico_sens_esp,
    width = 9,
    height = 6,
    dpi = 300
  )

  # Curva ROC dos melhores modelos do cenario.
  melhores_para_roc <- metricas_cenario %>%
    dplyr::arrange(dplyr::desc(Score_Geral)) %>%
    dplyr::slice_head(n = 3) %>%
    dplyr::pull(Modelo)

  if (nrow(curvas_roc_cenario) > 0) {
    grafico_roc <- curvas_roc_cenario %>%
      dplyr::filter(Modelo %in% melhores_para_roc) %>%
      ggplot2::ggplot(ggplot2::aes(x = Falso_Positivo, y = Sensitividade, color = Modelo)) +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::geom_abline(linetype = "dashed") +
      ggplot2::labs(
        title = paste("Curva ROC dos melhores modelos -", nome_cenario),
        x = "Taxa de falso positivo (1 - especificidade)",
        y = "Sensitividade"
      ) +
      ggplot2::theme_minimal(base_size = 12)

    ggplot2::ggsave(
      paste0("graficos/curva_roc_melhores_modelos_", nome_limpo, ".png"),
      grafico_roc,
      width = 8,
      height = 6,
      dpi = 300
    )
  }

  # Importancia das variaveis para o melhor modelo.
  melhor_modelo_nome <- metricas_cenario %>%
    dplyr::arrange(dplyr::desc(Score_Geral)) %>%
    dplyr::slice(1) %>%
    dplyr::pull(Modelo)

  importancia_melhor <- importancias_cenario %>%
    dplyr::filter(Modelo == melhor_modelo_nome) %>%
    dplyr::arrange(dplyr::desc(Overall)) %>%
    dplyr::slice_head(n = 15)

  if (nrow(importancia_melhor) > 0) {
    salvar_csv(importancia_melhor, paste0("resultados/importancia_melhor_modelo_", nome_limpo, ".csv"))

    grafico_importancia <- ggplot2::ggplot(importancia_melhor, ggplot2::aes(x = reorder(Variavel, Overall), y = Overall)) +
      ggplot2::geom_col() +
      ggplot2::coord_flip() +
      ggplot2::labs(
        title = paste("Importancia das variaveis -", melhor_modelo_nome, "-", nome_cenario),
        x = "Variavel",
        y = "Importancia relativa"
      ) +
      ggplot2::theme_minimal(base_size = 12)

    ggplot2::ggsave(
      paste0("graficos/importancia_variaveis_melhor_modelo_", nome_limpo, ".png"),
      grafico_importancia,
      width = 9,
      height = 6,
      dpi = 300
    )
  }

  # Comentario da etapa: o cenario foi treinado com validacao cruzada, upsampling interno, avaliacao em teste e graficos finais.

  list(
    metricas = metricas_cenario,
    curvas_roc = curvas_roc_cenario,
    importancias = importancias_cenario,
    erros = erros_cenario
  )
}

# -----------------------------
# 6. Execucao dos tres cenarios
# -----------------------------

cenarios <- c("Completa", "Homens", "Mulheres")
resultados_cenarios <- purrr::map(cenarios, ~ executar_cenario(dados, .x))
names(resultados_cenarios) <- cenarios

metricas_todos <- purrr::map_dfr(resultados_cenarios, "metricas") %>%
  dplyr::mutate(
    dplyr::across(
      c(Acuracia, Sensitividade, Especificidade, Precisao, Recall, F1, AUC, Score_Geral),
      ~ round(.x, 4)
    )
  )

curvas_roc_todas <- purrr::map_dfr(resultados_cenarios, "curvas_roc")
importancias_todas <- purrr::map_dfr(resultados_cenarios, "importancias")
erros_todos <- purrr::map_dfr(resultados_cenarios, "erros")

salvar_csv(metricas_todos, "resultados/metricas_todos_os_modelos.csv")
salvar_csv(curvas_roc_todas, "resultados/curvas_roc_todos_os_modelos.csv")
salvar_csv(importancias_todas, "resultados/importancia_variaveis_todos_os_modelos.csv")

if (nrow(erros_todos) > 0) {
  salvar_csv(erros_todos, "resultados/erros_todos_os_modelos.csv")
}

# Tabela comparativa final obrigatoria.
tabela_comparativa_final <- metricas_todos %>%
  dplyr::select(
    Cenario,
    Modelo,
    Acuracia,
    Sensitividade,
    Especificidade,
    Precisao,
    Recall,
    F1,
    AUC
  ) %>%
  dplyr::arrange(Cenario, dplyr::desc(AUC), dplyr::desc(F1), dplyr::desc(Acuracia))

salvar_csv(tabela_comparativa_final, "resultados/tabela_comparativa_final.csv")

melhores_modelos <- metricas_todos %>%
  dplyr::group_by(Cenario) %>%
  dplyr::arrange(dplyr::desc(Score_Geral), .by_group = TRUE) %>%
  dplyr::slice(1) %>%
  dplyr::ungroup()

salvar_csv(melhores_modelos, "resultados/melhores_modelos_por_cenario.csv")


# -----------------------------
# 7. Comparacao com o artigo de referencia
# -----------------------------

# Valores aproximados retirados do artigo enviado pelo usuario.
# Eles sao usados apenas como referencia comparativa; os resultados do projeto
# sao calculados pelo script a partir da base, treino, validacao e teste.
melhores_resultados_artigo <- tibble::tibble(
  Cenario = c("Completa", "Homens", "Mulheres"),
  Melhor_Artigo_Modelo = c("Regressao Logistica sem CFS", "Generalized Linear Model sem CFS", "SVM sem CFS"),
  Melhor_Artigo_Acuracia = c(0.753, 0.765, 0.714)
)

comparacao_artigo <- melhores_resultados_artigo %>%
  dplyr::left_join(
    melhores_modelos %>%
      dplyr::select(
        Cenario,
        Melhor_Projeto_Modelo = Modelo,
        Melhor_Projeto_Acuracia = Acuracia,
        Melhor_Projeto_Sensitividade = Sensitividade,
        Melhor_Projeto_Especificidade = Especificidade,
        Melhor_Projeto_F1 = F1,
        Melhor_Projeto_AUC = AUC,
        Score_Geral
      ),
    by = "Cenario"
  ) %>%
  dplyr::mutate(
    Diferenca_Acuracia = Melhor_Projeto_Acuracia - Melhor_Artigo_Acuracia,
    Diferenca_Acuracia_pp = round(100 * Diferenca_Acuracia, 2),
    Houve_Melhoria_Acuracia = dplyr::case_when(
      Diferenca_Acuracia > 0 ~ "Sim",
      Diferenca_Acuracia == 0 ~ "Empate",
      Diferenca_Acuracia < 0 ~ "Nao",
      TRUE ~ NA_character_
    )
  )

salvar_csv(melhores_resultados_artigo, "resultados/melhores_resultados_artigo.csv")
salvar_csv(comparacao_artigo, "resultados/comparacao_com_artigo.csv")

# Grafico comparando acuracia do melhor modelo do projeto com o melhor resultado do artigo.
dados_comparacao_grafico <- comparacao_artigo %>%
  dplyr::select(Cenario, Melhor_Artigo_Acuracia, Melhor_Projeto_Acuracia) %>%
  tidyr::pivot_longer(
    cols = c(Melhor_Artigo_Acuracia, Melhor_Projeto_Acuracia),
    names_to = "Fonte",
    values_to = "Acuracia"
  ) %>%
  dplyr::mutate(
    Fonte = dplyr::recode(
      Fonte,
      Melhor_Artigo_Acuracia = "Artigo",
      Melhor_Projeto_Acuracia = "Projeto"
    )
  )

grafico_comparacao_artigo <- ggplot2::ggplot(dados_comparacao_grafico, ggplot2::aes(x = Cenario, y = Acuracia, fill = Fonte)) +
  ggplot2::geom_col(position = "dodge") +
  ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
  ggplot2::labs(
    title = "Comparacao da acuracia: projeto versus artigo",
    x = "Cenario",
    y = "Acuracia"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave("graficos/comparacao_acuracia_artigo.png", grafico_comparacao_artigo, width = 8, height = 6, dpi = 300)


# -----------------------------
# 8. Encerramento
# -----------------------------

message("Analise concluida com sucesso.")
message("Tabelas salvas em: resultados/")
message("Graficos salvos em: graficos/")

