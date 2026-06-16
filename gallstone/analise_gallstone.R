# =============================================================================
# ANALISE DE DADOS - GALLSTONE DISEASE PREDICTION
# =============================================================================
# Objetivo:
# 1. Derivar paines candidatos exclusivamente a partir dos dados observados.
# 2. Testar se um painel fixo com 10 features e realmente necessario.
# 3. Priorizar uma resposta cientificamente defensavel e aplicavel na vida real.
# =============================================================================

COLUNAS_DADOS <- c(
  "Gallstone", "Age", "Gender", "Comorbidity", "CAD", "Hypothyroidism",
  "Hyperlipidemia", "DM", "Height", "Weight", "BMI", "TBW", "ECW", "ICW",
  "ECF_TBW", "TBFR", "LM", "Protein", "VFR", "BM", "MM", "Obesity",
  "TFC", "VFA", "VMA", "HFA", "Glucose", "TC", "LDL", "HDL",
  "Triglyceride", "AST", "ALT", "ALP", "Creatinine", "GFR", "CRP",
  "HGB", "VitaminD"
)

VARS_FATOR <- c(
  "Gender", "Comorbidity", "CAD", "Hypothyroidism",
  "Hyperlipidemia", "DM", "HFA"
)

VARS_PRINCIPAIS <- c(
  "Age", "BMI", "Glucose", "TC", "LDL", "HDL",
  "Triglyceride", "AST", "ALT", "ALP", "HGB", "VitaminD", "CRP"
)

GRUPOS_FEATURES <- list(
  Historia = c("Age", "Gender", "Comorbidity", "CAD", "Hypothyroidism", "Hyperlipidemia", "DM"),
  Antropometria = c("Height", "Weight", "BMI"),
  Bioimpedancia = c("TBW", "ECW", "ICW", "ECF_TBW", "TBFR", "LM", "Protein",
                    "VFR", "BM", "MM", "Obesity", "TFC", "VFA", "VMA"),
  Laboratorio = c("Glucose", "TC", "LDL", "HDL", "Triglyceride", "AST", "ALT",
                  "ALP", "Creatinine", "GFR", "CRP", "HGB", "VitaminD"),
  HFA = c("HFA")
)

CUSTOS_GRUPOS <- c(
  Historia = 1,
  Antropometria = 1,
  Laboratorio = 2,
  Bioimpedancia = 3,
  HFA = 4
)

ORDEM_GRUPOS <- c("Historia", "Antropometria", "Laboratorio", "Bioimpedancia", "HFA")

JUSTIFICATIVAS_FEATURES <- c(
  Age = "idade aumenta o risco cumulativo e ajuda a representar exposicao metabolica de longo prazo.",
  Gender = "sexo tem relevancia epidemiologica conhecida em colelitiase e pode capturar diferencas hormonais.",
  Comorbidity = "carga de comorbidades resume fragilidade clinica e risco metabolico agregado.",
  CAD = "doenca arterial coronariana compartilha vias metabolicas com dislipidemia e resistencia insulinica.",
  Hypothyroidism = "hipotireoidismo pode alterar motilidade biliar e metabolismo lipidico.",
  Hyperlipidemia = "hiperlipidemia tem plausibilidade biologica direta por aumentar o ambiente litogenico.",
  DM = "diabetes e resistencia insulinica aumentam risco metabolico e alteracoes de bile.",
  Height = "altura isolada e pouco especifica, mas pode atuar como ajuste de composicao corporal.",
  Weight = "peso resume carga corporal total, embora costume ser redundante com IMC e gordura visceral.",
  BMI = "IMC e um marcador clinico barato de adiposidade e risco metabolico.",
  TBW = "agua corporal total resume composicao corporal global e pode substituir medidas bioimpedanciometricas vizinhas.",
  ECW = "agua extracelular captura distribuicao hidrica e inflamada da composicao corporal.",
  ICW = "agua intracelular descreve massa metabolicamente ativa e hidratacao celular.",
  ECF_TBW = "a razao entre agua extracelular e agua corporal total resume o balanco hidrico sem usar duas medidas separadas.",
  TBFR = "taxa de gordura corporal total expressa adiposidade, ligada a sindrome metabolica e litogenese.",
  LM = "massa magra resume constituicao corporal, mas costuma ser quase substituta de outras medidas de bioimpedancia.",
  Protein = "conteudo proteico corporal atua como marcador indireto de composicao e estado nutricional.",
  VFR = "rating de gordura visceral tenta resumir adiposidade central, fator relevante para risco metabolico.",
  BM = "massa ossea aparece como proxy de composicao corporal global e estado nutricional.",
  MM = "massa muscular tende a se sobrepor com agua corporal e massa magra em bioimpedancia.",
  Obesity = "indice sintetico de obesidade resume fenotipo adiposo, mas pode ser redundante com IMC e gordura total.",
  TFC = "conteudo total de gordura resume adiposidade global e pode competir com TBFR e VFA.",
  VFA = "area de gordura visceral aproxima adiposidade central e resistencia insulinica.",
  VMA = "area muscular visceral pode representar fenotipo corporal e distribuicao de massa metabolica.",
  HFA = "acumulo de gordura hepatica conecta resistencia insulinica, esteatose e bile litogenica.",
  Glucose = "glicose elevada e marcador de resistencia insulinica, plausivel na fisiopatologia da colelitiase.",
  TC = "colesterol total tem plausibilidade biologica, mas pode ser redundante com LDL.",
  LDL = "LDL resume parte do metabolismo lipidico aterogenico e litogenico.",
  HDL = "HDL baixo acompanha sindrome metabolica e risco cardiometabolico.",
  Triglyceride = "triglicerideos altos acompanham sindrome metabolica e risco hepatobiliar.",
  AST = "AST e um marcador hepatocelular inespecifico com plausibilidade em doenca hepatobiliar.",
  ALT = "ALT complementa dano/metabolismo hepatico, mas costuma andar junto com AST.",
  ALP = "ALP e plausivel clinicamente por se relacionar a colestase e trato biliar.",
  Creatinine = "creatinina reflete funcao renal e estado muscular, com relacao mais indireta a colelitiase.",
  GFR = "taxa de filtracao glomerular resume funcao renal, sinal indireto e menos especifico.",
  CRP = "PCR capta inflamacao sistemica e foi uma das variaveis mais consistentes nos estudos.",
  HGB = "hemoglobina resume estado geral e inflamatorio, mas e pouco especifica para colelitiase.",
  VitaminD = "deficiencia de vitamina D foi destacada nos estudos e tem plausibilidade via estase biliar."
)

PACOTES_ANALISE <- c(
  "caret", "randomForest", "e1071", "kernlab", "naivebayes", "nnet",
  "rpart", "gbm", "ada", "plyr", "pROC", "ggplot2", "gridExtra",
  "corrplot", "reshape2", "scales", "knitr", "rmarkdown"
)

MODELOS_CONFIG <- list(
  "Logistic Regression" = list(method = "glm", family = "binomial"),
  "Random Forest" = list(method = "rf", ntree = 500),
  "AdaBoost" = list(method = "ada"),
  "Gradient Boosting" = list(method = "gbm", verbose = FALSE),
  "MLP" = list(method = "nnet", trace = FALSE, MaxNWts = 5000),
  "SVM Radial" = list(method = "svmRadial"),
  "Decision Tree" = list(method = "rpart"),
  "Naive Bayes" = list(method = "naive_bayes"),
  "KNN" = list(method = "knn")
)

instalar_se_necessario <- function(pacote) {
  if (!require(pacote, character.only = TRUE, quietly = TRUE)) {
    install.packages(
      pacote,
      dependencies = TRUE,
      repos = "https://cran.r-project.org"
    )
    library(pacote, character.only = TRUE)
  }
}

carregar_pacotes <- function() {
  cat("=== Instalando e carregando pacotes ===\n")
  invisible(sapply(PACOTES_ANALISE, instalar_se_necessario))
  cat("Pacotes carregados.\n\n")
}

garantir_diretorios <- function() {
  dir.create("graficos", showWarnings = FALSE)
  dir.create("resultados", showWarnings = FALSE)
}

carregar_dados <- function(caminho_csv = "gallstone.csv") {
  dados <- read.csv(caminho_csv, header = TRUE, stringsAsFactors = FALSE)
  colnames(dados) <- COLUNAS_DADOS

  for (variavel in VARS_FATOR) {
    dados[[variavel]] <- as.factor(dados[[variavel]])
  }

  dados
}

preparar_dados_modelagem <- function(dados) {
  dados_modelo <- dados
  dados_modelo$Gallstone <- factor(
    dados_modelo$Gallstone,
    levels = c(0, 1),
    labels = c("Positivo", "Negativo")
  )
  dados_modelo
}

rotular_dados_exploratorios <- function(dados) {
  dados$Gallstone_label <- factor(
    dados$Gallstone,
    levels = c(0, 1),
    labels = c("Com Calculo", "Sem Calculo")
  )
  dados$Gender_label <- factor(
    dados$Gender,
    levels = c(0, 1),
    labels = c("Masculino", "Feminino")
  )
  dados
}

imprimir_resumo_dataset <- function(dados) {
  cat("=== Carregando dados ===\n")
  cat(sprintf(
    "  Instancias: %d | Variaveis: %d | NAs: %d\n",
    nrow(dados), ncol(dados), sum(is.na(dados))
  ))
  cat(sprintf(
    "  Com calculo (0): %d (%.1f%%) | Sem calculo (1): %d (%.1f%%)\n",
    sum(dados$Gallstone == 0), 100 * mean(dados$Gallstone == 0),
    sum(dados$Gallstone == 1), 100 * mean(dados$Gallstone == 1)
  ))
  cat(sprintf(
    "  Masculino: %d | Feminino: %d\n",
    sum(dados$Gender == 0), sum(dados$Gender == 1)
  ))
  print(summary(dados[, VARS_PRINCIPAIS]))
}

obter_grupo_feature <- function(feature) {
  for (grupo in names(GRUPOS_FEATURES)) {
    if (feature %in% GRUPOS_FEATURES[[grupo]]) {
      return(grupo)
    }
  }
  "Outro"
}

formatar_lista_bullets <- function(x) {
  paste(sprintf("- %s", x), collapse = "\n")
}

formatar_lista_inline <- function(x) {
  paste(x, collapse = ", ")
}

criar_componentes_conexos <- function(arestas, nos) {
  if (length(nos) == 0) {
    return(setNames(character(0), character(0)))
  }

  adj <- setNames(vector("list", length(nos)), nos)
  for (no in nos) {
    adj[[no]] <- character(0)
  }

  if (nrow(arestas) > 0) {
    for (i in seq_len(nrow(arestas))) {
      a <- arestas$Feature1[i]
      b <- arestas$Feature2[i]
      adj[[a]] <- unique(c(adj[[a]], b))
      adj[[b]] <- unique(c(adj[[b]], a))
    }
  }

  visitados <- setNames(rep(FALSE, length(nos)), nos)
  cluster_map <- setNames(rep(NA_character_, length(nos)), nos)
  cluster_id <- 0

  for (no in nos) {
    if (visitados[[no]]) {
      next
    }

    cluster_id <- cluster_id + 1
    fila <- c(no)
    visitados[[no]] <- TRUE

    while (length(fila) > 0) {
      atual <- fila[1]
      fila <- fila[-1]
      cluster_map[[atual]] <- sprintf("C%02d", cluster_id)

      vizinhos <- adj[[atual]]
      novos <- vizinhos[!visitados[vizinhos]]
      if (length(novos) > 0) {
        visitados[novos] <- TRUE
        fila <- c(fila, novos)
      }
    }
  }

  cluster_map
}

detectar_redundancia <- function(dados_treino, limite = 0.85) {
  vars_numericas <- names(dados_treino)[sapply(dados_treino, is.numeric)]
  vars_numericas <- setdiff(vars_numericas, "Gallstone")
  cor_matrix <- cor(dados_treino[, vars_numericas], use = "complete.obs")

  pares_idx <- which(abs(cor_matrix) >= limite, arr.ind = TRUE)
  pares_idx <- pares_idx[pares_idx[, 1] < pares_idx[, 2], , drop = FALSE]

  if (nrow(pares_idx) == 0) {
    pares <- data.frame(
      Feature1 = character(0),
      Feature2 = character(0),
      Correlacao = numeric(0),
      stringsAsFactors = FALSE
    )
  } else {
    pares <- data.frame(
      Feature1 = rownames(cor_matrix)[pares_idx[, 1]],
      Feature2 = colnames(cor_matrix)[pares_idx[, 2]],
      Correlacao = cor_matrix[pares_idx],
      stringsAsFactors = FALSE
    )
    pares <- pares[order(-abs(pares$Correlacao)), ]
    rownames(pares) <- NULL
  }

  cluster_map <- criar_componentes_conexos(pares, vars_numericas)
  resumo_cluster <- unique(data.frame(
    Cluster = unname(cluster_map),
    Feature = names(cluster_map),
    stringsAsFactors = FALSE
  ))
  resumo_cluster <- aggregate(
    Feature ~ Cluster,
    data = resumo_cluster,
    FUN = function(x) paste(sort(x), collapse = ", ")
  )
  resumo_cluster$Tamanho <- sapply(strsplit(resumo_cluster$Feature, ", "), length)
  resumo_cluster <- resumo_cluster[order(resumo_cluster$Cluster), c("Cluster", "Tamanho", "Feature")]

  list(
    cor_matrix = cor_matrix,
    pares = pares,
    cluster_map = cluster_map,
    resumo_cluster = resumo_cluster
  )
}

prune_ranked_features <- function(ranked_features, cluster_map) {
  pruned <- character(0)
  clusters_vistos <- character(0)

  for (feature in ranked_features) {
    cluster_id <- cluster_map[feature]
    if (length(cluster_id) == 1 && !is.na(cluster_id)) {
      cluster_id <- unname(cluster_id)
    } else {
      cluster_id <- paste0("UNIQ_", feature)
    }

    if (!(cluster_id %in% clusters_vistos)) {
      pruned <- c(pruned, feature)
      clusters_vistos <- c(clusters_vistos, cluster_id)
    }
  }

  pruned
}

calcular_relevancia_univariada <- function(dados_treino) {
  target <- dados_treino$Gallstone
  features <- setdiff(names(dados_treino), "Gallstone")
  saida <- vector("list", length(features))

  for (i in seq_along(features)) {
    feature <- features[i]
    grupo <- obter_grupo_feature(feature)

    if (is.numeric(dados_treino[[feature]])) {
      positivos <- dados_treino[[feature]][target == "Positivo"]
      negativos <- dados_treino[[feature]][target == "Negativo"]
      teste <- suppressWarnings(wilcox.test(positivos, negativos, exact = FALSE))

      saida[[i]] <- data.frame(
        Feature = feature,
        Grupo = grupo,
        Tipo = "Numerica",
        Teste = "Wilcoxon",
        Estatistica = unname(teste$statistic),
        Pvalor = teste$p.value,
        Efeito = median(positivos, na.rm = TRUE) - median(negativos, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    } else {
      tabela <- table(dados_treino[[feature]], target)
      usar_fisher <- any(tabela < 5)
      if (usar_fisher) {
        teste <- fisher.test(tabela)
        estatistica <- NA_real_
        nome_teste <- "Fisher"
      } else {
        teste <- suppressWarnings(chisq.test(tabela, correct = FALSE))
        estatistica <- unname(teste$statistic)
        nome_teste <- "Qui-quadrado"
      }

      prop_col <- prop.table(tabela, 2)
      efeito <- max(prop_col[, "Positivo"] - prop_col[, "Negativo"])

      saida[[i]] <- data.frame(
        Feature = feature,
        Grupo = grupo,
        Tipo = "Categorica",
        Teste = nome_teste,
        Estatistica = estatistica,
        Pvalor = teste$p.value,
        Efeito = efeito,
        stringsAsFactors = FALSE
      )
    }
  }

  relevancia <- do.call(rbind, saida)
  relevancia <- relevancia[order(relevancia$Pvalor, -abs(relevancia$Efeito)), ]
  rownames(relevancia) <- NULL
  relevancia
}

calcular_importancia_rf <- function(dados_treino, ntree = 500) {
  set.seed(123)
  modelo <- randomForest::randomForest(
    Gallstone ~ .,
    data = dados_treino,
    ntree = ntree,
    importance = TRUE
  )
  importancia <- randomForest::importance(modelo, type = 1)
  ranking <- names(sort(importancia[, 1], decreasing = TRUE))

  list(
    modelo = modelo,
    importancia = importancia,
    ranking = ranking
  )
}

calcular_custo_painel <- function(features) {
  grupos <- unique(vapply(features, obter_grupo_feature, character(1)))
  grupos <- ORDEM_GRUPOS[ORDEM_GRUPOS %in% grupos]
  grupos <- grupos[!is.na(grupos)]

  componentes <- paste(
    sprintf("%s=%d", grupos, CUSTOS_GRUPOS[grupos]),
    collapse = " + "
  )

  list(
    grupos = grupos,
    custo_total = sum(CUSTOS_GRUPOS[grupos]),
    origens = paste(grupos, collapse = " + "),
    componentes = componentes
  )
}

construir_paineis_candidatos <- function(preditoras, ranking_bruto, ranking_podado, max_k = 15) {
  paineis <- list(full_38 = preditoras)

  max_bruto <- min(max_k, length(ranking_bruto))
  if (max_bruto >= 3) {
    for (k in 3:max_bruto) {
      paineis[[sprintf("raw_top_%02d", k)]] <- ranking_bruto[seq_len(k)]
    }
  }

  max_podado <- min(max_k, length(ranking_podado))
  if (max_podado >= 3) {
    for (k in 3:max_podado) {
      paineis[[sprintf("pruned_top_%02d", k)]] <- ranking_podado[seq_len(k)]
    }
  }

  paineis
}

obter_nome_painel_referencia_interno <- function(nomes_paineis) {
  if ("raw_top_10" %in% nomes_paineis) {
    return("raw_top_10")
  }

  paineis_brutos <- grep("^raw_top_", nomes_paineis, value = TRUE)
  if (length(paineis_brutos) == 0) {
    return(NA_character_)
  }

  k_paineis <- vapply(paineis_brutos, extrair_k_painel, integer(1))
  paineis_brutos[which.max(k_paineis)]
}

treinar_modelo <- function(config, dados_treino, ctrl, tune_length = 5) {
  tryCatch({
    set.seed(0)
    args <- list(
      form = Gallstone ~ .,
      data = dados_treino,
      method = config$method,
      trControl = ctrl,
      metric = "ROC",
      tuneLength = tune_length
    )

    if (config$method %in% c("glm", "nnet", "svmRadial", "knn", "naive_bayes")) {
      args$preProcess <- c("center", "scale")
    }

    extras <- setdiff(names(config), "method")
    for (extra in extras) {
      args[[extra]] <- config[[extra]]
    }

    do.call(caret::train, args)
  }, error = function(e) {
    cat(sprintf("  ERRO: %s\n", e$message))
    NULL
  })
}

calcular_metricas <- function(modelo, dados_teste, nome_modelo) {
  if (is.null(modelo)) {
    return(data.frame(
      Modelo = nome_modelo,
      Acuracia = NA_real_,
      Sensibilidade = NA_real_,
      Especificidade = NA_real_,
      Precisao = NA_real_,
      Recall = NA_real_,
      F1 = NA_real_,
      AUC = NA_real_,
      Acc_CV = NA_real_,
      stringsAsFactors = FALSE
    ))
  }

  pred_classe <- predict(modelo, dados_teste)
  pred_prob <- predict(modelo, dados_teste, type = "prob")
  cm <- caret::confusionMatrix(pred_classe, dados_teste$Gallstone, positive = "Positivo")

  roc_obj <- tryCatch(
    pROC::roc(
      dados_teste$Gallstone,
      pred_prob$Positivo,
      levels = c("Negativo", "Positivo"),
      direction = "<",
      quiet = TRUE
    ),
    error = function(e) NULL
  )
  auc_val <- if (!is.null(roc_obj)) as.numeric(pROC::auc(roc_obj)) else NA_real_

  acc_cv <- tryCatch({
    preds_cv <- modelo$pred
    if (is.null(preds_cv) || nrow(preds_cv) == 0) {
      return(NA_real_)
    }

    acc_por_fold <- tapply(
      seq_len(nrow(preds_cv)),
      preds_cv$Resample,
      function(idx) mean(preds_cv$pred[idx] == preds_cv$obs[idx])
    )
    round(mean(acc_por_fold) * 100, 2)
  }, error = function(e) {
    NA_real_
  })

  data.frame(
    Modelo = nome_modelo,
    Acuracia = round(unname(cm$overall["Accuracy"]) * 100, 2),
    Sensibilidade = round(unname(cm$byClass["Sensitivity"]) * 100, 2),
    Especificidade = round(unname(cm$byClass["Specificity"]) * 100, 2),
    Precisao = round(unname(cm$byClass["Pos Pred Value"]) * 100, 2),
    Recall = round(unname(cm$byClass["Sensitivity"]) * 100, 2),
    F1 = round(unname(cm$byClass["F1"]) * 100, 2),
    AUC = round(auc_val * 100, 2),
    Acc_CV = acc_cv,
    stringsAsFactors = FALSE
  )
}

avaliar_painel <- function(
  nome_painel,
  cenario,
  features,
  treino,
  teste,
  ctrl,
  guardar_roc = FALSE,
  tune_length = 5
) {
  dados_treino <- treino[, c(features, "Gallstone")]
  dados_teste <- teste[, c(features, "Gallstone")]
  resultados <- data.frame(stringsAsFactors = FALSE)
  roc_list <- list()

  custo <- calcular_custo_painel(features)

  for (nome_modelo in names(MODELOS_CONFIG)) {
    cat(sprintf("  [%s | %s] %s...", cenario, nome_painel, nome_modelo))
    modelo <- treinar_modelo(
      MODELOS_CONFIG[[nome_modelo]],
      dados_treino,
      ctrl,
      tune_length = tune_length
    )
    metricas <- calcular_metricas(modelo, dados_teste, nome_modelo)
    metricas$Cenario <- cenario
    metricas$Painel_Base <- nome_painel
    metricas$N_Features <- length(features)
    metricas$Features <- paste(features, collapse = ", ")
    metricas$Origens <- custo$origens
    metricas$Custo_Total <- custo$custo_total
    metricas$Custo_Componentes <- custo$componentes
    resultados <- rbind(resultados, metricas)

    if (guardar_roc && !is.null(modelo)) {
      prob <- predict(modelo, dados_teste, type = "prob")
      roc_list[[nome_modelo]] <- tryCatch(
        pROC::roc(
          dados_teste$Gallstone,
          prob$Positivo,
          levels = c("Negativo", "Positivo"),
          direction = "<",
          quiet = TRUE
        ),
        error = function(e) NULL
      )
    }

    cat(" OK\n")
  }

  list(
    resultados = resultados,
    roc = roc_list,
    features = features,
    custo = custo
  )
}

avaliar_cenario <- function(
  cenario,
  treino,
  teste,
  preditoras,
  ctrl,
  limite_cor = 0.85,
  max_k = 15,
  tune_length = 3
) {
  cat(sprintf("\n=== Auditoria de features - %s ===\n", cenario))

  relevancia <- calcular_relevancia_univariada(treino)
  redundancia <- detectar_redundancia(treino, limite = limite_cor)
  rf_info <- calcular_importancia_rf(treino)
  ranking_podado <- prune_ranked_features(rf_info$ranking, redundancia$cluster_map)
  paineis <- construir_paineis_candidatos(preditoras, rf_info$ranking, ranking_podado, max_k = max_k)

  cat(sprintf("Top 10 features (%s): %s\n", cenario, formatar_lista_inline(head(rf_info$ranking, 10))))
  cat(sprintf("Top 10 podadas (%s): %s\n", cenario, formatar_lista_inline(head(ranking_podado, 10))))
  cat(sprintf("Pares altamente correlacionados (%s): %d\n", cenario, nrow(redundancia$pares)))

  resultados_paineis <- data.frame(stringsAsFactors = FALSE)
  roc_referencia <- list()
  painel_referencia <- obter_nome_painel_referencia_interno(names(paineis))

  for (nome_painel in names(paineis)) {
    avaliacao <- avaliar_painel(
      nome_painel = nome_painel,
      cenario = cenario,
      features = paineis[[nome_painel]],
      treino = treino,
      teste = teste,
      ctrl = ctrl,
      guardar_roc = identical(nome_painel, painel_referencia),
      tune_length = tune_length
    )

    resultados_paineis <- rbind(resultados_paineis, avaliacao$resultados)

    if (identical(nome_painel, painel_referencia)) {
      roc_referencia <- avaliacao$roc
    }
  }

  metricas_painel <- aggregate(
    cbind(Acuracia, Sensibilidade, Especificidade, Precisao, F1, AUC, Acc_CV) ~
      Cenario + Painel_Base + N_Features + Features + Origens + Custo_Total + Custo_Componentes,
    data = resultados_paineis,
    FUN = function(x) round(mean(x, na.rm = TRUE), 2)
  )
  metricas_painel <- metricas_painel[order(-metricas_painel$AUC, metricas_painel$Custo_Total), ]
  rownames(metricas_painel) <- NULL

  list(
    relevancia = relevancia,
    redundancia = redundancia,
    rf_info = rf_info,
    ranking_podado = ranking_podado,
    paineis = paineis,
    painel_referencia = painel_referencia,
    resultados_modelos = resultados_paineis,
    resumo_paineis = metricas_painel,
    roc_referencia = roc_referencia
  )
}

consolidar_resumo_global <- function(resumo_8020, resumo_7030) {
  nomes_paineis <- sort(unique(c(resumo_8020$Painel_Base, resumo_7030$Painel_Base)))

  coletar_meta <- function(df, painel) {
    linha <- df[df$Painel_Base == painel, , drop = FALSE]
    if (nrow(linha) == 0) {
      return(data.frame(
        Painel_Base = painel,
        N_Features = NA_real_,
        Features = NA_character_,
        Origens = NA_character_,
        Custo_Total = NA_real_,
        stringsAsFactors = FALSE
      ))
    }
    linha[1, c("Painel_Base", "N_Features", "Features", "Origens", "Custo_Total")]
  }

  meta_8020 <- do.call(rbind, lapply(nomes_paineis, function(p) coletar_meta(resumo_8020, p)))
  meta_7030 <- do.call(rbind, lapply(nomes_paineis, function(p) coletar_meta(resumo_7030, p)))
  names(meta_8020)[-1] <- paste0(names(meta_8020)[-1], "_8020")
  names(meta_7030)[-1] <- paste0(names(meta_7030)[-1], "_7030")

  resumos_todos <- rbind(resumo_8020, resumo_7030)
  resumo_global <- aggregate(
    cbind(Acuracia, Sensibilidade, Especificidade, Precisao, F1, AUC, Acc_CV, N_Features, Custo_Total) ~ Painel_Base,
    data = resumos_todos,
    FUN = function(x) round(mean(x, na.rm = TRUE), 2)
  )

  resumo_global <- merge(resumo_global, meta_8020, by = "Painel_Base", all.x = TRUE)
  resumo_global <- merge(resumo_global, meta_7030, by = "Painel_Base", all.x = TRUE)
  resumo_global <- resumo_global[order(-resumo_global$AUC, resumo_global$Custo_Total, resumo_global$N_Features), ]
  rownames(resumo_global) <- NULL
  resumo_global
}

selecionar_painel_recomendado <- function(resumo_global) {
  melhor_auc <- max(resumo_global$AUC, na.rm = TRUE)
  melhor_f1 <- max(resumo_global$F1, na.rm = TRUE)
  melhor_sens <- max(resumo_global$Sensibilidade, na.rm = TRUE)

  elegiveis <- resumo_global[
    resumo_global$AUC >= (melhor_auc - 1) &
      resumo_global$F1 >= (melhor_f1 - 2) &
      resumo_global$Sensibilidade >= (melhor_sens - 3),
    ,
    drop = FALSE
  ]

  elegiveis <- elegiveis[
    order(elegiveis$Custo_Total, elegiveis$N_Features, -elegiveis$Sensibilidade),
    ,
    drop = FALSE
  ]

  recomendacao <- elegiveis[1, , drop = FALSE]
  resumo_global$Elegivel <- resumo_global$Painel_Base %in% elegiveis$Painel_Base
  resumo_global$Recomendado <- resumo_global$Painel_Base == recomendacao$Painel_Base

  list(
    resumo_global = resumo_global,
    elegiveis = elegiveis,
    recomendacao = recomendacao
  )
}

extrair_k_painel <- function(nome_painel) {
  if (!grepl("top_", nome_painel)) {
    return(NA_integer_)
  }
  as.integer(sub(".*_(\\d+)$", "\\1", nome_painel))
}

montar_curva_k <- function(resumo_global) {
  curva <- resumo_global[grepl("^(raw|pruned)_top_", resumo_global$Painel_Base), , drop = FALSE]
  if (nrow(curva) == 0) {
    return(curva)
  }

  curva$Tipo <- ifelse(grepl("^raw_", curva$Painel_Base), "Ranking bruto", "Ranking sem redundancia")
  curva$k <- vapply(curva$Painel_Base, extrair_k_painel, integer(1))
  curva[order(curva$Tipo, curva$k), ]
}

gerar_conclusao_necessidade <- function(recomendacao, resumo_global) {
  painel <- recomendacao$Painel_Base
  n_feat <- if (!is.null(recomendacao$N_Features_8020)) recomendacao$N_Features_8020 else recomendacao$N_Features
  painel_referencia <- obter_nome_painel_referencia_interno(resumo_global$Painel_Base)

  if (!is.na(n_feat) && n_feat < 10) {
    return(sprintf(
      "Os resultados indicam que 10 atributos nao sao estritamente necessarios: o painel %s manteve desempenho clinicamente competitivo com %d features e menor custo operacional.",
      painel, n_feat
    ))
  }

  if (!is.na(painel_referencia) && identical(painel, painel_referencia)) {
    return(sprintf(
      "Os resultados indicam que o painel interno de referencia com %d features ja oferece o melhor equilibrio observado entre desempenho medio, estabilidade e custo operacional.",
      n_feat
    ))
  }

  return(sprintf(
    "O painel %s manteve %d features e mostrou melhor equilibrio entre desempenho medio, estabilidade e custo-beneficio do que assumir um corte fixo e universal de 10 variaveis.",
    painel, n_feat
  ))
}

gerar_justificativas_painel <- function(features) {
  linhas <- character(0)
  for (feature in features) {
    explicacao <- JUSTIFICATIVAS_FEATURES[[feature]]
    if (is.null(explicacao)) {
      explicacao <- sprintf("%s foi mantida por combinar relevancia estatistica com plausibilidade clinica.", feature)
    }
    linhas <- c(linhas, sprintf("- **%s**: %s", feature, explicacao))
  }
  linhas
}

gerar_texto_realidade <- function(features, custo_info) {
  c(
    paste(
      "O painel recomendado foi interpretado como ferramenta de triagem, nao como substituto",
      "de ultrassonografia ou avaliacao clinica especializada."
    ),
    paste(
      "Na pratica, o custo foi calculado por origem da informacao:",
      custo_info$componentes, "."
    ),
    paste(
      "Isso permite comparar nao apenas desempenho estatistico, mas tambem o esforco humano e estrutural para coletar o painel:",
      custo_info$origens, "."
    ),
    paste(
      "Em linha com o NIDDK, fatores ligados a obesidade, metabolismo lipidico e diabetes fazem sentido biologico",
      "para colelitiase, mesmo quando uma variavel nao lidera sozinha o ranking de importancia."
    )
  )
}

criar_graficos_exploratorios <- function(dados_raw) {
  cat("\n=== Graficos exploratorios ===\n")
  dados_exp <- rotular_dados_exploratorios(dados_raw)

  p1 <- ggplot2::ggplot(dados_exp, ggplot2::aes(x = Gallstone_label, fill = Gallstone_label)) +
    ggplot2::geom_bar(width = 0.6, show.legend = FALSE) +
    ggplot2::geom_text(
      stat = "count",
      ggplot2::aes(label = after_stat(count)),
      vjust = -0.5,
      size = 5
    ) +
    ggplot2::scale_fill_manual(values = c("#E74C3C", "#2ECC71")) +
    ggplot2::labs(
      title = "Distribuicao da Variavel Alvo",
      subtitle = "Gallstone Status (Presenca de Calculo Biliar)",
      x = "Status",
      y = "Quantidade"
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )
  ggplot2::ggsave("graficos/01_distribuicao_alvo.png", p1, width = 8, height = 6, dpi = 150)

  p2 <- ggplot2::ggplot(dados_exp, ggplot2::aes(x = Gender_label, fill = Gallstone_label)) +
    ggplot2::geom_bar(position = "dodge", width = 0.7) +
    ggplot2::geom_text(
      stat = "count",
      ggplot2::aes(label = after_stat(count)),
      position = ggplot2::position_dodge(width = 0.7),
      vjust = -0.5,
      size = 4
    ) +
    ggplot2::scale_fill_manual(values = c("#E74C3C", "#2ECC71"), name = "Status") +
    ggplot2::labs(
      title = "Distribuicao por Genero e Status de Calculo Biliar",
      x = "Genero",
      y = "Quantidade"
    ) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"))
  ggplot2::ggsave("graficos/02_genero_gallstone.png", p2, width = 8, height = 6, dpi = 150)

  dados_long <- reshape2::melt(
    dados_exp[, c("Gallstone_label", VARS_PRINCIPAIS)],
    id.vars = "Gallstone_label",
    variable.name = "Variavel",
    value.name = "Valor"
  )
  p3 <- ggplot2::ggplot(
    dados_long,
    ggplot2::aes(x = Gallstone_label, y = Valor, fill = Gallstone_label)
  ) +
    ggplot2::geom_boxplot(outlier.alpha = 0.5) +
    ggplot2::facet_wrap(~Variavel, scales = "free_y", ncol = 4) +
    ggplot2::scale_fill_manual(values = c("#E74C3C", "#2ECC71"), name = "Status") +
    ggplot2::labs(title = "Boxplots das Variaveis Principais por Status", x = "", y = "Valor") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      axis.text.x = ggplot2::element_blank(),
      legend.position = "bottom"
    )
  ggplot2::ggsave("graficos/03_boxplots_variaveis.png", p3, width = 14, height = 10, dpi = 150)

  vars_numericas <- names(dados_raw)[sapply(dados_raw, is.numeric)]
  vars_numericas <- setdiff(vars_numericas, "Gallstone")
  cor_matrix <- cor(dados_raw[, vars_numericas], use = "complete.obs")
  png("graficos/04_matriz_correlacao.png", width = 1200, height = 1000, res = 120)
  corrplot::corrplot(
    cor_matrix,
    method = "color",
    type = "upper",
    tl.cex = 0.6,
    tl.col = "black",
    col = colorRampPalette(c("#3498DB", "white", "#E74C3C"))(100),
    title = "Matriz de Correlacao entre Variaveis Numericas",
    mar = c(0, 0, 2, 0),
    addCoef.col = "black",
    number.cex = 0.4
  )
  dev.off()
  cat("Graficos exploratorios salvos em ./graficos/\n")
}

plotar_importancia_feature <- function(importancia, painel_referencia) {
  weights_df <- data.frame(
    Feature = rownames(importancia),
    Importance = importancia[, 1],
    stringsAsFactors = FALSE
  )
  weights_df <- weights_df[order(-weights_df$Importance), ]
  weights_df$Feature <- factor(weights_df$Feature, levels = rev(weights_df$Feature))
  top20 <- head(weights_df, 20)

  p <- ggplot2::ggplot(top20, ggplot2::aes(x = Feature, y = Importance, fill = Feature %in% painel_referencia)) +
    ggplot2::geom_bar(stat = "identity", show.legend = TRUE) +
    ggplot2::scale_fill_manual(
      values = c("FALSE" = "gray70", "TRUE" = "#E74C3C"),
      labels = c("Nao selecionada", "Painel interno de referencia"),
      name = ""
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Importancia das Variaveis (Random Forest)",
      subtitle = "Top 20 variaveis - destaque para o painel interno de referencia",
      x = "",
      y = "Importancia"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5),
      legend.position = "bottom"
    )

  ggplot2::ggsave("graficos/05_feature_importance.png", p, width = 10, height = 8, dpi = 150)
}

plotar_roc <- function(roc_list, arquivo, titulo) {
  cores_modelos <- c(
    "#E74C3C", "#3498DB", "#2ECC71", "#9B59B6", "#F39C12",
    "#1ABC9C", "#E67E22", "#34495E", "#C0392B"
  )

  png(arquivo, width = 900, height = 700, res = 120)
  plot(NULL, xlim = c(1, 0), ylim = c(0, 1), xlab = "Especificidade", ylab = "Sensibilidade", main = titulo)
  abline(a = 0, b = 1, lty = 2, col = "gray60")

  legendas <- character(0)
  cores <- character(0)
  i <- 1
  for (nome_modelo in names(roc_list)) {
    if (!is.null(roc_list[[nome_modelo]])) {
      lines(roc_list[[nome_modelo]], col = cores_modelos[i], lwd = 2)
      legendas <- c(
        legendas,
        sprintf("%s (AUC=%.1f%%)", nome_modelo, round(pROC::auc(roc_list[[nome_modelo]]) * 100, 1))
      )
      cores <- c(cores, cores_modelos[i])
    }
    i <- i + 1
  }

  legend("bottomright", legend = legendas, col = cores, lwd = 2, cex = 0.65, bg = "white")
  dev.off()
}

plotar_graficos_painel_referencia <- function(resultados_8020, resultados_7030, roc_8020, roc_7030) {
  df_cv <- rbind(
    data.frame(Modelo = resultados_8020$Modelo, Acuracia = resultados_8020$Acc_CV, Particao = "CV_8020"),
    data.frame(Modelo = resultados_7030$Modelo, Acuracia = resultados_7030$Acc_CV, Particao = "CV_7030")
  )
  df_cv$Modelo <- factor(df_cv$Modelo, levels = rev(names(MODELOS_CONFIG)))

  p6 <- ggplot2::ggplot(df_cv, ggplot2::aes(x = Modelo, y = Acuracia / 100, fill = Particao)) +
    ggplot2::geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    ggplot2::scale_fill_manual(
      values = c("CV_8020" = "#AED6F1", "CV_7030" = "#F5B7B1"),
      labels = c("CV_8020" = "80/20", "CV_7030" = "70/30")
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Comparacao da Acuracia de Treino (CV) - 70/30 vs 80/20",
      x = "Modelo",
      y = "Acuracia",
      fill = "Particao"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      legend.position = "right"
    )
  ggplot2::ggsave("graficos/06_acuracia_treino_cv.png", p6, width = 10, height = 7, dpi = 150)

  df_cm <- rbind(
    data.frame(Modelo = resultados_8020$Modelo, Acuracia = resultados_8020$Acuracia, Particao = "CM_8020"),
    data.frame(Modelo = resultados_7030$Modelo, Acuracia = resultados_7030$Acuracia, Particao = "CM_7030")
  )
  df_cm$Modelo <- factor(df_cm$Modelo, levels = rev(names(MODELOS_CONFIG)))

  p7 <- ggplot2::ggplot(df_cm, ggplot2::aes(x = Modelo, y = Acuracia / 100, fill = Particao)) +
    ggplot2::geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    ggplot2::scale_fill_manual(
      values = c("CM_8020" = "#AED6F1", "CM_7030" = "#F5B7B1"),
      labels = c("CM_8020" = "80/20", "CM_7030" = "70/30")
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Comparacao da Acuracia do Teste - 70/30 vs 80/20",
      x = "Modelo",
      y = "Acuracia",
      fill = "Particao"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      legend.position = "right"
    )
  ggplot2::ggsave("graficos/07_acuracia_teste_cm.png", p7, width = 10, height = 7, dpi = 150)

  plotar_roc(roc_8020, "graficos/08_curvas_roc_8020.png", "Curvas ROC (Cenario 80/20)")
  plotar_roc(roc_7030, "graficos/09_curvas_roc_7030.png", "Curvas ROC (Cenario 70/30)")

  df_heat_8020 <- reshape2::melt(
    resultados_8020[, c("Modelo", "Acuracia", "Sensibilidade", "Especificidade", "Precisao", "F1", "AUC")],
    id.vars = "Modelo",
    variable.name = "Metrica",
    value.name = "Valor"
  )
  df_heat_8020$Modelo <- factor(df_heat_8020$Modelo, levels = rev(resultados_8020$Modelo))

  p10 <- ggplot2::ggplot(df_heat_8020, ggplot2::aes(x = Metrica, y = Modelo, fill = Valor)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.5) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f", Valor)), size = 3.5, color = "black") +
    ggplot2::scale_fill_gradient2(
      low = "#E74C3C",
      mid = "#F1C40F",
      high = "#2ECC71",
      midpoint = 70,
      limits = c(40, 100),
      name = "Valor (%)"
    ) +
    ggplot2::labs(title = "Heatmap de Metricas por Modelo (Cenario 80/20)", x = "", y = "") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
    )
  ggplot2::ggsave("graficos/10_heatmap_metricas.png", p10, width = 10, height = 6, dpi = 150)

  df_heat_7030 <- reshape2::melt(
    resultados_7030[, c("Modelo", "Acuracia", "Sensibilidade", "Especificidade", "Precisao", "F1", "AUC")],
    id.vars = "Modelo",
    variable.name = "Metrica",
    value.name = "Valor"
  )
  df_heat_7030$Modelo <- factor(df_heat_7030$Modelo, levels = rev(resultados_7030$Modelo))

  p11 <- ggplot2::ggplot(df_heat_7030, ggplot2::aes(x = Metrica, y = Modelo, fill = Valor)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.5) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f", Valor)), size = 3.5, color = "black") +
    ggplot2::scale_fill_gradient2(
      low = "#E74C3C",
      mid = "#F1C40F",
      high = "#2ECC71",
      midpoint = 70,
      limits = c(40, 100),
      name = "Valor (%)"
    ) +
    ggplot2::labs(title = "Heatmap de Metricas por Modelo (Cenario 70/30)", x = "", y = "") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
    )
  ggplot2::ggsave("graficos/11_heatmap_metricas_7030.png", p11, width = 10, height = 6, dpi = 150)

  df_f1 <- rbind(
    data.frame(Modelo = resultados_8020$Modelo, F1 = resultados_8020$F1, Cenario = "80/20"),
    data.frame(Modelo = resultados_7030$Modelo, F1 = resultados_7030$F1, Cenario = "70/30")
  )
  df_f1$Modelo <- factor(df_f1$Modelo, levels = resultados_8020$Modelo)
  p12 <- ggplot2::ggplot(df_f1, ggplot2::aes(x = Modelo, y = F1, fill = Cenario)) +
    ggplot2::geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f", F1)),
      position = ggplot2::position_dodge(width = 0.7),
      vjust = -0.5,
      size = 3
    ) +
    ggplot2::scale_fill_manual(values = c("80/20" = "#9B59B6", "70/30" = "#1ABC9C")) +
    ggplot2::labs(
      title = "F1-Score por Modelo",
      subtitle = "Cenarios 80/20 vs 70/30",
      x = "",
      y = "F1-Score (%)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5),
      axis.text.x = ggplot2::element_text(angle = 35, hjust = 1),
      legend.position = "top"
    ) +
    ggplot2::coord_cartesian(ylim = c(0, 100))
  ggplot2::ggsave("graficos/12_f1score_comparacao.png", p12, width = 12, height = 7, dpi = 150)

  df_auc <- rbind(
    data.frame(Modelo = resultados_8020$Modelo, AUC = resultados_8020$AUC, Cenario = "80/20"),
    data.frame(Modelo = resultados_7030$Modelo, AUC = resultados_7030$AUC, Cenario = "70/30")
  )
  df_auc$Modelo <- factor(df_auc$Modelo, levels = resultados_8020$Modelo)
  p13 <- ggplot2::ggplot(df_auc, ggplot2::aes(x = Modelo, y = AUC, fill = Cenario)) +
    ggplot2::geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f", AUC)),
      position = ggplot2::position_dodge(width = 0.7),
      vjust = -0.5,
      size = 3
    ) +
    ggplot2::scale_fill_manual(values = c("80/20" = "#2C3E50", "70/30" = "#E74C3C")) +
    ggplot2::labs(
      title = "AUC por Modelo",
      subtitle = "Cenarios 80/20 vs 70/30",
      x = "",
      y = "AUC (%)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5),
      axis.text.x = ggplot2::element_text(angle = 35, hjust = 1),
      legend.position = "top"
    ) +
    ggplot2::coord_cartesian(ylim = c(0, 100))
  ggplot2::ggsave("graficos/13_auc_comparacao.png", p13, width = 12, height = 7, dpi = 150)
}

plotar_redundancia <- function(redundancia_8020) {
  pares <- redundancia_8020$pares
  if (nrow(pares) == 0) {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("text", x = 1, y = 1, label = "Nenhum par com |r| >= 0.85", size = 6) +
      ggplot2::theme_void() +
      ggplot2::labs(title = "Redundancia forte entre features (80/20)")
    ggplot2::ggsave("graficos/14_redundancia_correlacoes.png", p, width = 8, height = 5, dpi = 150)
    return(invisible(NULL))
  }

  pares_plot <- rbind(
    pares,
    data.frame(Feature1 = pares$Feature2, Feature2 = pares$Feature1, Correlacao = pares$Correlacao)
  )

  p <- ggplot2::ggplot(pares_plot, ggplot2::aes(x = Feature1, y = Feature2, fill = Correlacao)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", Correlacao)), size = 3) +
    ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", midpoint = 0) +
    ggplot2::labs(
      title = "Redundancia forte entre features (80/20)",
      subtitle = "Apenas pares com |r| >= 0.85",
      x = "",
      y = ""
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 35, hjust = 1),
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )

  ggplot2::ggsave("graficos/14_redundancia_correlacoes.png", p, width = 10, height = 7, dpi = 150)
}

plotar_curva_k <- function(curva_k) {
  if (nrow(curva_k) == 0) {
    return(invisible(NULL))
  }

  curva_melt <- reshape2::melt(
    curva_k[, c("Painel_Base", "Tipo", "k", "AUC", "F1")],
    id.vars = c("Painel_Base", "Tipo", "k"),
    variable.name = "Metrica",
    value.name = "Valor"
  )

  p <- ggplot2::ggplot(curva_melt, ggplot2::aes(x = k, y = Valor, color = Tipo)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::facet_wrap(~Metrica, scales = "free_y") +
    ggplot2::labs(
      title = "Curva de desempenho por numero de features",
      subtitle = "Medias sobre 9 modelos e 2 cenarios",
      x = "Numero de features",
      y = "Valor (%)",
      color = "Tipo de ranking"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )

  ggplot2::ggsave("graficos/15_curva_k_desempenho.png", p, width = 11, height = 6, dpi = 150)
}

plotar_custo_beneficio <- function(resumo_global, painel_recomendado) {
  resumo_plot <- resumo_global
  resumo_plot$Rotulo <- resumo_plot$Painel_Base

  p <- ggplot2::ggplot(
    resumo_plot,
    ggplot2::aes(x = Custo_Total, y = AUC, size = N_Features, color = Recomendado)
  ) +
    ggplot2::geom_point(alpha = 0.8) +
    ggplot2::geom_text(
      ggplot2::aes(label = Rotulo),
      hjust = 0,
      nudge_x = 0.08,
      size = 3.1,
      show.legend = FALSE
    ) +
    ggplot2::scale_color_manual(values = c("FALSE" = "#7F8C8D", "TRUE" = "#E74C3C")) +
    ggplot2::labs(
      title = "Custo-beneficio dos paineis candidatos",
      subtitle = sprintf("Painel recomendado: %s", painel_recomendado$Painel_Base),
      x = "Custo operacional agregado",
      y = "AUC media (%)",
      size = "Numero medio de features",
      color = "Recomendado"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )

  ggplot2::ggsave("graficos/16_custo_beneficio.png", p, width = 12, height = 7, dpi = 150)
}

salvar_resultados_csv <- function(
  cenario_8020,
  cenario_7030,
  resumo_global,
  recomendacao
) {
  write.csv(cenario_8020$relevancia, "resultados/relevancia_8020.csv", row.names = FALSE)
  write.csv(cenario_7030$relevancia, "resultados/relevancia_7030.csv", row.names = FALSE)
  write.csv(cenario_8020$redundancia$pares, "resultados/redundancia_pares_8020.csv", row.names = FALSE)
  write.csv(cenario_7030$redundancia$pares, "resultados/redundancia_pares_7030.csv", row.names = FALSE)
  write.csv(cenario_8020$redundancia$resumo_cluster, "resultados/redundancia_clusters_8020.csv", row.names = FALSE)
  write.csv(cenario_7030$redundancia$resumo_cluster, "resultados/redundancia_clusters_7030.csv", row.names = FALSE)
  write.csv(cenario_8020$resultados_modelos, "resultados/modelos_cenario_8020.csv", row.names = FALSE)
  write.csv(cenario_7030$resultados_modelos, "resultados/modelos_cenario_7030.csv", row.names = FALSE)
  write.csv(cenario_8020$resumo_paineis, "resultados/resumo_paineis_8020.csv", row.names = FALSE)
  write.csv(cenario_7030$resumo_paineis, "resultados/resumo_paineis_7030.csv", row.names = FALSE)
  write.csv(resumo_global, "resultados/resumo_global_paineis.csv", row.names = FALSE)

  painel_referencia_8020_nome <- cenario_8020$painel_referencia
  painel_referencia_7030_nome <- cenario_7030$painel_referencia
  features_referencia_8020 <- cenario_8020$paineis[[painel_referencia_8020_nome]]
  features_referencia_7030 <- cenario_7030$paineis[[painel_referencia_7030_nome]]

  features_recomendadas_8020 <- strsplit(
    recomendacao$recomendacao$Features_8020,
    ", ",
    fixed = TRUE
  )[[1]]
  justificativas_painel <- gerar_justificativas_painel(features_recomendadas_8020)
  texto_realidade <- gerar_texto_realidade(
    features_recomendadas_8020,
    calcular_custo_painel(features_recomendadas_8020)
  )
  nome_painel_referencia <- if (identical(painel_referencia_8020_nome, painel_referencia_7030_nome)) {
    painel_referencia_8020_nome
  } else {
    sprintf("%s (80/20) e %s (70/30)", painel_referencia_8020_nome, painel_referencia_7030_nome)
  }

  contexto <- list(
    gerado_em = Sys.time(),
    conclusao_necessidade = gerar_conclusao_necessidade(recomendacao$recomendacao, resumo_global),
    painel_referencia = list(
      nome_8020 = painel_referencia_8020_nome,
      nome_7030 = painel_referencia_7030_nome,
      features_8020 = paste(features_referencia_8020, collapse = ", "),
      features_7030 = paste(features_referencia_7030, collapse = ", ")
    ),
    painel_recomendado = recomendacao$recomendacao,
    justificativas_painel = justificativas_painel,
    realidade = texto_realidade,
    texto_painel_referencia = sprintf(
      "Painel de referencia interno: **%s**. Features 80/20: %s. Features 70/30: %s.",
      nome_painel_referencia,
      paste(features_referencia_8020, collapse = ", "),
      paste(features_referencia_7030, collapse = ", ")
    ),
    texto_painel_recomendado = sprintf(
      "Painel recomendado: **%s**. Features 80/20: %s. Features 70/30: %s.",
      recomendacao$recomendacao$Painel_Base,
      recomendacao$recomendacao$Features_8020,
      recomendacao$recomendacao$Features_7030
    ),
    texto_custo_recomendado = sprintf(
      "Custo medio do painel recomendado: **%.2f**. Custo 80/20: **%.0f**. Custo 70/30: **%.0f**.",
      recomendacao$recomendacao$Custo_Total,
      recomendacao$recomendacao$Custo_Total_8020,
      recomendacao$recomendacao$Custo_Total_7030
    ),
    texto_realidade = paste(texto_realidade, collapse = "\n\n"),
    texto_justificativas_painel = paste(justificativas_painel, collapse = "\n"),
    links = list(
      uci = "https://archive.ics.uci.edu/dataset/1150/gallstone-1",
      niddk = "https://www.niddk.nih.gov/health-information/digestive-diseases/gallstones/symptoms-causes"
    )
  )
  saveRDS(contexto, "resultados/contexto_relatorio.rds")
}

normalizar_contexto_relatorio <- function(path = "resultados/contexto_relatorio.rds") {
  if (!file.exists(path)) {
    stop("Arquivo de contexto do relatorio nao encontrado.")
  }

  contexto <- readRDS(path)
  painel_recomendado <- contexto$painel_recomendado

  if (is.data.frame(painel_recomendado)) {
    painel_linha <- painel_recomendado[1, , drop = FALSE]
  } else {
    painel_linha <- as.data.frame(painel_recomendado, stringsAsFactors = FALSE)
  }

  features_8020 <- character(0)
  if (!is.null(painel_linha$Features_8020) && nzchar(as.character(painel_linha$Features_8020[1]))) {
    features_8020 <- strsplit(as.character(painel_linha$Features_8020[1]), ", ", fixed = TRUE)[[1]]
  }

  justificativas_painel <- contexto$justificativas_painel
  if ((is.null(justificativas_painel) || length(justificativas_painel) == 0) && length(features_8020) > 0) {
    justificativas_painel <- gerar_justificativas_painel(features_8020)
  }

  texto_realidade_vec <- contexto$realidade
  if ((is.null(texto_realidade_vec) || length(texto_realidade_vec) == 0) && length(features_8020) > 0) {
    texto_realidade_vec <- gerar_texto_realidade(
      features_8020,
      calcular_custo_painel(features_8020)
    )
  }

  painel_referencia <- contexto$painel_referencia
  if (is.null(painel_referencia) || !is.list(painel_referencia)) {
    painel_referencia <- list(
      nome_8020 = "raw_top_10",
      nome_7030 = "raw_top_10",
      features_8020 = "Nao registrado",
      features_7030 = "Nao registrado"
    )
  }

  nome_painel_referencia <- if (identical(painel_referencia$nome_8020, painel_referencia$nome_7030)) {
    painel_referencia$nome_8020
  } else {
    sprintf("%s (80/20) e %s (70/30)", painel_referencia$nome_8020, painel_referencia$nome_7030)
  }

  if (is.null(contexto$texto_painel_referencia)) {
    contexto$texto_painel_referencia <- sprintf(
      "Painel de referencia interno: **%s**. Features 80/20: %s. Features 70/30: %s.",
      nome_painel_referencia,
      painel_referencia$features_8020,
      painel_referencia$features_7030
    )
  }

  if (is.null(contexto$texto_painel_recomendado)) {
    contexto$texto_painel_recomendado <- sprintf(
      "Painel recomendado: **%s**. Features 80/20: %s. Features 70/30: %s.",
      painel_linha$Painel_Base[1],
      painel_linha$Features_8020[1],
      painel_linha$Features_7030[1]
    )
  }

  if (is.null(contexto$texto_custo_recomendado)) {
    contexto$texto_custo_recomendado <- sprintf(
      "Custo medio do painel recomendado: **%.2f**. Custo 80/20: **%.0f**. Custo 70/30: **%.0f**.",
      painel_linha$Custo_Total[1],
      painel_linha$Custo_Total_8020[1],
      painel_linha$Custo_Total_7030[1]
    )
  }

  if (is.null(contexto$texto_realidade) && !is.null(texto_realidade_vec)) {
    contexto$texto_realidade <- paste(texto_realidade_vec, collapse = "\n\n")
  }

  if (is.null(contexto$texto_justificativas_painel) && !is.null(justificativas_painel)) {
    contexto$texto_justificativas_painel <- paste(justificativas_painel, collapse = "\n")
  }

  links_existentes <- contexto$links
  if (is.null(links_existentes) || !is.list(links_existentes)) {
    links_existentes <- list()
  }

  contexto$comparacao_artigos <- NULL
  contexto$texto_artigo_local <- NULL
  contexto$texto_overlap_local_8020 <- NULL
  contexto$texto_overlap_original_8020 <- NULL
  contexto$links <- list(
    uci = if (!is.null(links_existentes$uci)) links_existentes$uci else "https://archive.ics.uci.edu/dataset/1150/gallstone-1",
    niddk = if (!is.null(links_existentes$niddk)) links_existentes$niddk else "https://www.niddk.nih.gov/health-information/digestive-diseases/gallstones/symptoms-causes"
  )

  saveRDS(contexto, path)
  invisible(contexto)
}

escrever_relatorio_rmd <- function() {
  conteudo <- c(
    "---",
    "title: \"Analise de Dados: Gallstone Disease Prediction\"",
    "subtitle: \"Necessidade real de 10 features, custo-beneficio e plausibilidade clinica\"",
    sprintf("date: \"%s\"", format(Sys.Date(), "%d/%m/%Y")),
    "output:",
    "  html_document:",
    "    toc: true",
    "    toc_float: true",
    "    theme: flatly",
    "    number_sections: true",
    "  pdf_document:",
    "    toc: true",
    "---",
    "",
    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)",
    "ctx <- readRDS('resultados/contexto_relatorio.rds')",
    "resumo_global <- read.csv('resultados/resumo_global_paineis.csv', stringsAsFactors = FALSE)",
    "relev_8020 <- read.csv('resultados/relevancia_8020.csv', stringsAsFactors = FALSE)",
    "redu_8020 <- read.csv('resultados/redundancia_pares_8020.csv', stringsAsFactors = FALSE)",
    "clusters_8020 <- read.csv('resultados/redundancia_clusters_8020.csv', stringsAsFactors = FALSE)",
    "painel_referencia_final_8020 <- read.csv('resultados/modelos_painel_referencia_8020.csv', stringsAsFactors = FALSE)",
    "painel_referencia_final_7030 <- read.csv('resultados/modelos_painel_referencia_7030.csv', stringsAsFactors = FALSE)",
    "painel_final_8020 <- read.csv('resultados/modelos_painel_recomendado_8020.csv', stringsAsFactors = FALSE)",
    "painel_final_7030 <- read.csv('resultados/modelos_painel_recomendado_7030.csv', stringsAsFactors = FALSE)",
    "```",
    "",
    "# Introducao",
    "",
    "Este relatorio responde a uma pergunta metodologica e clinica: **o corte fixo em 10 features realmente e necessario nesta base?**",
    "",
    "Toda a analise foi conduzida de forma **data-driven**, sem usar o artigo original como baseline de comparacao. O foco aqui e comparar paineis cumulativos e paineis podados por redundancia, sempre pesando desempenho, custo operacional de coleta e plausibilidade clinica.",
    "",
    "# Dataset e desenho analitico",
    "",
    "- Base: Gallstone Disease Prediction (UCI).",
    "- Amostra: 319 instancias e 38 preditoras.",
    "- Variavel alvo: `Gallstone`.",
    "- Paineis candidatos: `full_38`, `raw_top_k` e `pruned_top_k`.",
    "- Painel de referencia interno: painel bruto com 10 variaveis derivado diretamente do ranking de importancia do treino.",
    "- Triagem dos paineis: 5-fold CV com `tuneLength = 3`.",
    "- Revalidacao final do painel de referencia e do painel recomendado: 10-fold CV com `tuneLength = 5`.",
    "",
    "`r ctx$texto_painel_referencia`",
    "",
    "## Graficos exploratorios",
    "",
    "![](graficos/01_distribuicao_alvo.png)",
    "",
    "![](graficos/02_genero_gallstone.png)",
    "",
    "![](graficos/03_boxplots_variaveis.png)",
    "",
    "![](graficos/04_matriz_correlacao.png)",
    "",
    "# Auditoria cientifica das features",
    "",
    "## Relevancia univariada (80/20)",
    "",
    "As comparacoes univariadas ajudam a separar sinal plausivel de ruido antes da selecao multivariada. Para variaveis numericas foi usado Wilcoxon; para categoricas, Fisher ou qui-quadrado, conforme a frequencia esperada.",
    "",
    "```{r}",
    "knitr::kable(head(relev_8020, 15), digits = 4, caption = 'Top 15 features por relevancia univariada no treino 80/20')",
    "```",
    "",
    "## Redundancia forte entre features (80/20)",
    "",
    "Em medicina aplicada, duas medidas quase equivalentes so devem coexistir se o ganho justificar o custo extra. Nesta base, varias features de composicao corporal andam juntas.",
    "",
    "![](graficos/14_redundancia_correlacoes.png)",
    "",
    "```{r}",
    "knitr::kable(head(redu_8020, 12), digits = 3, caption = 'Pares com |r| >= 0.85 no treino 80/20')",
    "```",
    "",
    "```{r}",
    "knitr::kable(clusters_8020, caption = 'Clusters de redundancia no treino 80/20')",
    "```",
    "",
    "# Paineis candidatos e criterio de escolha",
    "",
    "- `full_38`: todas as variaveis.",
    "- `raw_top_k`: ranking bruto de importancia do Random Forest com k de 3 a 15.",
    "- `pruned_top_k`: ranking apos remover redundancia forte, com k de 3 a 15.",
    "- `raw_top_10`: painel de referencia interno usado para testar se um corte fixo de 10 variaveis faz sentido nos dados.",
    "",
    "Para viabilizar a comparacao extensa de paineis, a **triagem** usou 5-fold CV com `tuneLength = 3`. Depois da escolha do painel, o **painel de referencia interno** e o **painel recomendado** foram rerodados com 10-fold CV e `tuneLength = 5` para a leitura final.",
    "",
    "Regra de decisao usada:",
    "",
    "- Elegivel se ficar ate 1 ponto percentual abaixo da melhor AUC media.",
    "- Elegivel se ficar ate 2 pontos abaixo do melhor F1 medio.",
    "- Elegivel se ficar ate 3 pontos abaixo da melhor sensibilidade media.",
    "- Entre os elegiveis, vence o menor custo operacional.",
    "- Empate: menor numero de features; novo empate: maior sensibilidade.",
    "",
    "![](graficos/15_curva_k_desempenho.png)",
    "",
    "![](graficos/16_custo_beneficio.png)",
    "",
    "```{r}",
    "knitr::kable(head(resumo_global[, c('Painel_Base', 'Acuracia', 'Sensibilidade', 'F1', 'AUC', 'N_Features', 'Custo_Total', 'Elegivel', 'Recomendado')], 15), digits = 2, caption = 'Resumo global dos paineis candidatos')",
    "```",
    "",
    "## Conclusao objetiva",
    "",
    "`r ctx$conclusao_necessidade`",
    "",
    "`r ctx$texto_painel_recomendado`",
    "",
    "`r ctx$texto_custo_recomendado`",
    "",
    "# Por que o painel recomendado faz sentido",
    "",
    "```{r, results='asis'}",
    "cat(ctx$texto_realidade)",
    "```",
    "",
    "## Justificativa feature por feature",
    "",
    "```{r, results='asis'}",
    "cat(ctx$texto_justificativas_painel)",
    "```",
    "",
    "# Desempenho dos 9 modelos no painel de referencia interno",
    "",
    "## Cenario 80/20",
    "",
    "```{r}",
    "knitr::kable(painel_referencia_final_8020[, c('Modelo', 'Acuracia', 'Sensibilidade', 'Especificidade', 'Precisao', 'F1', 'AUC', 'Acc_CV')], digits = 2, caption = 'Painel de referencia interno - cenario 80/20 (revalidado com 10-fold CV)')",
    "```",
    "",
    "## Cenario 70/30",
    "",
    "```{r}",
    "knitr::kable(painel_referencia_final_7030[, c('Modelo', 'Acuracia', 'Sensibilidade', 'Especificidade', 'Precisao', 'F1', 'AUC', 'Acc_CV')], digits = 2, caption = 'Painel de referencia interno - cenario 70/30 (revalidado com 10-fold CV)')",
    "```",
    "",
    "## Painel recomendado (revalidado com 10-fold CV)",
    "",
    "```{r}",
    "knitr::kable(painel_final_8020[, c('Modelo', 'Acuracia', 'Sensibilidade', 'Especificidade', 'Precisao', 'F1', 'AUC', 'Acc_CV')], digits = 2, caption = 'Painel recomendado - cenario 80/20')",
    "```",
    "",
    "```{r}",
    "knitr::kable(painel_final_7030[, c('Modelo', 'Acuracia', 'Sensibilidade', 'Especificidade', 'Precisao', 'F1', 'AUC', 'Acc_CV')], digits = 2, caption = 'Painel recomendado - cenario 70/30')",
    "```",
    "",
    "![](graficos/06_acuracia_treino_cv.png)",
    "",
    "![](graficos/07_acuracia_teste_cm.png)",
    "",
    "![](graficos/08_curvas_roc_8020.png)",
    "",
    "![](graficos/09_curvas_roc_7030.png)",
    "",
    "![](graficos/10_heatmap_metricas.png)",
    "",
    "![](graficos/11_heatmap_metricas_7030.png)",
    "",
    "![](graficos/12_f1score_comparacao.png)",
    "",
    "![](graficos/13_auc_comparacao.png)",
    "",
    "# Faz sentido com a vida real?",
    "",
    "Sim, se a interpretacao for de **suporte a triagem**. O relatorio nao assume causalidade e nao vende o modelo como substituto de imagem. O ponto central e que um painel pequeno, estavel e de menor custo operacional costuma ser mais util em pratica do que um painel maior cuja melhora media e marginal.",
    "",
    "Tambem ha um cuidado importante: **feature preditiva nao e automaticamente fator de risco epidemiologico**. Obesidade, metabolismo lipidico, diabetes e inflamacao continuam clinicamente relevantes mesmo quando uma variavel especifica nao aparece no topo do ranking em todos os splits.",
    "",
    "# Limitacoes",
    "",
    "- Base pequena e de centro unico.",
    "- Possivel instabilidade de ranking em amostra tabular curta.",
    "- Algumas variaveis de bioimpedancia sao fortemente redundantes.",
    "- O painel recomendado otimiza custo-beneficio interno da base, nao valida generalizacao externa.",
    "",
    "# Referencias",
    "",
    "- UCI ML Repository: https://archive.ics.uci.edu/dataset/1150/gallstone-1",
    "- Referencia clinica oficial: https://www.niddk.nih.gov/health-information/digestive-diseases/gallstones/symptoms-causes"
  )

  writeLines(conteudo, "relatorio_gallstone.Rmd")
}

renderizar_relatorio <- function() {
  cat("\n=== Gerando relatorio ===\n")
  normalizar_contexto_relatorio()
  escrever_relatorio_rmd()
  cat("relatorio_gallstone.Rmd criado.\n")

  tryCatch({
    if (requireNamespace("rmarkdown", quietly = TRUE)) {
      rmarkdown::render(
        "relatorio_gallstone.Rmd",
        output_format = "html_document",
        output_file = "relatorio_gallstone.html",
        quiet = TRUE
      )
      cat("relatorio_gallstone.html gerado.\n")

      tryCatch({
        rmarkdown::render(
          "relatorio_gallstone.Rmd",
          output_format = "pdf_document",
          output_file = "relatorio_gallstone.pdf",
          quiet = TRUE
        )
        cat("relatorio_gallstone.pdf gerado.\n")
      }, error = function(e) {
        cat("PDF nao gerado (requer LaTeX). Use HTML ou instale tinytex.\n")
      })
    }
  }, error = function(e) {
    cat("Para gerar o relatorio, abra relatorio_gallstone.Rmd no RStudio e clique Knit.\n")
  })
}

salvar_tabelas_painel_referencia <- function(resultados_8020, resultados_7030) {
  tabela_principal <- data.frame(
    Algoritmo = resultados_8020$Modelo,
    Teste_8020 = resultados_8020$Acuracia,
    Treino_CV_8020 = resultados_8020$Acc_CV,
    Teste_7030 = resultados_7030$Acuracia,
    Treino_CV_7030 = resultados_7030$Acc_CV,
    stringsAsFactors = FALSE
  )
  names(tabela_principal) <- c(
    "Algoritmo", "Teste 80/20 (%)", "Treino CV 80/20 (%)",
    "Teste 70/30 (%)", "Treino CV 70/30 (%)"
  )

  write.csv(tabela_principal, "resultados/tabela_painel_referencia_interno.csv", row.names = FALSE)
}

main <- function() {
  carregar_pacotes()
  garantir_diretorios()

  dados_raw <- carregar_dados("gallstone.csv")
  imprimir_resumo_dataset(dados_raw)
  criar_graficos_exploratorios(dados_raw)

  cat("\n=== Pre-processamento ===\n")
  dados <- preparar_dados_modelagem(dados_raw)
  preditoras <- setdiff(names(dados), "Gallstone")
  cat(sprintf("Preditoras: %d\n", length(preditoras)))

  set.seed(123)
  idx_8020 <- caret::createDataPartition(dados$Gallstone, p = 0.8, list = FALSE)
  treino_8020 <- dados[idx_8020, ]
  teste_8020 <- dados[-idx_8020, ]

  set.seed(123)
  idx_7030 <- caret::createDataPartition(dados$Gallstone, p = 0.7, list = FALSE)
  treino_7030 <- dados[idx_7030, ]
  teste_7030 <- dados[-idx_7030, ]

  cat(sprintf("Cenario 80/20 - Treino: %d | Teste: %d\n", nrow(treino_8020), nrow(teste_8020)))
  cat(sprintf("Cenario 70/30 - Treino: %d | Teste: %d\n", nrow(treino_7030), nrow(teste_7030)))

  ctrl_triagem <- caret::trainControl(
    method = "cv",
    number = 5,
    classProbs = TRUE,
    summaryFunction = caret::twoClassSummary,
    savePredictions = "final"
  )
  ctrl_final <- caret::trainControl(
    method = "cv",
    number = 10,
    classProbs = TRUE,
    summaryFunction = caret::twoClassSummary,
    savePredictions = "final"
  )

  cenario_8020 <- avaliar_cenario(
    "80/20",
    treino_8020,
    teste_8020,
    preditoras,
    ctrl_triagem,
    max_k = 15,
    tune_length = 3
  )
  cenario_7030 <- avaliar_cenario(
    "70/30",
    treino_7030,
    teste_7030,
    preditoras,
    ctrl_triagem,
    max_k = 15,
    tune_length = 3
  )

  painel_referencia_8020_nome <- cenario_8020$painel_referencia
  painel_referencia_7030_nome <- cenario_7030$painel_referencia
  features_referencia_8020 <- cenario_8020$paineis[[painel_referencia_8020_nome]]
  features_referencia_7030 <- cenario_7030$paineis[[painel_referencia_7030_nome]]
  plotar_importancia_feature(cenario_8020$rf_info$importancia, features_referencia_8020)

  resumo_global <- consolidar_resumo_global(cenario_8020$resumo_paineis, cenario_7030$resumo_paineis)
  recomendacao <- selecionar_painel_recomendado(resumo_global)
  curva_k <- montar_curva_k(recomendacao$resumo_global)
  painel_referencia_nome <- obter_nome_painel_referencia_interno(recomendacao$resumo_global$Painel_Base)

  plotar_redundancia(cenario_8020$redundancia)
  plotar_curva_k(curva_k)
  plotar_custo_beneficio(recomendacao$resumo_global, recomendacao$recomendacao)

  painel_referencia_final_8020 <- avaliar_painel(
    nome_painel = painel_referencia_8020_nome,
    cenario = "80/20",
    features = cenario_8020$paineis[[painel_referencia_8020_nome]],
    treino = treino_8020,
    teste = teste_8020,
    ctrl = ctrl_final,
    guardar_roc = TRUE,
    tune_length = 5
  )
  painel_referencia_final_7030 <- avaliar_painel(
    nome_painel = painel_referencia_7030_nome,
    cenario = "70/30",
    features = cenario_7030$paineis[[painel_referencia_7030_nome]],
    treino = treino_7030,
    teste = teste_7030,
    ctrl = ctrl_final,
    guardar_roc = TRUE,
    tune_length = 5
  )

  painel_recomendado_nome <- recomendacao$recomendacao$Painel_Base
  recomendado_final_8020 <- if (identical(painel_recomendado_nome, painel_referencia_nome)) {
    painel_referencia_final_8020
  } else {
    avaliar_painel(
      nome_painel = painel_recomendado_nome,
      cenario = "80/20",
      features = cenario_8020$paineis[[painel_recomendado_nome]],
      treino = treino_8020,
      teste = teste_8020,
      ctrl = ctrl_final,
      guardar_roc = FALSE,
      tune_length = 5
    )
  }
  recomendado_final_7030 <- if (identical(painel_recomendado_nome, painel_referencia_nome)) {
    painel_referencia_final_7030
  } else {
    avaliar_painel(
      nome_painel = painel_recomendado_nome,
      cenario = "70/30",
      features = cenario_7030$paineis[[painel_recomendado_nome]],
      treino = treino_7030,
      teste = teste_7030,
      ctrl = ctrl_final,
      guardar_roc = FALSE,
      tune_length = 5
    )
  }

  plotar_graficos_painel_referencia(
    painel_referencia_final_8020$resultados,
    painel_referencia_final_7030$resultados,
    painel_referencia_final_8020$roc,
    painel_referencia_final_7030$roc
  )

  write.csv(painel_referencia_final_8020$resultados, "resultados/modelos_painel_referencia_8020.csv", row.names = FALSE)
  write.csv(painel_referencia_final_7030$resultados, "resultados/modelos_painel_referencia_7030.csv", row.names = FALSE)
  write.csv(recomendado_final_8020$resultados, "resultados/modelos_painel_recomendado_8020.csv", row.names = FALSE)
  write.csv(recomendado_final_7030$resultados, "resultados/modelos_painel_recomendado_7030.csv", row.names = FALSE)

  salvar_tabelas_painel_referencia(painel_referencia_final_8020$resultados, painel_referencia_final_7030$resultados)
  salvar_resultados_csv(
    cenario_8020 = cenario_8020,
    cenario_7030 = cenario_7030,
    resumo_global = recomendacao$resumo_global,
    recomendacao = recomendacao
  )
  renderizar_relatorio()

  cat("\n=====================================================================\n")
  cat("                    ANALISE CONCLUIDA                                \n")
  cat("=====================================================================\n")
  cat(sprintf(
    "Painel de referencia interno (80/20 - %s): %s\n",
    painel_referencia_8020_nome,
    formatar_lista_inline(features_referencia_8020)
  ))
  cat(sprintf(
    "Painel de referencia interno (70/30 - %s): %s\n",
    painel_referencia_7030_nome,
    formatar_lista_inline(features_referencia_7030)
  ))
  cat(sprintf(
    "Painel recomendado: %s | custo medio %.2f | AUC media %.2f\n",
    recomendacao$recomendacao$Painel_Base,
    recomendacao$recomendacao$Custo_Total,
    recomendacao$recomendacao$AUC
  ))
  cat(gerar_conclusao_necessidade(recomendacao$recomendacao, recomendacao$resumo_global), "\n")
  cat("Arquivos principais: resultados/*.csv | relatorio_gallstone.Rmd | relatorio_gallstone.html\n")
  cat("=====================================================================\n")
}

if (sys.nframe() == 0) {
  main()
}
