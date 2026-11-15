# ============================================================================
# 07_graphiques.R — Graphiques interactifs de la page (plotly)
# Les graphiques Word (mschart) sont dans 05_/06_ : ici, uniquement l'écran.
# ============================================================================

config_plotly <- function(p) {
  p |>
    plotly::config(displaylogo = FALSE, locale = "fr",
                   modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d", "toggleSpikelines")) |>
    plotly::layout(separators = ", ", font = list(family = "Source Sans 3, Segoe UI, Arial", color = TEXTE),
                   paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
                   hoverlabel = list(font = list(size = 13)))
}

texte_survol <- function(s, i) {
  paste0("<b>", formater_mois(s$date), "</b><br>", formater_valeur(s$valeur, i$unite),
         "<br>Statut : <b>", ifelse(is.na(s$statut), "n.d.", s$statut), "</b>",
         ifelse(s$estime, "<br><i>valeur estimée (interpolation)</i>", ""))
}

#' Zones de vigilance / d'alerte en arrière-plan (rectangles horizontaux).
zones_seuil <- function(i, ymin, ymax) {
  z <- list()
  rect <- function(y0, y1, col, op) list(type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = y0, y1 = y1,
                                         fillcolor = col, opacity = op, line = list(width = 0), layer = "below")
  ligne <- function(y, col, dash) list(type = "line", xref = "paper", x0 = 0, x1 = 1, y0 = y, y1 = y,
                                       line = list(color = col, dash = dash, width = 1.5))
  if (is.na(i$alerte_1)) return(z)
  if (i$type_seuil == "plafond") {
    z <- list(rect(i$alerte_1, ymax, ALERTE, 0.09), rect(i$vigilance_1, i$alerte_1, VIGILANCE, 0.12),
              ligne(i$alerte_1, ALERTE, "dash"), ligne(i$vigilance_1, VIGILANCE, "dot"))
  } else if (i$type_seuil == "plancher") {
    z <- list(rect(ymin, i$alerte_1, ALERTE, 0.09), rect(i$alerte_1, i$vigilance_1, VIGILANCE, 0.12),
              ligne(i$alerte_1, ALERTE, "dash"), ligne(i$vigilance_1, VIGILANCE, "dot"))
  } else if (i$type_seuil == "bande") {
    z <- list(rect(ymin, i$alerte_1, ALERTE, 0.09), rect(i$alerte_2, ymax, ALERTE, 0.09),
              ligne(i$alerte_1, ALERTE, "dash"), ligne(i$alerte_2, ALERTE, "dash"))
  }
  z
}

#' Courbe d'un indicateur avec zones de seuil et points colorés par statut.
graphe_indicateur <- function(entite, id, annees) {
  i <- ind_info(id); s <- serie(entite, id, annees); s <- s[!is.na(s$valeur), ]
  validate_ok <- nrow(s) > 0
  if (!validate_ok) return(plotly::plotly_empty() |> plotly::layout(title = "Aucune donnée"))
  bornes <- range(c(s$valeur, i$alerte_1, i$alerte_2, i$vigilance_1), na.rm = TRUE)
  marge <- diff(bornes) * 0.15 + 0.1; ymin <- bornes[1] - marge; ymax <- bornes[2] + marge
  obs <- s[!s$estime, ]
  plotly::plot_ly(s, x = ~date) |>
    plotly::add_lines(y = ~valeur, line = list(color = NAVY, width = 2.5), name = libelle_entite(entite),
                      text = texte_survol(s, i), hoverinfo = "text") |>
    plotly::add_markers(data = obs, y = ~valeur, marker = list(color = couleur_statut(obs$statut), size = 9,
                        line = list(color = "white", width = 1.5)), name = "Valeur observée",
                        text = texte_survol(obs, i), hoverinfo = "text") |>
    plotly::layout(shapes = zones_seuil(i, ymin, ymax), showlegend = FALSE,
                   yaxis = list(title = i$unite, range = c(ymin, ymax), zeroline = FALSE, gridcolor = "#E6EAF0"),
                   xaxis = list(title = "", rangeslider = list(visible = TRUE, thickness = 0.08), gridcolor = "#F0F2F5"),
                   margin = list(l = 60, r = 20, t = 10, b = 10)) |>
    config_plotly()
}

#' Carte de la CEMAC : nombre d'indicateurs en alerte par pays.
graphe_carte <- function(grille) {
  n <- aggregate(statut ~ entite, grille, function(x) sum(x == "Alerte"))
  n$iso3 <- PRISME$pays$iso3[match(n$entite, PRISME$pays$nom)]
  survol <- vapply(n$entite, function(e) {
    g <- grille[grille$entite == e & grille$statut == "Alerte", ]
    paste0("<b>", e, "</b><br>", nrow(g), " indicateur(s) en alerte<br><span style='font-size:11px'>",
           paste(utils::head(g$nom, 6), collapse = "<br>"), if (nrow(g) > 6) "<br>…" else "", "</span>")
  }, character(1))
  plotly::plot_geo(n, source = "carte") |>
    plotly::add_trace(type = "choropleth", locations = ~iso3, z = ~statut, text = survol, hoverinfo = "text",
                      customdata = ~entite, zmin = 0, zmax = 16,
                      colorscale = list(c(0, "#F3E3E3"), c(0.5, "#D46A6A"), c(1, "#7A1F1F")),
                      marker = list(line = list(color = "white", width = 1.2)),
                      colorbar = list(title = list(text = "Alertes"), thickness = 12, len = 0.6)) |>
    plotly::layout(geo = list(scope = "africa", fitbounds = "locations", showframe = FALSE, showcoastlines = FALSE,
                              showcountries = TRUE, countrycolor = "#C9D1DC", showland = TRUE, landcolor = "#EEF1F5",
                              bgcolor = "rgba(0,0,0,0)", projection = list(type = "mercator")),
                   margin = list(l = 0, r = 0, t = 0, b = 0)) |>
    config_plotly()
}

#' Grille des statuts (pays × indicateurs), couleurs discrètes.
graphe_grille <- function(grille) {
  niv <- c("Sain" = 1, "Vigilance" = 2, "Alerte" = 3, "n.d." = 0)
  inds <- IND$nom[order(IND$ordre)]
  pays <- rev(unique(grille$entite))
  z <- matrix(NA, length(pays), length(inds)); txt <- z
  for (k in seq_len(nrow(grille))) {
    r <- match(grille$entite[k], pays); c <- match(grille$nom[k], inds)
    z[r, c] <- niv[[grille$statut[k]]]
    txt[r, c] <- paste0("<b>", grille$entite[k], "</b><br>", grille$nom[k], "<br>Valeur : ",
                        formater_valeur(grille$valeur[k], grille$unite[k]), "<br>Seuil : ", grille$description_seuil[k],
                        "<br>Statut : <b>", grille$statut[k], "</b>")
  }
  etiquettes <- IND$id[order(IND$ordre)]
  courts <- c(pib_croissance = "Croissance", inflation = "Inflation", ecart_production = "Écart prod.", chomage = "Chômage",
              solde_budgetaire = "Solde budg.", solde_primaire = "Solde prim.", recettes_fiscales = "Recettes fisc.",
              dette_publique = "Dette publ.", taux_directeur = "Taux dir.", masse_monetaire = "M2/M3", credit_prive = "Crédit privé",
              creances_souffrance = "Créances douteuses", compte_courant = "Compte courant", reserves_change = "Réserves",
              tcer = "TCER", dette_exterieure = "Dette ext.")
  plotly::plot_ly(x = unname(courts[etiquettes]), y = pays, z = z, type = "heatmap", text = txt, hoverinfo = "text",
                  zmin = 0, zmax = 3, xgap = 3, ygap = 3, showscale = FALSE,
                  colorscale = list(c(0, NEUTRE), c(0.25, NEUTRE), c(0.25, SAIN), c(0.5, SAIN), c(0.5, VIGILANCE),
                                    c(0.75, VIGILANCE), c(0.75, ALERTE), c(1, ALERTE))) |>
    plotly::layout(xaxis = list(tickangle = -40, side = "top", title = ""), yaxis = list(title = ""),
                   margin = list(l = 10, r = 10, t = 10, b = 10),
                   shapes = lapply(c(3.5, 7.5, 11.5), function(x) list(type = "line", x0 = x, x1 = x, y0 = -0.5,
                                    y1 = length(pays) - 0.5, line = list(color = "white", width = 4)))) |>
    config_plotly()
}

#' Carré de Kaldor : un polygone par entité, cercle de référence = limite d'alerte (rayon 50).
graphe_kaldor <- function(entites, annee) {
  k <- PRISME$kaldor[PRISME$kaldor$entite %in% entites & PRISME$kaldor$annee == annee, ]
  axes <- PRISME$kaldor_axes$axe
  p <- plotly::plot_ly(type = "scatterpolar", mode = "lines")
  p <- plotly::add_trace(p, r = rep(50, 5), theta = c(axes, axes[1]), name = "Limite d’alerte",
                         line = list(color = ALERTE, dash = "dash", width = 1.5), hoverinfo = "skip", fill = "none")
  for (j in seq_along(entites)) {
    e <- entites[j]; x <- k[k$entite == e, ]; x <- x[match(axes, x$axe), ]
    r <- ifelse(is.na(x$r), 50, x$r)
    survol <- paste0("<b>", libelle_entite(e), " — ", x$axe, "</b><br>",
                     vapply(seq_len(nrow(x)), function(m) {
                       i <- ind_info(x$indicateur_id[m]); formater_valeur(x$valeur[m], i$unite) }, character(1)),
                     "<br>Statut : ", ifelse(is.na(x$statut), "n.d.", x$statut))
    p <- plotly::add_trace(p, r = c(r, r[1]), theta = c(axes, axes[1]), name = libelle_entite(e), fill = "toself",
                           mode = "lines+markers", line = list(color = COULEURS_PAYS[j], width = 2.5),
                           fillcolor = paste0(COULEURS_PAYS[j], "33"),
                           marker = list(size = 9, color = couleur_statut(x$statut[c(seq_len(nrow(x)), 1)]),
                                         line = list(color = "white", width = 1)),
                           text = c(survol, survol[1]), hoverinfo = "text")
  }
  p |>
    plotly::layout(polar = list(radialaxis = list(range = c(0, 100), showticklabels = FALSE, ticks = "", gridcolor = "#E3E7ED"),
                                angularaxis = list(tickfont = list(size = 14), gridcolor = "#E3E7ED"),
                                bgcolor = "rgba(0,0,0,0)"),
                   legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.08),
                   margin = list(l = 40, r = 40, t = 30, b = 30)) |>
    config_plotly()
}

#' Comparaison de 2-3 pays : courbes + barres de la dernière valeur.
graphe_comparaison <- function(entites, id, annees) {
  i <- ind_info(id)
  p <- plotly::plot_ly()
  for (j in seq_along(entites)) {
    s <- serie(entites[j], id, annees); s <- s[!is.na(s$valeur), ]
    p <- plotly::add_lines(p, data = s, x = ~date, y = ~valeur, name = libelle_entite(entites[j]),
                           line = list(color = COULEURS_PAYS[j], width = 2.5), text = texte_survol(s, i), hoverinfo = "text+name")
  }
  formes <- lapply(stats::na.omit(c(i$alerte_1, i$alerte_2)), function(y) list(type = "line", xref = "paper", x0 = 0, x1 = 1,
                   y0 = y, y1 = y, line = list(color = ALERTE, dash = "dash", width = 1.5)))
  p |> plotly::layout(shapes = formes, yaxis = list(title = i$unite, gridcolor = "#E6EAF0"), xaxis = list(title = ""),
                      legend = list(orientation = "h", y = 1.08), hovermode = "x unified",
                      margin = list(l = 60, r = 20, t = 30, b = 30)) |>
    config_plotly()
}

graphe_barres_derniere <- function(entites, id, annees) {
  i <- ind_info(id); jusqu_a <- min(DERNIERE_DATE, as.Date(sprintf("%d-12-01", annees[2])))
  d <- do.call(rbind, lapply(entites, function(e) { f <- faits_indicateur(e, id, jusqu_a)
    data.frame(entite = libelle_entite(e), valeur = f$valeur, statut = f$statut) }))
  d$entite <- factor(d$entite, levels = rev(d$entite))
  p <- plotly::plot_ly(d, y = ~entite, x = ~valeur, type = "bar", orientation = "h",
                       marker = list(color = rev(COULEURS_PAYS[seq_along(entites)])[as.integer(d$entite)]),
                       text = paste0(formater_valeur(d$valeur, i$unite), " · ", d$statut), textposition = "auto",
                       hoverinfo = "text")
  formes <- lapply(stats::na.omit(c(i$alerte_1, i$alerte_2)), function(x) list(type = "line", yref = "paper", y0 = 0, y1 = 1,
                   x0 = x, x1 = x, line = list(color = ALERTE, dash = "dash", width = 2)))
  p |> plotly::layout(shapes = formes, xaxis = list(title = i$unite, gridcolor = "#E6EAF0"), yaxis = list(title = ""),
                      margin = list(l = 10, r = 20, t = 10, b = 40)) |>
    config_plotly()
}
