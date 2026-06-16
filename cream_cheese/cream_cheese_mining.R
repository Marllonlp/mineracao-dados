# -*- coding: UTF-8 -*-

required_packages <- c("foreign", "cluster", "rpart")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Pacotes R ausentes: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

set.seed(20260608)

root_dir <- getwd()
zip_path <- file.path(root_dir, "SPSS_CreamCheese.zip")
out_dir <- file.path(root_dir, "cream_cheese_outputs")
fig_dir <- file.path(out_dir, "figures")
table_dir <- file.path(out_dir, "tables")
report_path <- file.path(root_dir, "relatorio_padroes_cream_cheese.md")

dir.create(out_dir, showWarnings = FALSE)
dir.create(fig_dir, showWarnings = FALSE)
dir.create(table_dir, showWarnings = FALSE)

if (!file.exists(zip_path)) {
  stop("Arquivo SPSS_CreamCheese.zip nao encontrado em: ", root_dir, call. = FALSE)
}

extract_dir <- file.path(tempdir(), "cream_cheese_spss")
if (dir.exists(extract_dir)) {
  unlink(extract_dir, recursive = TRUE)
}
dir.create(extract_dir, showWarnings = FALSE)
utils::unzip(zip_path, exdir = extract_dir)
sav_files <- list.files(extract_dir, pattern = "\\.sav$", recursive = TRUE, full.names = TRUE)
if (length(sav_files) != 1) {
  stop("Esperava encontrar exatamente um arquivo .sav dentro do ZIP; encontrados: ", length(sav_files), call. = FALSE)
}

raw_data <- foreign::read.spss(sav_files[[1]], to.data.frame = TRUE, use.value.labels = FALSE)
data <- as.data.frame(raw_data, stringsAsFactors = FALSE)
source_nrow <- nrow(data)
source_ncol <- ncol(data)

id_vars <- c("Productname", "Productnumber", "Panellist", "Replicate", "Session", "Servingorder")
sensory_vars <- setdiff(names(data), id_vars)
target_var <- "MCreaminess"
driver_vars <- setdiff(sensory_vars, target_var)

data$Productnumber <- as.integer(data$Productnumber)
data$Panellist <- as.integer(data$Panellist)
data$Replicate <- as.integer(data$Replicate)
data$Session <- as.integer(data$Session)
data$Servingorder <- as.integer(data$Servingorder)
data$Productlabel <- paste0(sprintf("%02d", data$Productnumber), " - ", data$Productname)

expected_checks <- data.frame(
  Check = c("Linhas", "Colunas", "Valores ausentes", "Produtos", "Provadores", "Replicas", "Variaveis sensoriais"),
  Observed = c(
    source_nrow,
    source_ncol,
    sum(is.na(data)),
    length(unique(data$Productnumber)),
    length(unique(data$Panellist)),
    length(unique(data$Replicate)),
    length(sensory_vars)
  ),
  Expected = c(240, 29, 0, 10, 8, 3, 23),
  Pass = c(
    source_nrow == 240,
    source_ncol == 29,
    sum(is.na(data)) == 0,
    length(unique(data$Productnumber)) == 10,
    length(unique(data$Panellist)) == 8,
    length(unique(data$Replicate)) == 3,
    length(sensory_vars) == 23
  )
)

write.csv(expected_checks, file.path(table_dir, "quality_checks.csv"), row.names = FALSE, fileEncoding = "UTF-8")
if (!all(expected_checks$Pass)) {
  stop("Falha nas validacoes iniciais. Veja cream_cheese_outputs/tables/quality_checks.csv", call. = FALSE)
}

fmt_num <- function(x, digits = 2) {
  ifelse(is.na(x), "", formatC(x, format = "f", digits = digits, decimal.mark = ","))
}

fmt_p <- function(p) {
  ifelse(is.na(p), "", ifelse(p < 0.001, "< 0,001", fmt_num(p, 3)))
}

fmt_pct <- function(x, digits = 1) {
  paste0(fmt_num(100 * x, digits), "%")
}

as_label <- function(productnumber, productname) {
  paste0(sprintf("%02d", productnumber), " - ", productname)
}

write_table <- function(df, name) {
  write.csv(df, file.path(table_dir, name), row.names = FALSE, fileEncoding = "UTF-8")
}

md_table <- function(df, n = nrow(df), digits = 3) {
  if (nrow(df) == 0) {
    return("_Nenhuma linha atende aos criterios._")
  }
  shown <- head(df, n)
  for (col in names(shown)) {
    if (is.numeric(shown[[col]])) {
      shown[[col]] <- fmt_num(shown[[col]], digits)
    }
  }
  shown[] <- lapply(shown, as.character)
  header <- paste0("| ", paste(names(shown), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(shown)), collapse = " | "), " |")
  rows <- apply(shown, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  c(header, sep, rows)
}

eta_sq_oneway <- function(y, group) {
  fit <- stats::aov(y ~ factor(group))
  an <- summary(fit)[[1]]
  an[["Sum Sq"]][1] / sum(an[["Sum Sq"]], na.rm = TRUE)
}

anova_rows <- lapply(sensory_vars, function(v) {
  fit <- stats::aov(data[[v]] ~ factor(data$Productnumber))
  an <- summary(fit)[[1]]
  means <- stats::aggregate(data[[v]], by = list(Productlabel = data$Productlabel), FUN = mean)
  names(means)[2] <- "Mean"
  means <- means[order(means$Mean), ]
  data.frame(
    Variable = v,
    P_value = an[["Pr(>F)"]][1],
    Eta_sq = eta_sq_oneway(data[[v]], data$Productnumber),
    Lowest_product = means$Productlabel[1],
    Lowest_mean = means$Mean[1],
    Highest_product = means$Productlabel[nrow(means)],
    Highest_mean = means$Mean[nrow(means)],
    stringsAsFactors = FALSE
  )
})
anova_results <- do.call(rbind, anova_rows)
anova_results <- anova_results[order(-anova_results$Eta_sq, anova_results$P_value), ]
write_table(anova_results, "anova_product_effects.csv")

product_means <- stats::aggregate(
  data[sensory_vars],
  by = list(Productnumber = data$Productnumber, Productname = data$Productname),
  FUN = mean
)
product_means <- product_means[order(product_means$Productnumber), ]
product_means$Productlabel <- as_label(product_means$Productnumber, product_means$Productname)
product_means <- product_means[, c("Productnumber", "Productname", "Productlabel", sensory_vars)]
write_table(product_means, "product_mean_profiles.csv")

creaminess_rank <- product_means[order(-product_means[[target_var]]), c("Productnumber", "Productname", "Productlabel", target_var, "MFat", "MChalky", "MMeltdown", "MFirm", "MSour")]
write_table(creaminess_rank, "creaminess_product_ranking.csv")

corr_rows <- lapply(driver_vars, function(v) {
  ct <- stats::cor.test(data[[v]], data[[target_var]], method = "pearson")
  data.frame(
    Variable = v,
    Correlation = unname(ct$estimate),
    P_value = ct$p.value,
    Direction = ifelse(unname(ct$estimate) >= 0, "positiva", "negativa"),
    stringsAsFactors = FALSE
  )
})
corr_results <- do.call(rbind, corr_rows)
corr_results <- corr_results[order(-abs(corr_results$Correlation)), ]
write_table(corr_results, "creaminess_correlations.csv")

top_lm_vars <- head(corr_results$Variable, 6)
lm_formula <- stats::as.formula(paste(target_var, "~", paste(top_lm_vars, collapse = " + ")))
lm_fit <- stats::lm(lm_formula, data = data)
lm_summary <- summary(lm_fit)
lm_coefficients <- as.data.frame(lm_summary$coefficients)
lm_coefficients$Term <- rownames(lm_coefficients)
rownames(lm_coefficients) <- NULL
lm_coefficients <- lm_coefficients[, c("Term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]
names(lm_coefficients) <- c("Term", "Estimate", "Std_error", "T_value", "P_value")
write_table(lm_coefficients, "creaminess_linear_model.csv")

tree_data <- data[, c(target_var, driver_vars)]
tree_fit <- rpart::rpart(
  stats::as.formula(paste(target_var, "~ .")),
  data = tree_data,
  method = "anova",
  control = rpart::rpart.control(cp = 0.01, minbucket = 10)
)
tree_importance <- data.frame(
  Variable = names(tree_fit$variable.importance),
  Importance = as.numeric(tree_fit$variable.importance),
  stringsAsFactors = FALSE
)
if (nrow(tree_importance) > 0) {
  tree_importance <- tree_importance[order(-tree_importance$Importance), ]
}
write_table(tree_importance, "creaminess_tree_importance.csv")

png(file.path(fig_dir, "creaminess_tree.png"), width = 1100, height = 750)
plot(tree_fit, uniform = TRUE, margin = 0.08, branch = 0.5)
text(tree_fit, use.n = TRUE, cex = 0.7)
dev.off()

scaled_product <- scale(product_means[sensory_vars])
pca_fit <- stats::prcomp(scaled_product, scale. = FALSE)
pca_importance <- summary(pca_fit)$importance
pca_scores <- as.data.frame(pca_fit$x[, 1:5])
pca_scores$Productnumber <- product_means$Productnumber
pca_scores$Productname <- product_means$Productname
pca_scores$Productlabel <- product_means$Productlabel
pca_scores <- pca_scores[, c("Productnumber", "Productname", "Productlabel", "PC1", "PC2", "PC3", "PC4", "PC5")]
pca_loadings <- as.data.frame(pca_fit$rotation[, 1:5])
pca_loadings$Variable <- rownames(pca_loadings)
pca_loadings <- pca_loadings[, c("Variable", "PC1", "PC2", "PC3", "PC4", "PC5")]
write_table(pca_scores, "pca_product_scores.csv")
write_table(pca_loadings, "pca_attribute_loadings.csv")

png(file.path(fig_dir, "pca_products.png"), width = 1100, height = 850)
plot(
  pca_scores$PC1,
  pca_scores$PC2,
  type = "n",
  xlab = paste0("PC1 (", fmt_pct(pca_importance[2, 1]), " da variancia)"),
  ylab = paste0("PC2 (", fmt_pct(pca_importance[2, 2]), " da variancia)"),
  main = "Produtos no espaco PCA dos atributos sensoriais"
)
abline(h = 0, v = 0, col = "gray80", lty = 2)
text(pca_scores$PC1, pca_scores$PC2, labels = pca_scores$Productlabel, cex = 0.82)
dev.off()

dist_product <- stats::dist(scaled_product)
cluster_fit <- stats::kmeans(scaled_product, centers = 3, nstart = 100)
silhouette_fit <- cluster::silhouette(cluster_fit$cluster, dist_product)
avg_silhouette <- mean(silhouette_fit[, "sil_width"])
hclust_fit <- stats::hclust(dist_product, method = "ward.D2")

cluster_assignments <- data.frame(
  Productnumber = product_means$Productnumber,
  Productname = product_means$Productname,
  Productlabel = product_means$Productlabel,
  Cluster = cluster_fit$cluster,
  stringsAsFactors = FALSE
)
cluster_assignments <- cluster_assignments[order(cluster_assignments$Cluster, cluster_assignments$Productnumber), ]
write_table(cluster_assignments, "cluster_assignments.csv")

cluster_profile_rows <- list()
global_means <- colMeans(product_means[sensory_vars])
global_sds <- apply(product_means[sensory_vars], 2, stats::sd)
for (cl in sort(unique(cluster_fit$cluster))) {
  idx <- cluster_fit$cluster == cl
  cluster_means <- colMeans(product_means[idx, sensory_vars, drop = FALSE])
  z_profile <- (cluster_means - global_means) / global_sds
  high_attrs <- names(sort(z_profile, decreasing = TRUE))[1:4]
  low_attrs <- names(sort(z_profile, decreasing = FALSE))[1:4]
  cluster_profile_rows[[length(cluster_profile_rows) + 1]] <- data.frame(
    Cluster = cl,
    Products = paste(product_means$Productlabel[idx], collapse = "; "),
    Above_average_attributes = paste(high_attrs, collapse = ", "),
    Below_average_attributes = paste(low_attrs, collapse = ", "),
    Mean_MCreaminess = mean(product_means[[target_var]][idx]),
    stringsAsFactors = FALSE
  )
}
cluster_profiles <- do.call(rbind, cluster_profile_rows)
write_table(cluster_profiles, "cluster_profiles.csv")

png(file.path(fig_dir, "cluster_dendrogram.png"), width = 1100, height = 800)
plot(hclust_fit, labels = product_means$Productlabel, main = "Cluster hierarquico dos produtos", xlab = "", sub = "")
rect.hclust(hclust_fit, k = 3, border = c("#2C7BB6", "#D7191C", "#FDAE61"))
dev.off()

png(file.path(fig_dir, "creaminess_ranking.png"), width = 1100, height = 800)
barplot(
  creaminess_rank[[target_var]],
  names.arg = creaminess_rank$Productlabel,
  las = 2,
  col = "#6BAED6",
  ylab = "Media de MCreaminess",
  main = "Ranking medio de cremosidade por produto"
)
dev.off()

top_corr_plot <- corr_results[order(corr_results$Correlation), ]
top_corr_plot <- rbind(head(top_corr_plot, 6), tail(top_corr_plot, 6))
png(file.path(fig_dir, "creaminess_correlations.png"), width = 1100, height = 800)
bar_cols <- ifelse(top_corr_plot$Correlation >= 0, "#2C7BB6", "#D7191C")
barplot(
  top_corr_plot$Correlation,
  names.arg = top_corr_plot$Variable,
  horiz = TRUE,
  las = 1,
  col = bar_cols,
  xlab = "Correlacao com MCreaminess",
  main = "Atributos mais associados a cremosidade"
)
abline(v = 0, col = "gray30")
dev.off()

png(file.path(fig_dir, "anova_eta_sq.png"), width = 1100, height = 800)
anova_plot <- head(anova_results, 12)
barplot(
  rev(anova_plot$Eta_sq),
  names.arg = rev(anova_plot$Variable),
  horiz = TRUE,
  las = 1,
  col = "#74C476",
  xlab = "Eta-quadrado do efeito de produto",
  main = "Atributos que mais separam produtos"
)
dev.off()

target_high <- data[[target_var]] >= stats::quantile(data[[target_var]], 0.75, na.rm = TRUE)
base_rate <- mean(target_high)
rules <- list()

add_rule <- function(rule_name, condition) {
  antecedent_count <- sum(condition, na.rm = TRUE)
  hit_count <- sum(condition & target_high, na.rm = TRUE)
  if (antecedent_count == 0) {
    return(invisible(NULL))
  }
  confidence <- hit_count / antecedent_count
  rules[[length(rules) + 1]] <<- data.frame(
    Rule = rule_name,
    Antecedent_count = antecedent_count,
    Hit_count = hit_count,
    Support = hit_count / nrow(data),
    Confidence = confidence,
    Lift = confidence / base_rate,
    stringsAsFactors = FALSE
  )
}

for (v in driver_vars) {
  q25 <- stats::quantile(data[[v]], 0.25, na.rm = TRUE)
  q75 <- stats::quantile(data[[v]], 0.75, na.rm = TRUE)
  add_rule(paste0(v, " alto => MCreaminess alto"), data[[v]] >= q75)
  add_rule(paste0(v, " baixo => MCreaminess alto"), data[[v]] <= q25)
}

top_rule_vars <- head(corr_results$Variable, 8)
if (length(top_rule_vars) >= 2) {
  pairs <- utils::combn(top_rule_vars, 2, simplify = FALSE)
  corr_lookup <- setNames(corr_results$Correlation, corr_results$Variable)
  for (pair in pairs) {
    conds <- list()
    labels <- character(0)
    for (v in pair) {
      if (corr_lookup[[v]] >= 0) {
        conds[[v]] <- data[[v]] >= stats::quantile(data[[v]], 0.75, na.rm = TRUE)
        labels <- c(labels, paste0(v, " alto"))
      } else {
        conds[[v]] <- data[[v]] <= stats::quantile(data[[v]], 0.25, na.rm = TRUE)
        labels <- c(labels, paste0(v, " baixo"))
      }
    }
    add_rule(paste0(paste(labels, collapse = " + "), " => MCreaminess alto"), conds[[1]] & conds[[2]])
  }
}

rules_results <- do.call(rbind, rules)
rules_results <- rules_results[
  rules_results$Antecedent_count >= 12 &
    rules_results$Support >= 0.04 &
    rules_results$Lift >= 1.25,
]
rules_results <- rules_results[order(-rules_results$Lift, -rules_results$Confidence, -rules_results$Support), ]
write_table(rules_results, "association_rules_high_creaminess.csv")

control_rows <- lapply(sensory_vars, function(v) {
  fit <- stats::aov(stats::as.formula(paste(v, "~ factor(Productnumber) + factor(Panellist) + factor(Replicate) + factor(Session) + factor(Servingorder)")), data = data)
  an <- summary(fit)[[1]]
  terms <- trimws(rownames(an))
  get_anova_value <- function(term, column) {
    idx <- which(terms == term)
    if (length(idx) == 0) {
      return(NA_real_)
    }
    an[idx[1], column]
  }
  data.frame(
    Variable = v,
    Product_p = get_anova_value("factor(Productnumber)", "Pr(>F)"),
    Panellist_p = get_anova_value("factor(Panellist)", "Pr(>F)"),
    Replicate_p = get_anova_value("factor(Replicate)", "Pr(>F)"),
    Session_p = get_anova_value("factor(Session)", "Pr(>F)"),
    Servingorder_p = get_anova_value("factor(Servingorder)", "Pr(>F)"),
    Product_eta = get_anova_value("factor(Productnumber)", "Sum Sq") / sum(an[["Sum Sq"]], na.rm = TRUE),
    stringsAsFactors = FALSE
  )
})
control_effects <- do.call(rbind, control_rows)
write_table(control_effects, "control_effects_by_attribute.csv")

control_summary <- data.frame(
  Effect = c("Produto", "Provador", "Replica", "Sessao", "Ordem de servico"),
  Significant_attributes_p_lt_0_05 = c(
    sum(control_effects$Product_p < 0.05),
    sum(control_effects$Panellist_p < 0.05),
    sum(control_effects$Replicate_p < 0.05),
    sum(control_effects$Session_p < 0.05),
    sum(control_effects$Servingorder_p < 0.05)
  ),
  stringsAsFactors = FALSE
)
write_table(control_summary, "control_effects_summary.csv")

pc1_top_pos <- head(pca_loadings[order(-pca_loadings$PC1), c("Variable", "PC1")], 5)
pc1_top_neg <- head(pca_loadings[order(pca_loadings$PC1), c("Variable", "PC1")], 5)
pc2_top_pos <- head(pca_loadings[order(-pca_loadings$PC2), c("Variable", "PC2")], 5)
pc2_top_neg <- head(pca_loadings[order(pca_loadings$PC2), c("Variable", "PC2")], 5)

top_anova <- head(anova_results, 6)
significant_anova_count <- sum(anova_results$P_value < 0.05)
top_positive_corr <- head(corr_results[order(-corr_results$Correlation), ], 6)
top_negative_corr <- head(corr_results[order(corr_results$Correlation), ], 6)
best_rules <- head(rules_results, 6)
target_control <- control_effects[control_effects$Variable == target_var, ]

report_lines <- c(
  "# Mineração de dados sensoriais: Cream Cheese",
  "",
  "## Como ler este relatório",
  "",
  "Este relatório foi gerado automaticamente por `cream_cheese_mining.R`. A análise usa o arquivo `SPSS_CreamCheese.zip`, lê o `.sav` com `foreign::read.spss` e trabalha somente com R e pacotes já disponíveis.",
  "",
  "Cada padrão útil abaixo traz quatro partes: descrição, evidência, interpretação e limitação. Isso evita transformar uma correlação bonita demais em conclusão apressada.",
  "",
  "## Fonte e qualidade dos dados",
  "",
  paste0("- Observações: ", nrow(data), "."),
  paste0("- Variáveis originais: ", source_ncol, "."),
  paste0("- Produtos distintos por `Productnumber`: ", length(unique(data$Productnumber)), "."),
  paste0("- Provadores: ", length(unique(data$Panellist)), "."),
  paste0("- Réplicas: ", length(unique(data$Replicate)), "."),
  paste0("- Atributos sensoriais minerados: ", length(sensory_vars), "."),
  paste0("- Valores ausentes: ", sum(is.na(data)), "."),
  "",
  "Observação importante: `Productnumber` foi usado como identidade do produto, porque `Productname` não é único. O nome `A-Pr`, por exemplo, aparece em dois produtos diferentes.",
  "",
  "## Padrão 1 - Os produtos têm assinaturas sensoriais próprias",
  "",
  "**Descrição.** A maioria dos atributos sensoriais muda de forma estatisticamente detectável entre produtos.",
  "",
  paste0("**Evidência.** ", significant_anova_count, " de ", length(sensory_vars), " atributos tiveram efeito de produto com `p < 0,05` em ANOVA de um fator. Os maiores tamanhos de efeito foram:"),
  "",
  md_table(top_anova[, c("Variable", "P_value", "Eta_sq", "Lowest_product", "Highest_product")], digits = 3),
  "",
  "**Interpretação.** Há estrutura real nos dados: os produtos não se diferenciam só por ruído de provador. Os atributos com maior eta-quadrado são bons candidatos para descrever posicionamento sensorial, controle de qualidade e comunicação de diferenças entre formulações.",
  "",
  "**Limitação.** Essa primeira ANOVA isola produto, mas não modela provador e sessão ao mesmo tempo. Por isso o Padrão 7 revisita os efeitos de controle.",
  "",
  "## Padrão 2 - Cremoso tende a ser gorduroso/manteigado e pouco farináceo",
  "",
  "**Descrição.** A cremosidade na boca (`MCreaminess`) se associa positivamente com atributos de gordura/manteiga e negativamente com traços farináceos, envelhecidos ou granulados.",
  "",
  "**Evidência.** Correlações mais positivas com `MCreaminess`:",
  "",
  md_table(top_positive_corr[, c("Variable", "Correlation", "P_value")], digits = 3),
  "",
  "Correlações mais negativas com `MCreaminess`:",
  "",
  md_table(top_negative_corr[, c("Variable", "Correlation", "P_value")], digits = 3),
  "",
  paste0("O modelo linear exploratório usou os seis atributos mais correlacionados: `", paste(top_lm_vars, collapse = "`, `"), "`. O R² ajustado foi ", fmt_num(lm_summary$adj.r.squared, 3), "."),
  "",
  "**Interpretação.** Sensorialmente, a cremosidade parece mais próxima de uma experiência cheia, gordurosa e lisa do que de sinais secos/farináceos. O atributo `MChalky` é especialmente útil como alerta: quando ele cresce, a cremosidade percebida tende a cair.",
  "",
  "**Limitação.** Correlação não prova causalidade. Além disso, alguns atributos são naturalmente parecidos entre si; o modelo linear deve ser lido como explicativo, não como fórmula causal.",
  "",
  "## Padrão 3 - Produtos mais e menos cremosos formam um ranking acionável",
  "",
  "**Descrição.** A média por produto mostra quais formulações ocupam o topo e a base da cremosidade percebida.",
  "",
  "**Evidência.** Ranking médio de `MCreaminess`:",
  "",
  md_table(creaminess_rank[, c("Productlabel", target_var, "MFat", "MChalky", "MMeltdown", "MFirm", "MSour")], n = 10, digits = 2),
  "",
  paste0("O maior valor médio de `MCreaminess` foi do produto ", creaminess_rank$Productlabel[1], " (", fmt_num(creaminess_rank[[target_var]][1], 2), "), enquanto o menor foi do produto ", creaminess_rank$Productlabel[nrow(creaminess_rank)], " (", fmt_num(creaminess_rank[[target_var]][nrow(creaminess_rank)], 2), ")."),
  "",
  "**Interpretação.** Esse ranking é o ponto de partida mais direto para decisões de produto: produtos no topo podem servir como referência sensorial; produtos na base indicam candidatos para investigar textura, farinosidade ou equilíbrio ácido.",
  "",
  "**Limitação.** A média resume 24 avaliações por produto. Ela é útil para priorizar, mas não mostra sozinha se a percepção é consensual entre provadores.",
  "",
  "## Padrão 4 - Existem três segmentos sensoriais de produto",
  "",
  "**Descrição.** O k-means sobre médias padronizadas dos 23 atributos separou os produtos em três perfis sensoriais.",
  "",
  paste0("**Evidência.** Silhueta média do agrupamento com 3 clusters: ", fmt_num(avg_silhouette, 3), ". Perfis dos clusters:"),
  "",
  md_table(cluster_profiles, digits = 2),
  "",
  "**Interpretação.** Os clusters condensam a base em grupos comparáveis: produtos dentro do mesmo cluster têm perfil sensorial mais parecido entre si do que com os demais. Isso é útil para escolher benchmarks, planejar reformulações e evitar comparar produtos que pertencem a territórios sensoriais diferentes.",
  "",
  "**Limitação.** Há só 10 produtos, então o cluster deve ser lido como mapa exploratório, não como segmentação definitiva de mercado.",
  "",
  "## Padrão 5 - A PCA revela duas dimensões principais de variação sensorial",
  "",
  "**Descrição.** A PCA aplicada às médias por produto resume grande parte da variação sensorial em poucos eixos.",
  "",
  paste0("**Evidência.** PC1 explica ", fmt_pct(pca_importance[2, 1]), " da variância e PC2 explica ", fmt_pct(pca_importance[2, 2]), ". Juntas, PC1 e PC2 explicam ", fmt_pct(sum(pca_importance[2, 1:2])), "."),
  "",
  "Atributos mais positivos em PC1:",
  "",
  md_table(pc1_top_pos, digits = 3),
  "",
  "Atributos mais negativos em PC1:",
  "",
  md_table(pc1_top_neg, digits = 3),
  "",
  "Atributos mais positivos em PC2:",
  "",
  md_table(pc2_top_pos, digits = 3),
  "",
  "Atributos mais negativos em PC2:",
  "",
  md_table(pc2_top_neg, digits = 3),
  "",
  "**Interpretação.** A PCA ajuda a transformar 23 atributos em uma leitura visual: produtos próximos no gráfico têm perfis parecidos, e os atributos com maiores cargas explicam que tipo de sensação empurra cada produto em uma direção.",
  "",
  "**Limitação.** A PCA foi feita nas médias por produto, então ela representa o mapa dos produtos, não a variabilidade individual de cada provador.",
  "",
  "## Padrão 6 - Regras simples identificam combinações associadas à alta cremosidade",
  "",
  "**Descrição.** Atributos foram discretizados em alto/baixo por quartis para gerar regras interpretáveis de alta cremosidade.",
  "",
  paste0("**Evidência.** A taxa base de alta cremosidade foi ", fmt_pct(base_rate), ". As regras abaixo superaram os filtros mínimos de suporte, confiança e lift:"),
  "",
  md_table(best_rules[, c("Rule", "Antecedent_count", "Hit_count", "Support", "Confidence", "Lift")], digits = 3),
  "",
  "**Interpretação.** Regras com lift acima de 1 indicam situações em que alta cremosidade fica mais provável do que na base total. Elas são úteis porque traduzem mineração de dados em condições legíveis: atributos sensoriais altos/baixos que aumentam a chance de um produto ser percebido como muito cremoso.",
  "",
  "**Limitação.** As regras usam quartis e não devem ser tratadas como limites universais. Elas são boas para triagem e hipótese, não para especificação industrial final.",
  "",
  "## Padrão 7 - Produto continua sendo o sinal mais consistente, mas provador também importa",
  "",
  "**Descrição.** Modelos com produto, provador, réplica, sessão e ordem de serviço ajudam a separar padrão sensorial de artefato experimental.",
  "",
  "**Evidência.** Número de atributos com efeito significativo (`p < 0,05`) em modelo aditivo por atributo:",
  "",
  md_table(control_summary, digits = 0),
  "",
  paste0("Para `MCreaminess`, o p-valor de produto foi ", fmt_p(target_control$Product_p), ", de provador foi ", fmt_p(target_control$Panellist_p), ", de réplica foi ", fmt_p(target_control$Replicate_p), ", de sessão foi ", fmt_p(target_control$Session_p), " e de ordem foi ", fmt_p(target_control$Servingorder_p), "."),
  "",
  "**Interpretação.** O produto explica diferenças importantes, mas a presença de efeito de provador em vários atributos lembra que dados sensoriais carregam estilo individual de avaliação. Portanto, padrões fortes são os que sobrevivem à leitura por produto e fazem sentido no controle por desenho experimental.",
  "",
  "**Limitação.** O modelo trata os efeitos como fixos. Um modelo misto seria mais formal para generalizar provadores, mas exigiria pacote adicional e sairia do requisito de não instalar dependências.",
  "",
  "## Arquivos gerados",
  "",
  "- `cream_cheese_outputs/tables/anova_product_effects.csv`",
  "- `cream_cheese_outputs/tables/product_mean_profiles.csv`",
  "- `cream_cheese_outputs/tables/creaminess_product_ranking.csv`",
  "- `cream_cheese_outputs/tables/creaminess_correlations.csv`",
  "- `cream_cheese_outputs/tables/creaminess_linear_model.csv`",
  "- `cream_cheese_outputs/tables/creaminess_tree_importance.csv`",
  "- `cream_cheese_outputs/tables/pca_product_scores.csv`",
  "- `cream_cheese_outputs/tables/pca_attribute_loadings.csv`",
  "- `cream_cheese_outputs/tables/cluster_assignments.csv`",
  "- `cream_cheese_outputs/tables/cluster_profiles.csv`",
  "- `cream_cheese_outputs/tables/association_rules_high_creaminess.csv`",
  "- `cream_cheese_outputs/tables/control_effects_by_attribute.csv`",
  "- `cream_cheese_outputs/tables/control_effects_summary.csv`",
  "- `cream_cheese_outputs/figures/creaminess_ranking.png`",
  "- `cream_cheese_outputs/figures/creaminess_correlations.png`",
  "- `cream_cheese_outputs/figures/anova_eta_sq.png`",
  "- `cream_cheese_outputs/figures/pca_products.png`",
  "- `cream_cheese_outputs/figures/cluster_dendrogram.png`",
  "- `cream_cheese_outputs/figures/creaminess_tree.png`",
  "",
  "## Reprodutibilidade",
  "",
  "- Comando: `Rscript cream_cheese_mining.R`.",
  "- Semente fixa: `set.seed(20260608)`.",
  "- Pacotes usados: `foreign`, `cluster`, `rpart`, `stats` e base R.",
  "- Nenhum pacote foi instalado para gerar este relatório."
)

con <- file(report_path, open = "wb")
writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
writeBin(charToRaw(paste(enc2utf8(report_lines), collapse = "\n")), con)
writeBin(charToRaw("\n"), con)
close(con)

cat("Analise concluida.\n")
cat("Relatorio: ", report_path, "\n", sep = "")
cat("Saidas: ", out_dir, "\n", sep = "")
