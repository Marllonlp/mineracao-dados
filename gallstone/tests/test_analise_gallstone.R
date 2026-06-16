source("analise_gallstone.R")

toy <- data.frame(
  Gallstone = factor(
    c("Positivo", "Positivo", "Positivo", "Positivo", "Negativo", "Negativo", "Negativo", "Negativo"),
    levels = c("Positivo", "Negativo")
  ),
  A = c(1, 2, 3, 4, 5, 6, 7, 8),
  B = c(2, 4, 6, 8, 10, 12, 14, 16),
  C = c(8, 7, 6, 5, 4, 3, 2, 1),
  Gender = factor(c(0, 0, 1, 1, 0, 1, 0, 1))
)

redu <- detectar_redundancia(toy, limite = 0.95)
pares_ab <- with(redu$pares, (Feature1 == "A" & Feature2 == "B") | (Feature1 == "B" & Feature2 == "A"))
stopifnot(any(pares_ab))

ranking <- c("A", "B", "Gender", "C")
ranking_podado <- prune_ranked_features(ranking, redu$cluster_map)
stopifnot(identical(ranking_podado, c("A", "Gender")))

custo <- calcular_custo_painel(c("Age", "BMI", "CRP", "TBW", "HFA"))
stopifnot(custo$custo_total == 11)
stopifnot(identical(custo$grupos, c("Historia", "Antropometria", "Laboratorio", "Bioimpedancia", "HFA")))

resumo_teste <- data.frame(
  Painel_Base = c("raw_top_10", "raw_top_08", "pruned_top_06"),
  Acuracia = c(89.0, 88.5, 88.2),
  Sensibilidade = c(87.0, 85.5, 84.3),
  Especificidade = c(90.0, 89.0, 88.5),
  Precisao = c(88.0, 87.0, 86.4),
  F1 = c(88.0, 87.0, 86.5),
  AUC = c(90.0, 89.5, 89.4),
  Acc_CV = c(84.0, 84.1, 83.8),
  N_Features = c(10, 8, 6),
  Custo_Total = c(9, 6, 5),
  N_Features_8020 = c(10, 8, 6),
  Features_8020 = c("CRP, VitaminD", "CRP, VitaminD", "CRP, BMI"),
  Origens_8020 = c("Laboratorio + Bioimpedancia", "Laboratorio + Bioimpedancia", "Historia + Laboratorio"),
  Custo_Total_8020 = c(9, 6, 5),
  N_Features_7030 = c(10, 8, 6),
  Features_7030 = c("CRP, VitaminD", "CRP, VitaminD", "CRP, BMI"),
  Origens_7030 = c("Laboratorio + Bioimpedancia", "Laboratorio + Bioimpedancia", "Historia + Laboratorio"),
  Custo_Total_7030 = c(9, 6, 5),
  stringsAsFactors = FALSE
)

sel <- selecionar_painel_recomendado(resumo_teste)
stopifnot(sel$recomendacao$Painel_Base == "pruned_top_06")
stopifnot(any(sel$resumo_global$Elegivel))
stopifnot(any(sel$resumo_global$Recomendado))

contexto_legado <- list(
  gerado_em = Sys.time(),
  comparacao_artigos = list(
    local_info = list(
      quantidade_afirmada = 10,
      quantidade_nomeada = 9,
      features = c("CRP", "VitaminD")
    ),
    overlap_8020 = c("CRP", "VitaminD"),
    overlap_original_8020 = c("CRP")
  ),
  conclusao_necessidade = "Conclusao teste.",
  painel_recomendado = data.frame(
    Painel_Base = "pruned_top_02",
    Features_8020 = "CRP, VitaminD",
    Features_7030 = "CRP, VitaminD",
    Custo_Total = 4,
    Custo_Total_8020 = 4,
    Custo_Total_7030 = 4,
    stringsAsFactors = FALSE
  ),
  justificativas_painel = c("- item 1", "- item 2"),
  realidade = c("linha 1", "linha 2"),
  links = list()
)

arquivo_ctx <- tempfile(fileext = ".rds")
saveRDS(contexto_legado, arquivo_ctx)
normalizar_contexto_relatorio(arquivo_ctx)
ctx_norm <- readRDS(arquivo_ctx)
stopifnot(all(c(
  "texto_painel_recomendado",
  "texto_custo_recomendado",
  "texto_realidade",
  "texto_justificativas_painel"
) %in% names(ctx_norm)))
stopifnot(!any(c(
  "comparacao_artigos",
  "texto_artigo_local",
  "texto_overlap_local_8020",
  "texto_overlap_original_8020"
) %in% names(ctx_norm)))
stopifnot(grepl("Painel recomendado", ctx_norm$texto_painel_recomendado, fixed = TRUE))
stopifnot(identical(ctx_norm$texto_realidade, "linha 1\n\nlinha 2"))
unlink(arquivo_ctx)

cat("Todos os testes de sanidade passaram.\n")
