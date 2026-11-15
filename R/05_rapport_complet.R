# ============================================================================
# 05_rapport_complet.R — Rapport de stage complet en Word (officer + flextable
# + mschart), reconstruit à partir de rapport/contenu_*.md.
# Le texte est celui du rapport original (coquilles corrigées) ; les données
# du graphique 2 sont tracées en graphique Word natif (mschart), modifiable
# dans Word (clic droit > Modifier les données).
# ============================================================================

DOSSIER_RAPPORT <- "rapport"
TITRE_RAPPORT <- "Conception d’un outil de diagnostic macroéconomique et de suivi des alertes pour les pays de la CEMAC"
AUTEUR <- "NOUMEN DJOFANG Yvan Rayan"

lire_contenu <- function(fichier) {
  txt <- readLines(file.path(DOSSIER_RAPPORT, fichier), encoding = "UTF-8", warn = FALSE)
  blocs <- strsplit(paste(txt, collapse = "\n"), "\n\\s*\n")[[1]]
  trimws(gsub("\n", " ", blocs))
}
img_rapport <- function(f) file.path(DOSSIER_RAPPORT, "images", f)

# --- Tableaux du rapport -----------------------------------------------------
TABLEAUX <- list(
  "1" = list(
    legende = "Tableau 1 – Référentiel des indicateurs retenus pour le diagnostic",
    source = "Source : Nos travaux, à partir de la note de cadrage remise par M. MVONDO.",
    largeurs = c(4, 7.5, 4),
    df = data.frame(
      Secteur = rep(c("Réel", "Finances publiques", "Monétaire et financier", "Extérieur"), each = 4),
      Indicateur = c("Taux de croissance du PIB réel", "Inflation (IPC)", "Écart de production", "Taux de chômage",
                     "Solde budgétaire global", "Solde primaire", "Recettes fiscales", "Dette publique totale",
                     "Taux directeur", "Croissance de M2/M3", "Crédit au secteur privé", "Créances en souffrance",
                     "Solde du compte courant", "Réserves de change", "Taux de change effectif réel", "Dette extérieure"),
      `Unité usuelle` = c("%", "%", "% du PIB potentiel", "%", "% du PIB", "% du PIB", "% du PIB", "% du PIB",
                          "%", "%", "Variation en %", "% du crédit", "% du PIB", "Mois d’importations", "Indice", "% du PIB"),
      check.names = FALSE),
    fusion = "Secteur"),
  "2" = list(
    legende = "Tableau 2 – Exemple de structure d’un enregistrement importable",
    source = "Source : Nos travaux.", largeurs = c(3.5, 12),
    df = data.frame(Champ = c("Secteur", "Indicateur", "Pays", "Code source", "Date", "Valeur"),
                    `Rôle méthodologique` = c("Regroupe l’indicateur dans le pilier correspondant",
                      "Identifie sans ambiguïté la variable statistique", "Précise l’économie concernée dans la CEMAC",
                      "Préserve le lien avec la nomenclature et la provenance",
                      "Permet le classement chronologique et la concordance des périodes",
                      "Contient la mesure numérique, à contrôler avant publication"), check.names = FALSE)),
  "3" = list(
    legende = "Tableau 3 – Correspondance entre les phases GIMSI et les travaux menés pour PRISME",
    source = "Source : Nos travaux, d’après Fernandez (2013).", largeurs = c(4, 11.5),
    df = data.frame(`Phase GIMSI` = c("Identification", "Conception", "Mise en œuvre", "Amélioration permanente"),
                    `Application au développement de PRISME` = c(
                      "Échanges avec M. MVONDO, analyse du travail à partir de nombreux fichiers Excel et définition des utilisateurs visés.",
                      "Exploitation de la note et de la trame remises, choix des indicateurs, des seuils, des filtres et des principales vues.",
                      "Programmation sous R Shiny, structuration SQLite, implémentation des alertes, des accès et des restitutions.",
                      "Démonstration à l’encadreur, recueil de ses remarques et définition des ajustements nécessaires avant tout déploiement."),
                    check.names = FALSE)),
  "4" = list(
    legende = "Tableau 4 – Synthèse des principales fonctionnalités de PRISME",
    source = "Source : Nos travaux.", largeurs = c(3.6, 6.8, 5.1),
    df = data.frame(Fonctionnalité = c("Diagnostic", "Vue CEMAC et pays", "Alertes", "Données", "Comparaison", "Assistant Iris", "Rapports"),
                    Réalisation = c("Référentiel de 16 indicateurs et fiches de consultation", "Filtres géographiques et consolidation régionale",
                                    "Calcul des statuts et notifications", "Importation, contrôle et validation par lots",
                                    "Sélection de deux ou trois économies", "Interface de dialogue et aide contextuelle",
                                    "Génération de documents PDF et Word"),
                    Utilité = c("Lecture sectorielle", "Synthèse et détail", "Repérage des signaux", "Fiabilisation des saisies",
                                "Lecture comparative", "Accompagnement de l’utilisateur", "Restitution des analyses"))),
  "D1" = list(
    legende = "Tableau D.1 – Extraits des paramètres d’alerte codés dans PRISME",
    source = "Source : Nos travaux.", largeurs = c(5, 4, 6.5),
    df = data.frame(Indicateur = c("Croissance du PIB réel", "Inflation", "Écart de production", "Chômage", "Solde budgétaire",
                                   "Solde primaire", "Recettes fiscales", "Dette publique", "Taux directeur réel", "Croissance de M2/M3",
                                   "Crédit privé", "Créances en souffrance", "Compte courant", "Réserves de change", "TCER", "Dette extérieure"),
                    `Type de règle` = c("Plancher", "Plafond", "Intervalle", "Hausse continue", "Plancher", "Plancher", "Plancher",
                                        "Plafond", "Calcul dérivé", "Référence dynamique", "Variation temporelle", "Plafond", "Plancher",
                                        "Plancher", "Écart à la base", "Plafond"),
                    `Seuil initial indicatif` = c("Inférieur à 2 %", "Supérieur à 3 %", "Hors de [−1 % ; 1 %]", "Trois trimestres de hausse",
                                                  "Inférieur à −3 % du PIB", "Inférieur à 0 % du PIB", "Inférieur à 15 % du PIB",
                                                  "Supérieure à 70 % du PIB", "Taux réel négatif", "Au-delà du PIB nominal + 2 points",
                                                  "Recul supérieur à 5 points", "Supérieures à 5 %", "Inférieur à −5 % du PIB",
                                                  "Moins de 3 mois d’importations", "Appréciation supérieure à 10 %", "Supérieure à 40 % du PIB"),
                    check.names = FALSE))
)

ajouter_tableau <- function(d, id) {
  t <- TABLEAUX[[id]]
  d <- ajouter_legende(d, t$legende, "tableau")
  ft <- ft_charte(t$df, largeurs = t$largeurs)
  if (!is.null(t$fusion)) {
    ft <- flextable::merge_v(ft, j = t$fusion)
    ft <- flextable::bold(ft, j = t$fusion, part = "body")
    ft <- flextable::hline(ft, i = c(4, 8, 12), border = officer::fp_border(color = NAVY, width = 1), part = "body")
  }
  d <- flextable::body_add_flextable(d, ft, align = "center")
  ajouter_source(d, t$source)
}

# --- Figure 1 : chaîne fonctionnelle (schéma Word natif, modifiable) ---------
ajouter_chaine <- function(d) {
  etapes <- c("Sources prévues : fichiers Excel/CSV, saisie et séries publiques autorisées",
              "Contrôles de structure → lot en attente → validation administrative",
              "Base SQLite : observations publiées, utilisateurs, seuils et traces",
              "Moteur de statuts | agrégation CEMAC | indicateurs dérivés",
              "Interfaces Shiny : diagnostic, Kaldor, comparaison, Iris, notifications et rapports")
  lignes <- as.vector(rbind(etapes, "▼"))[-(2 * length(etapes))]
  ft <- flextable::flextable(data.frame(x = lignes))
  ft <- flextable::delete_part(ft, part = "header")
  ft <- flextable::border_remove(ft)
  ft <- flextable::width(ft, width = 11 / 2.54)
  ft <- flextable::align(ft, align = "center", part = "body")
  ft <- flextable::font(ft, fontname = POLICE_TEXTE)
  boites <- seq(1, length(lignes), by = 2); fleches <- seq(2, length(lignes), by = 2)
  ft <- flextable::fontsize(ft, i = boites, size = 9.5)
  ft <- flextable::bg(ft, i = boites, bg = "#EEF2F7")
  ft <- flextable::border(ft, i = boites, border = officer::fp_border(color = NAVY, width = 1))
  ft <- flextable::color(ft, i = fleches, color = NAVY)
  ft <- flextable::fontsize(ft, i = fleches, size = 12)
  ft <- flextable::padding(ft, i = boites, padding = 6)
  ft <- flextable::padding(ft, i = fleches, padding = 0)
  ft <- flextable::set_table_properties(ft, align = "center")
  d <- flextable::body_add_flextable(d, ft, align = "center")
  d <- ajouter_legende(d, "Figure 1 – Chaîne fonctionnelle de PRISME", "figure")
  ajouter_source(d, "Source : Nos travaux.")
}

# --- Graphique 2 : comparaison Cameroun / Centrafrique (mschart) -------------
graphique_comparaison <- function(pays = c("Cameroun", "Centrafrique"), id = "pib_croissance", annees = c(2020, 2025)) {
  i <- ind_info(id)
  df <- do.call(rbind, lapply(pays, function(p) {
    s <- serie(p, id, annees); s <- s[format(s$date, "%m") == "12", ]
    data.frame(annee = as.character(s$annee), valeur = round(s$valeur, 2), serie = p)
  }))
  seuil <- data.frame(annee = unique(df$annee), valeur = i$alerte_1, serie = paste0("Seuil d’alerte (", i$description_seuil, ")"))
  df <- rbind(df, seuil)
  df$serie <- factor(df$serie, levels = c(pays, unique(seuil$serie)))
  cols <- stats::setNames(c(COULEURS_PAYS[seq_along(pays)], ALERTE), levels(df$serie))
  ch <- mschart::ms_linechart(df, x = "annee", y = "valeur", group = "serie")
  ch <- mschart::chart_labels(ch, title = paste(i$nom, "—", paste(pays, collapse = " et ")), xlab = "", ylab = i$unite)
  ch <- mschart::chart_data_stroke(ch, values = cols)
  ch <- mschart::chart_data_fill(ch, values = cols)
  ch <- mschart::chart_data_line_width(ch, values = stats::setNames(c(rep(2.25, length(pays)), 1.25), levels(df$serie)))
  ch <- mschart::chart_data_line_style(ch, values = stats::setNames(c(rep("solid", length(pays)), "dashed"), levels(df$serie)))
  ch <- mschart::chart_data_symbol(ch, values = stats::setNames(c(rep("circle", length(pays)), "none"), levels(df$serie)))
  ch <- mschart::chart_data_size(ch, values = stats::setNames(c(rep(6, length(pays)), 2), levels(df$serie)))
  ch <- mschart::chart_data_smooth(ch, values = stats::setNames(rep(0L, nlevels(df$serie)), levels(df$serie)))
  ch <- mschart::chart_ax_y(ch, num_fmt = "0.0")
  ch <- mschart::chart_ax_x(ch, tick_label_pos = "low")
  theme_mschart(ch)
}

ajouter_image <- function(d, spec) {
  p <- trimws(strsplit(spec, "|", fixed = TRUE)[[1]])
  f <- img_rapport(p[1]); larg <- if (length(p) >= 4) as.numeric(p[4]) else 15
  dim <- if (grepl("\\.png$", f)) dim(png::readPNG(f))[1:2] else dim(jpeg::readJPEG(f))[1:2]
  haut <- larg * dim[1] / dim[2]
  if (haut > 19.5) { larg <- larg * 19.5 / haut; haut <- 19.5 }
  d <- officer::body_add_img(d, f, width = larg / 2.54, height = haut / 2.54, style = "Centré")
  type <- if (startsWith(p[2], "Graphique")) "graphique" else "figure"
  d <- ajouter_legende(d, p[2], type)
  ajouter_source(d, p[3])
}

ajouter_equation <- function(d, spec) {
  p <- trimws(strsplit(spec, "|", fixed = TRUE)[[1]])
  lignes <- trimws(strsplit(p[1], ";", fixed = TRUE)[[1]])
  for (k in seq_along(lignes)) {
    runs <- runs_balises(lignes[k], officer::fp_text_lite(italic = TRUE))
    if (k == length(lignes) && length(p) > 1) runs <- c(runs, list(officer::ftext(paste0("  ", p[2]), officer::fp_text_lite(italic = FALSE))))
    d <- officer::body_add_fpar(d, do.call(officer::fpar, runs), style = "Équation")
  }
  d
}

# --- Moteur de rendu des fichiers de contenu ----------------------------------
rendre_contenu <- function(d, blocs, puce = "—", premier = TRUE) {
  for (b in blocs) {
    if (!nzchar(b)) next
    if (grepl("^#\\*? ", b)) {
      if (!premier) d <- officer::body_add_break(d)
      premier <- FALSE
      d <- officer::body_add_par(d, sub("^#\\*? ", "", b), style = "heading 1")
    } else if (startsWith(b, "### ")) d <- officer::body_add_par(d, sub("^### ", "", b), style = "heading 3")
    else if (startsWith(b, "## ")) d <- officer::body_add_par(d, sub("^## ", "", b), style = "heading 2")
    else if (startsWith(b, "- ")) d <- ajouter_par(d, paste0(puce, " ", sub("^- ", "", b)), style = "Puce")
    else if (startsWith(b, "!tableau ")) d <- ajouter_tableau(d, sub("^!tableau ", "", b))
    else if (b == "!figure chaine") d <- ajouter_chaine(d)
    else if (b == "!graphique comparaison") {
      d <- mschart::body_add_chart(d, graphique_comparaison(), width = 6.2, height = 3.4, style = "Centré")
      d <- ajouter_legende(d, "Graphique 2 – Comparaison de la croissance du PIB réel entre deux pays de la CEMAC", "graphique")
      d <- ajouter_source(d, "Source : Nos travaux (données fictives de démonstration de PRISME).")
    }
    else if (startsWith(b, "!image ")) d <- ajouter_image(d, sub("^!image ", "", b))
    else if (startsWith(b, "!equation ")) d <- ajouter_equation(d, sub("^!equation ", "", b))
    else if (startsWith(b, "!biblio ")) {
      d <- officer::body_add_fpar(d, do.call(officer::fpar, c(runs_balises(sub("^!biblio ", "", b)),
             list(fp_p = officer::fp_par(padding.left = 18, padding.bottom = 6, text.align = "left")))))
    }
    else if (startsWith(b, "!dedicace ")) {
      d <- officer::body_add_par(d, "", style = "Normal")
      for (k in 1:8) d <- officer::body_add_par(d, "", style = "Normal")
      for (l in trimws(strsplit(sub("^!dedicace ", "", b), "||", fixed = TRUE)[[1]]))
        d <- officer::body_add_fpar(d, officer::fpar(officer::ftext(l, officer::fp_text_lite(italic = TRUE, font.size = 13)),
                                                     fp_p = officer::fp_par(text.align = "center")))
    }
    else if (startsWith(b, "!sigles ")) {
      lignes <- strsplit(strsplit(sub("^!sigles ", "", b), ";;", fixed = TRUE)[[1]], "|", fixed = TRUE)
      df <- data.frame(Sigle = trimws(sapply(lignes, `[`, 1)), Signification = trimws(sapply(lignes, `[`, 2)))
      d <- flextable::body_add_flextable(d, flextable::bold(ft_charte(df, largeurs = c(3, 12.5)), j = 1, part = "body"))
    }
    else d <- ajouter_par(d, b)
  }
  d
}

# --- En-têtes, pieds de page, sections ---------------------------------------
pied <- function() {
  officer::block_list(officer::fpar(
    officer::ftext(paste0("© ", AUTEUR), officer::fp_text_lite(font.size = 8.5, color = NEUTRE)),
    officer::ftext("\tAnalyste Statisticien – 3e année\t", officer::fp_text_lite(font.size = 8.5, italic = TRUE, color = NEUTRE)),
    officer::run_word_field("PAGE", prop = officer::fp_text_lite(font.size = 9, bold = TRUE, color = NAVY)),
    fp_p = officer::fp_par(text.align = "left", border.top = officer::fp_border(color = NAVY, width = 0.75),
                           tabs = officer::fp_tabs(officer::fp_tab(8.3 / 2.54, "center"), officer::fp_tab(16.6 / 2.54, "right")))))
}
entete <- function() {
  officer::block_list(officer::fpar(officer::ftext(TITRE_RAPPORT, officer::fp_text_lite(font.size = 8.5, italic = TRUE, color = NAVY)),
                                    fp_p = officer::fp_par(text.align = "center", border.bottom = officer::fp_border(color = GOLD, width = 0.75))))
}
section <- function(avec_entete = TRUE) {
  officer::prop_section(page_size = officer::page_size(orient = "portrait", width = 21 / 2.54, height = 29.7 / 2.54),
                        page_margins = officer::page_mar(top = 2.2 / 2.54, bottom = 2 / 2.54, left = 2.2 / 2.54, right = 2.2 / 2.54,
                                                         header = 1 / 2.54, footer = 1 / 2.54),
                        type = "nextPage",
                        header_default = if (avec_entete) entete(), footer_default = if (avec_entete) pied())
}

# --- Page de garde ------------------------------------------------------------
ajouter_page_garde <- function(d) {
  bloc <- function(lignes) paste(lignes, collapse = "\n")
  df <- data.frame(
    issea = c("", bloc(c("Communauté Économique et Monétaire de l’Afrique Centrale (CEMAC)", "",
                         "Institut Sous-régional de Statistique et d’Économie Appliquée (ISSEA)", "Organisation internationale", "",
                         "B.P. 294, Yaoundé (Cameroun)", "Tél. : (+237) 222 22 01 34", "Fax : (+237) 222 22 95 21",
                         "Courriel : isseacemac@yahoo.fr", "Site web : https://www.issea-cemac.org"))),
    beac = c("", bloc(c("Communauté Économique et Monétaire de l’Afrique Centrale (CEMAC)", "",
                        "Banque des États de l’Afrique Centrale (BEAC)", "Services Centraux", "",
                        "B.P. 1917, Yaoundé (Cameroun)", "Tél. : (+237) 222 23 40 60", "Fax : (+237) 222 23 33 29",
                        "Courriel : beac@beac.int", "Site web : https://www.beac.int"))))
  ft <- flextable::flextable(df)
  ft <- flextable::delete_part(ft, part = "header")
  ft <- flextable::compose(ft, i = 1, j = 1, value = flextable::as_paragraph(flextable::as_image(img_rapport("logo_issea.png"), width = 0.75, height = 0.82)))
  ft <- flextable::compose(ft, i = 1, j = 2, value = flextable::as_paragraph(flextable::as_image(img_rapport("logo_beac.png"), width = 1.5, height = 0.68)))
  ft <- flextable::align(ft, align = "center", part = "all")
  ft <- flextable::font(ft, fontname = POLICE_TEXTE); ft <- flextable::fontsize(ft, size = 8.5)
  ft <- flextable::border_remove(ft)
  ft <- flextable::border_outer(ft, border = officer::fp_border(color = NAVY, width = 1.5))
  ft <- flextable::border_inner_v(ft, border = officer::fp_border(color = NAVY, width = 1.5))
  ft <- flextable::width(ft, width = 7.6 / 2.54)
  ft <- flextable::set_table_properties(ft, align = "center")
  d <- flextable::body_add_flextable(d, ft, align = "center")
  c_ <- function(txt, ...) officer::fpar(officer::ftext(txt, officer::fp_text_lite(...)), fp_p = officer::fp_par(text.align = "center", padding.top = 4))
  d <- officer::body_add_par(d, "")
  d <- officer::body_add_fpar(d, c_("RAPPORT DE STAGE ACADÉMIQUE", font.size = 15, color = NAVY))
  d <- officer::body_add_fpar(d, c_("DE TROISIÈME ANNÉE – FILIÈRE ANALYSTE STATISTICIEN", font.size = 11, bold = TRUE))
  d <- officer::body_add_fpar(d, officer::fpar(officer::ftext(toupper(TITRE_RAPPORT), officer::fp_text_lite(font.size = 16, bold = TRUE, color = NAVY)),
         fp_p = officer::fp_par(text.align = "center", padding = 10, border = officer::fp_border(color = GOLD, width = 1.5))))
  d <- officer::body_add_par(d, "")
  d <- officer::body_add_fpar(d, par_balise("Stage effectué du **3 août au 25 septembre 2026**", officer::fp_text_lite(italic = TRUE),
                                                    officer::fp_par(text.align = "center", padding.top = 4)))
  d <- officer::body_add_fpar(d, c_("à la Direction des Études, de la Recherche, des Statistiques et des Relations Internationales (DERSRI), aux Services Centraux de la BEAC.", italic = TRUE, font.size = 10))
  d <- officer::body_add_par(d, "")
  d <- officer::body_add_fpar(d, c_("Rédigé par :", font.size = 10))
  d <- officer::body_add_fpar(d, c_(AUTEUR, font.size = 14, bold = TRUE, color = NAVY))
  d <- officer::body_add_fpar(d, c_("Élève Analyste Statisticien, troisième année", font.size = 10))
  d <- officer::body_add_par(d, "")
  d <- officer::body_add_fpar(d, c_("Sous l’encadrement professionnel de :", font.size = 10))
  d <- officer::body_add_fpar(d, c_("M. Emile Thierry MVONDO", font.size = 12, bold = TRUE, color = NAVY))
  d <- officer::body_add_fpar(d, c_("Premier adjoint au directeur de la DERSRI", font.size = 10))
  d <- officer::body_add_par(d, "")
  officer::body_add_fpar(d, c_("Octobre 2026", font.size = 11, bold = TRUE, color = NAVY))
}

#' Construit le rapport complet et l'écrit dans `fichier`.
generer_rapport_complet <- function(fichier) {
  d <- doc_base()
  d <- ajouter_page_garde(d)
  d <- officer::body_end_block_section(d, officer::block_section(section(FALSE)))

  pre <- lire_contenu("contenu_preliminaires.md")
  i_sigles <- which(pre == "#* Sigles et abréviations")
  i_avant  <- which(pre == "#* Avant-propos")
  d <- rendre_contenu(d, pre[seq_len(i_sigles - 1)], puce = "•")
  d <- officer::body_add_break(d)
  d <- officer::body_add_par(d, "Sommaire", style = "Titre hors sommaire")
  d <- officer::body_add_toc(d, level = 1)
  d <- rendre_contenu(d, pre[i_sigles:(i_avant - 1)], premier = FALSE)
  for (l in list(c("Liste des tableaux", "Légende tableau"), c("Table des figures", "Légende figure"),
                 c("Liste des graphiques", "Légende graphique"))) {
    d <- officer::body_add_break(d)
    d <- officer::body_add_par(d, l[1], style = "Titre hors sommaire")
    d <- officer::body_add_toc(d, style = l[2])
  }
  d <- rendre_contenu(d, pre[i_avant:length(pre)], premier = FALSE)
  d <- officer::body_end_block_section(d, officer::block_section(section()))

  corps <- lire_contenu("contenu_corps.md")
  ann <- lire_contenu("contenu_annexes.md")
  i_annexe <- which(startsWith(ann, "#* Annexe A"))
  d <- rendre_contenu(d, corps)
  d <- rendre_contenu(d, ann[seq_len(i_annexe - 1)], premier = FALSE)       # bibliographie
  d <- officer::body_end_block_section(d, officer::block_section(section()))

  d <- rendre_contenu(d, ann[i_annexe:length(ann)])
  d <- officer::body_add_break(d)
  d <- officer::body_add_par(d, "Table des matières", style = "Titre hors sommaire")
  d <- officer::body_add_toc(d, level = 3)
  d <- officer::body_set_default_section(d, section())
  print(d, target = fichier)
  # page de garde : sans numéro ; préliminaires : i, ii… ; corps : 1, 2… ; annexes : I, II…
  finaliser_docx(fichier, formats = c(NA, "lowerRoman", "decimal", "upperRoman"))
  invisible(fichier)
}
