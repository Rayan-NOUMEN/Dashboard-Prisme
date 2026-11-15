# ============================================================================
# 06_fiche_word.R — Fiche indicateurs personnalisée (Word)
# Choix de l'utilisateur : périmètre (pays ou CEMAC), piliers, période.
# Contenu : synthèse des statuts, tableau coloré (flextable), un graphique
# Word natif par indicateur (mschart, modifiable dans Word) et son
# commentaire (IA, ou commentaire PRISME en repli).
# ============================================================================

#' Graphique mschart d'un indicateur : série + seuil d'alerte + début de vigilance.
graphique_indicateur <- function(entite, id, annees) {
  i <- ind_info(id)
  s <- serie(entite, id, annees); s <- s[!is.na(s$valeur), ]
  # Points de fin d'année (les séries sources de PRISME sont annuelles ; le mensuel est interpolé)
  s <- s[format(s$date, "%m") == "12" | s$date == max(s$date), ]
  s$date <- ifelse(format(s$date, "%m") == "12", format(s$date, "%Y"), formater_mois(s$date))
  df <- data.frame(date = s$date, valeur = round(s$valeur, 2), serie = libelle_entite(entite))
  cols <- stats::setNames(NAVY, libelle_entite(entite)); styles <- stats::setNames("solid", libelle_entite(entite))
  ajouter_ligne <- function(df, v, nom) rbind(df, data.frame(date = s$date, valeur = v, serie = nom))
  if (!is.na(i$alerte_1)) {
    nom <- "Seuil d’alerte"; df <- ajouter_ligne(df, i$alerte_1, nom)
    cols[nom] <- ALERTE; styles[nom] <- "dashed"
    if (!is.na(i$alerte_2)) { df <- ajouter_ligne(df, i$alerte_2, "Seuil d’alerte (haut)"); cols["Seuil d’alerte (haut)"] <- ALERTE; styles["Seuil d’alerte (haut)"] <- "dashed" }
  }
  if (!is.na(i$vigilance_1) && !isTRUE(all.equal(i$vigilance_1, i$alerte_1))) {
    nom <- "Début de vigilance"; df <- ajouter_ligne(df, i$vigilance_1, nom)
    cols[nom] <- VIGILANCE; styles[nom] <- "dotted"
  }
  df$serie <- factor(df$serie, levels = names(cols))
  ch <- mschart::ms_linechart(df, x = "date", y = "valeur", group = "serie")
  ch <- mschart::chart_data_smooth(ch, values = stats::setNames(rep(0L, length(cols)), names(cols)))
  ch <- mschart::chart_labels(ch, title = i$nom, xlab = NULL, ylab = i$unite)
  ch <- mschart::chart_data_stroke(ch, values = cols)
  ch <- mschart::chart_data_fill(ch, values = cols)
  ch <- mschart::chart_data_line_style(ch, values = styles)
  ch <- mschart::chart_data_line_width(ch, values = stats::setNames(ifelse(names(cols) == libelle_entite(entite), 2, 1), names(cols)))
  ch <- mschart::chart_data_symbol(ch, values = stats::setNames(ifelse(names(cols) == libelle_entite(entite), "circle", "none"), names(cols)))
  ch <- mschart::chart_data_size(ch, values = stats::setNames(ifelse(names(cols) == libelle_entite(entite), 6, 2), names(cols)))
  ch <- mschart::chart_ax_x(ch, tick_label_pos = "low")
  ch <- mschart::chart_ax_y(ch, num_fmt = "0.0")
  theme_mschart(ch)
}

#' Génère la fiche dans `fichier`. progres(valeur, message) : rappel optionnel.
generer_fiche <- function(fichier, entite, piliers = PILIERS, annees = ANNEES, utiliser_ia = TRUE,
                          progres = function(v, m) NULL) {
  ids <- IND$id[IND$secteur %in% piliers]
  jusqu_a <- min(DERNIERE_DATE, as.Date(sprintf("%d-12-01", annees[2])))
  pts <- derniers_points(entite, jusqu_a); pts <- pts[pts$id %in% ids, ]

  d <- doc_base()
  bandeau <- flextable::flextable(data.frame(x = c("PRISME — Fiche indicateurs", libelle_entite(entite))))
  bandeau <- flextable::delete_part(bandeau, part = "header")
  bandeau <- flextable::border_remove(bandeau)
  bandeau <- flextable::bg(bandeau, bg = NAVY)
  bandeau <- flextable::font(bandeau, fontname = POLICE_TEXTE)
  bandeau <- flextable::color(bandeau, i = 1, color = GOLD); bandeau <- flextable::color(bandeau, i = 2, color = "white")
  bandeau <- flextable::fontsize(bandeau, i = 1, size = 11); bandeau <- flextable::fontsize(bandeau, i = 2, size = 24)
  bandeau <- flextable::bold(bandeau); bandeau <- flextable::padding(bandeau, padding.left = 14, padding.top = 6, padding.bottom = 6)
  bandeau <- flextable::width(bandeau, width = 17 / 2.54)
  d <- flextable::body_add_flextable(d, bandeau)
  d <- ajouter_par(d, paste0("**Piliers :** ", paste(piliers, collapse = ", "), "   ·   **Période :** ", annees[1], "–", annees[2],
                             "   ·   **Données jusqu’à :** ", formater_mois(jusqu_a), "   ·   **Édition :** ", format(Sys.Date(), "%d/%m/%Y")))
  d <- ajouter_par(d, "*Données fictives de démonstration issues de PRISME (BEAC). Les seuils sont des paramètres du prototype, non homologués.*")

  # Synthèse : tuiles de comptage
  n <- table(factor(pts$statut, levels = c("Sain", "Vigilance", "Alerte", "n.d.")))
  tuiles <- data.frame(Sain = n[["Sain"]], Vigilance = n[["Vigilance"]], Alerte = n[["Alerte"]])
  ft <- flextable::flextable(tuiles)
  ft <- flextable::font(ft, fontname = POLICE_TEXTE, part = "all")
  ft <- flextable::fontsize(ft, size = 24, part = "body"); ft <- flextable::fontsize(ft, size = 10, part = "header")
  ft <- flextable::bold(ft, part = "all"); ft <- flextable::align(ft, align = "center", part = "all")
  ft <- flextable::color(ft, color = "white", part = "all"); ft <- flextable::border_remove(ft)
  for (s in names(tuiles)) ft <- flextable::bg(ft, j = s, bg = COULEURS_STATUT[[s]], part = "all")
  ft <- flextable::width(ft, width = 5 / 2.54); ft <- flextable::set_table_properties(ft, align = "center")
  d <- officer::body_add_par(d, "Synthèse", style = "heading 2")
  d <- flextable::body_add_flextable(d, ft)
  alertes <- pts$nom[pts$statut == "Alerte"]
  d <- ajouter_par(d, if (length(alertes)) paste0("**Indicateurs en alerte :** ", paste(alertes, collapse = " ; "), ".")
                      else "Aucun indicateur en alerte sur le périmètre retenu.")

  tab <- data.frame(Pilier = pts$secteur, Indicateur = pts$nom, Valeur = formater_valeur(pts$valeur, pts$unite),
                    Date = ifelse(is.na(pts$date), "n.d.", formater_mois(pts$date)), Statut = pts$statut,
                    `Seuil d’alerte` = pts$description_seuil, check.names = FALSE)
  ft <- ft_colorer_statut(ft_charte(tab, largeurs = c(2.6, 4.6, 2.6, 1.9, 1.9, 3.0), taille = 8.5), tab)
  ft <- flextable::merge_v(ft, j = "Pilier")
  d <- ajouter_legende(d, paste("Tableau 1 – Statut des indicateurs —", libelle_entite(entite)), "tableau")
  d <- flextable::body_add_flextable(d, ft)
  d <- ajouter_source(d, "Source : PRISME, données fictives ; statuts calculés selon les seuils du prototype.")

  k <- 0
  for (p in piliers) {
    d <- officer::body_add_break(d)
    d <- officer::body_add_par(d, paste("Pilier", p), style = "heading 1")
    for (id in IND$id[IND$secteur == p]) {
      k <- k + 1
      progres(k / length(ids), paste("Indicateur", k, "sur", length(ids)))
      d <- mschart::body_add_chart(d, graphique_indicateur(entite, id, annees), width = 6.3, height = 2.9, style = "Centré")
      com <- commenter(entite, id, jusqu_a, utiliser_ia)
      d <- ajouter_par(d, com$texte)
      d <- officer::body_add_par(d, paste0(com$source, if (nzchar(com$raison) && !com$ia && utiliser_ia) paste0(" — ", com$raison) else ""),
                                 style = "Source")
    }
  }
  d <- officer::body_set_default_section(d, officer::prop_section(
    page_margins = officer::page_mar(top = 1.8 / 2.54, bottom = 1.8 / 2.54, left = 2 / 2.54, right = 2 / 2.54),
    footer_default = officer::block_list(officer::fpar(
      officer::ftext("PRISME — fiche générée automatiquement · page ", officer::fp_text_lite(font.size = 8, color = NEUTRE)),
      officer::run_word_field("PAGE", prop = officer::fp_text_lite(font.size = 8, color = NEUTRE)),
      fp_p = officer::fp_par(text.align = "right")))))
  print(d, target = fichier)
  finaliser_docx(fichier)
  invisible(fichier)
}
