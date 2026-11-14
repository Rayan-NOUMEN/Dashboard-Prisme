# =============================================================================
# exports.R — Génération de la synthèse Word / PowerPoint
#   officer   : construction des documents .docx et .pptx
#   flextable : tableaux mis en forme (couleurs de statut)
#   mschart   : graphiques NATIFS Office (modifiables dans Word / PowerPoint)
#   ggplot2   : carré de Kaldor (radar non disponible dans mschart)
# =============================================================================

suppressPackageStartupMessages({
  library(officer)
  library(flextable)
  library(mschart)
  library(ggplot2)
})

AVERTISSEMENT <- paste(
  "Données FICTIVES générées pour la démonstration du prototype PRISME.",
  "Elles ne décrivent pas la situation réelle des pays de la CEMAC et les seuils",
  "utilisés sont des paramètres indicatifs, non homologués par la BEAC.")

# ---- Tableau des statuts (flextable) -----------------------------------------
ft_statuts <- function(base, perimetres, indicateurs, date_sel) {
  d <- base %>%
    filter(pays %in% perimetres, id %in% indicateurs, date == date_sel) %>%
    mutate(ordre = match(id, referentiel$id)) %>% arrange(ordre, pays) %>%
    mutate(cellule = paste0(formatC(valeur, format = "f", digits = 1, decimal.mark = ","))) %>%
    select(Secteur = secteur, Indicateur = indicateur, Unité = unite, pays, cellule, statut)

  val <- d %>% select(-statut) %>% pivot_wider(names_from = pays, values_from = cellule)
  sta <- d %>% select(Indicateur, pays, statut) %>%
    pivot_wider(names_from = pays, values_from = statut)
  cols_pays <- setdiff(names(val), c("Secteur", "Indicateur", "Unité"))

  ft <- flextable(val) %>%
    merge_v(j = "Secteur") %>%
    theme_vanilla() %>%
    fontsize(size = 9, part = "all") %>%
    bold(part = "header") %>%
    bg(part = "header", bg = pal$navy) %>% color(part = "header", color = "white") %>%
    align(j = cols_pays, align = "center", part = "all") %>%
    valign(j = "Secteur", valign = "top")

  for (p in cols_pays) {
    s <- as.character(sta[[p]])
    ft <- bg(ft, j = p, bg = unname(couleurs_statut[s]))
    ft <- color(ft, j = p, color = ifelse(s == "Vigilance", "black", "white"))
    ft <- bold(ft, j = p)
  }
  ft %>%
    add_footer_lines(paste0("Couleurs : vert = Sain, ambre = Vigilance, rouge = Alerte. ",
                            "Trimestre : ", libelle_trim(date_sel), ". Données fictives.")) %>%
    fontsize(part = "footer", size = 8) %>% italic(part = "footer") %>%
    autofit()
}

# ---- Graphiques natifs mschart ------------------------------------------------
theme_ms <- function(ch) {
  ch %>%
    chart_theme(main_title = fp_text(font.size = 13, bold = TRUE, color = pal$navy),
                axis_title_x = fp_text(font.size = 10, color = pal$gris),
                axis_title_y = fp_text(font.size = 10, color = pal$gris),
                axis_text_x = fp_text(font.size = 9), axis_text_y = fp_text(font.size = 9),
                grid_major_line_y = fp_border(width = 0.5, color = "#D9DEE5"),
                grid_major_line_x = fp_border(style = "none"),
                legend_position = "b")
}

palette_pays <- c(CEMAC = "#0B2545", Cameroun = "#1F77B4", Centrafrique = "#8C564B",
                  Congo = "#2CA02C", Gabon = "#D4A017", `Guinée équatoriale` = "#9467BD",
                  Tchad = "#D62728")

ms_evolution <- function(base, perimetres, ind) {
  ref <- referentiel %>% filter(id == ind)
  d <- base %>% filter(pays %in% perimetres, id == ind) %>%
    transmute(date, pays = as.character(pays), valeur)
  cols <- palette_pays[unique(d$pays)]
  ms_linechart(d, x = "date", y = "valeur", group = "pays") %>%
    chart_settings(style = "line") %>%
    chart_data_stroke(values = cols) %>%
    chart_data_size(values = setNames(rep(2.25, length(cols)), names(cols))) %>%
    chart_data_symbol(values = setNames(rep("none", length(cols)), names(cols))) %>%
    chart_ax_x(num_fmt = "yyyy", major_tick_mark = "out") %>%
    chart_labels(title = paste0(ref$indicateur, " — évolution trimestrielle"),
                 xlab = "", ylab = ref$unite) %>%
    theme_ms()
}

ms_dernieres_valeurs <- function(base, perimetres, ind, date_sel) {
  ref <- referentiel %>% filter(id == ind)
  d <- base %>% filter(pays %in% perimetres, id == ind, date == date_sel) %>%
    transmute(pays = as.character(pays), valeur, statut = as.character(statut))
  ms_barchart(d, x = "pays", y = "valeur", group = "statut") %>%
    chart_settings(dir = "horizontal", grouping = "clustered", overlap = 100, gap_width = 60) %>%
    chart_data_fill(values = couleurs_statut[unique(d$statut)]) %>%
    chart_data_stroke(values = couleurs_statut[unique(d$statut)]) %>%
    chart_labels(title = paste0(ref$indicateur, " — ", libelle_trim(date_sel),
                                " (seuil : ", ref$libelle_seuil, ")"),
                 xlab = "", ylab = ref$unite) %>%
    theme_ms()
}

# ---- Carré de Kaldor (ggplot2) --------------------------------------------------
gg_kaldor <- function(base, perimetre, date_sel, taille_texte = 3.6) {
  k <- kaldor_coords(kaldor_scores(base, perimetre, date_sel))
  grille <- expand.grid(r = c(.25, .5, .75, 1), a = k$angle) %>%
    mutate(x = r * cos(a), y = r * sin(a))
  ggplot() +
    geom_polygon(data = grille, aes(x, y, group = r), fill = NA, colour = "#D9DEE5") +
    geom_segment(data = k, aes(x = 0, y = 0, xend = cos(angle), yend = sin(angle)), colour = "#D9DEE5") +
    geom_polygon(data = k, aes(xr, yr), fill = NA, colour = pal$alerte, linetype = "dashed", linewidth = .7) +
    geom_polygon(data = k, aes(x, y), fill = pal$navy, alpha = .25, colour = pal$navy, linewidth = 1) +
    geom_point(data = k, aes(x, y), colour = pal$navy, size = 2.5) +
    geom_text(data = k, aes(xl, yl, label = paste0(axe, "\n",
              formatC(valeur, format = "f", digits = 1, decimal.mark = ","), " ", unite)),
              size = taille_texte, colour = pal$navy, lineheight = .9) +
    coord_equal(xlim = c(-1.5, 1.5), ylim = c(-1.35, 1.35)) +
    labs(title = paste0("Carré de Kaldor — ", perimetre, " — ", libelle_trim(date_sel)),
         caption = "Plein : situation (score 0-1, 1 = favorable). Pointillés rouges : seuils d'alerte. Données fictives.") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", colour = pal$navy, hjust = .5),
          plot.caption = element_text(colour = pal$gris, size = 8, hjust = .5))
}

# ---- Document Word -------------------------------------------------------------
generer_docx <- function(base, perimetres, indicateurs, date_sel, fichier) {
  indicateurs <- head(indicateurs, 6)
  fp_titre <- fp_text(font.size = 20, bold = TRUE, color = pal$navy)
  doc <- read_docx() %>%
    body_add_fpar(fpar(ftext("Synthèse de diagnostic macroéconomique", fp_titre))) %>%
    body_add_par(paste0("Périmètre : ", paste(perimetres, collapse = ", "),
                        "  |  Trimestre de référence : ", libelle_trim(date_sel),
                        "  |  Généré le ", format(Sys.Date(), "%d/%m/%Y")), style = "Normal") %>%
    body_add_fpar(fpar(ftext(AVERTISSEMENT, fp_text(italic = TRUE, color = pal$alerte, font.size = 9)))) %>%
    body_add_par("Tableau des statuts", style = "heading 1") %>%
    body_add_flextable(ft_statuts(base, perimetres, indicateurs, date_sel)) %>%
    body_add_par("Évolution des indicateurs", style = "heading 1") %>%
    body_add_par("Graphiques natifs Word (mschart) : clic droit > Modifier les données pour retrouver les séries.",
                 style = "Normal")
  for (ind in indicateurs) {
    doc <- doc %>% body_add_chart(ms_evolution(base, perimetres, ind), width = 6.3, height = 3.2)
  }
  doc <- doc %>%
    body_add_par("Comparaison au dernier trimestre", style = "heading 1")
  for (ind in indicateurs[1:min(2, length(indicateurs))]) {
    doc <- doc %>% body_add_chart(ms_dernieres_valeurs(base, perimetres, ind, date_sel),
                                  width = 6.3, height = 3)
  }
  doc <- doc %>% body_add_par("Carré de Kaldor", style = "heading 1")
  for (p in head(perimetres, 2)) {
    doc <- doc %>% body_add_gg(gg_kaldor(base, p, date_sel), width = 5.5, height = 5)
  }
  doc %>%
    body_add_par("Source : dashboard DATAVIZ — rapport de stage « PRISME » (BEAC/DERSRI, 2026).",
                 style = "Normal") %>%
    print(target = fichier)
  invisible(fichier)
}

# ---- Présentation PowerPoint ---------------------------------------------------
generer_pptx <- function(base, perimetres, indicateurs, date_sel, fichier) {
  indicateurs <- head(indicateurs, 6)
  lay <- "Title and Content"; ms <- "Office Theme"
  titre_slide <- function(p, t) ph_with(p, value = t, location = ph_location_type(type = "title"))
  zone <- ph_location(left = 0.5, top = 1.4, width = 9, height = 5.6)

  p <- read_pptx() %>%
    add_slide(layout = "Title Slide", master = ms) %>%
    ph_with("Synthèse de diagnostic macroéconomique", location = ph_location_type(type = "ctrTitle")) %>%
    ph_with(paste0(paste(perimetres, collapse = ", "), " — ", libelle_trim(date_sel),
                   "\nDonnées fictives — démonstration PRISME"), location = ph_location_type(type = "subTitle"))

  p <- p %>% add_slide(layout = lay, master = ms) %>% titre_slide("Tableau des statuts") %>%
    ph_with(fit_to_width(ft_statuts(base, perimetres, indicateurs, date_sel), max_width = 9),
            location = ph_location(left = 0.5, top = 1.4))

  for (ind in indicateurs) {
    p <- p %>% add_slide(layout = lay, master = ms) %>%
      titre_slide(referentiel$indicateur[referentiel$id == ind]) %>%
      ph_with(ms_evolution(base, perimetres, ind), location = zone)
  }
  for (ind in indicateurs[1:min(2, length(indicateurs))]) {
    p <- p %>% add_slide(layout = lay, master = ms) %>%
      titre_slide(paste("Comparaison —", libelle_trim(date_sel))) %>%
      ph_with(ms_dernieres_valeurs(base, perimetres, ind, date_sel), location = zone)
  }
  for (pp in head(perimetres, 2)) {
    p <- p %>% add_slide(layout = lay, master = ms) %>% titre_slide(paste("Carré de Kaldor —", pp)) %>%
      ph_with(gg_kaldor(base, pp, date_sel, taille_texte = 3.2),
              location = ph_location(left = 2, top = 1.3, width = 6, height = 5.8))
  }
  print(p, target = fichier)
  invisible(fichier)
}
