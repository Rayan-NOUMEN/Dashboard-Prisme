# ============================================================================
# 04_word_commun.R — Briques communes aux documents Word (officer)
# Styles, texte enrichi (**gras**, *italique*, _{indice}, ^{exposant}),
# légendes, sources, tableaux flextable et graphiques mschart à la charte.
# ============================================================================

POLICE_TEXTE <- "Cambria"
POLICE_TITRE <- "Cambria"

#' Document vierge avec les styles du rapport.
doc_base <- function() {
  d <- officer::read_docx()
  pp <- officer::fp_par
  tx <- function(...) officer::fp_text_lite(font.family = POLICE_TEXTE, ...)
  d <- officer::docx_set_paragraph_style(d, style_id = "Normal", style_name = "Normal",
         fp_p = pp(text.align = "justify", line_spacing = 1.25, padding.bottom = 6),
         fp_t = officer::fp_text_lite(font.family = POLICE_TEXTE, font.size = 11, color = TEXTE))
  d <- officer::docx_set_paragraph_style(d, style_id = "Titre1", style_name = "heading 1",
         fp_p = pp(text.align = "left", padding.top = 0, padding.bottom = 14, keep_with_next = TRUE),
         fp_t = tx(font.size = 18, bold = TRUE, color = NAVY))
  d <- officer::docx_set_paragraph_style(d, style_id = "Titre2", style_name = "heading 2",
         fp_p = pp(text.align = "left", padding.top = 12, padding.bottom = 6, keep_with_next = TRUE),
         fp_t = tx(font.size = 14, bold = TRUE, color = NAVY))
  d <- officer::docx_set_paragraph_style(d, style_id = "Titre3", style_name = "heading 3",
         fp_p = pp(text.align = "left", padding.top = 8, padding.bottom = 4, keep_with_next = TRUE),
         fp_t = tx(font.size = 12, bold = TRUE, italic = TRUE, color = NAVY))
  # Titres non numérotés hors sommaire (page de garde, sommaires eux-mêmes).
  d <- officer::docx_set_paragraph_style(d, style_id = "TitreHorsToc", style_name = "Titre hors sommaire",
         fp_p = pp(text.align = "left", padding.bottom = 14), fp_t = tx(font.size = 18, bold = TRUE, color = NAVY))
  for (s in c("Légende tableau", "Légende figure", "Légende graphique")) {
    d <- officer::docx_set_paragraph_style(d, style_id = gsub("[^A-Za-z]", "", s), style_name = s,
           fp_p = pp(text.align = "center", padding.top = 6, padding.bottom = 2, keep_with_next = s == "Légende tableau"),
           fp_t = tx(font.size = 10, bold = TRUE, color = NAVY))
  }
  d <- officer::docx_set_paragraph_style(d, style_id = "Source", style_name = "Source",
         fp_p = pp(text.align = "center", padding.bottom = 10), fp_t = tx(font.size = 9, italic = TRUE, color = NEUTRE))
  d <- officer::docx_set_paragraph_style(d, style_id = "Puce", style_name = "Puce",
         fp_p = pp(text.align = "justify", padding.left = 18, padding.bottom = 3, line_spacing = 1.2))
  d <- officer::docx_set_paragraph_style(d, style_id = "Equation", style_name = "Équation",
         fp_p = pp(text.align = "center", padding.top = 4, padding.bottom = 8),
         fp_t = tx(font.size = 11, italic = TRUE))
  d <- officer::docx_set_paragraph_style(d, style_id = "Centre", style_name = "Centré",
         fp_p = pp(text.align = "center"))
  d
}

#' Texte balisé -> liste de runs ftext (gras, italique, indice, exposant).
runs_balises <- function(txt, base = officer::fp_text_lite()) {
  motif <- "(\\*\\*[^*]+\\*\\*|\\*[^*]+\\*|_\\{[^}]*\\}|\\^\\{[^}]*\\})"
  morceaux <- regmatches(txt, gregexpr(motif, txt, perl = TRUE))[[1]]
  autres   <- regmatches(txt, gregexpr(motif, txt, perl = TRUE), invert = TRUE)[[1]]
  runs <- list()
  for (k in seq_along(autres)) {
    if (nzchar(autres[k])) runs[[length(runs) + 1]] <- officer::ftext(autres[k], base)
    if (k <= length(morceaux)) {
      m <- morceaux[k]
      runs[[length(runs) + 1]] <- if (startsWith(m, "**")) officer::ftext(gsub("^\\*\\*|\\*\\*$", "", m), update(base, bold = TRUE))
        else if (startsWith(m, "*")) officer::ftext(gsub("^\\*|\\*$", "", m), update(base, italic = TRUE))
        else if (startsWith(m, "_")) officer::ftext(gsub("^_\\{|\\}$", "", m), update(base, vertical.align = "subscript"))
        else officer::ftext(gsub("^\\^\\{|\\}$", "", m), update(base, vertical.align = "superscript"))
    }
  }
  runs
}
par_balise <- function(txt, base = officer::fp_text_lite(), fp_p = officer::fp_par_lite()) {
  do.call(officer::fpar, c(runs_balises(txt, base), list(fp_p = fp_p)))
}

ajouter_par <- function(d, txt, style = "Normal") officer::body_add_fpar(d, par_balise(txt), style = style)
ajouter_legende <- function(d, txt, type = c("tableau", "figure", "graphique")) {
  type <- match.arg(type)
  officer::body_add_par(d, txt, style = c(tableau = "Légende tableau", figure = "Légende figure", graphique = "Légende graphique")[[type]])
}
ajouter_source <- function(d, txt) officer::body_add_par(d, txt, style = "Source")

#' Mise en forme standard d'un tableau (en-tête bleu marine, filets fins).
ft_charte <- function(df, largeurs = NULL, taille = 9.5) {
  ft <- flextable::flextable(df)
  ft <- flextable::font(ft, fontname = POLICE_TEXTE, part = "all")
  ft <- flextable::fontsize(ft, size = taille, part = "all")
  ft <- flextable::bg(ft, bg = NAVY, part = "header")
  ft <- flextable::color(ft, color = "white", part = "header")
  ft <- flextable::bold(ft, part = "header")
  ft <- flextable::border_remove(ft)
  ft <- flextable::hline(ft, border = officer::fp_border(color = "#C9D1DC", width = 0.75), part = "body")
  ft <- flextable::hline_bottom(ft, border = officer::fp_border(color = NAVY, width = 1.25), part = "body")
  ft <- flextable::valign(ft, valign = "center", part = "all")
  ft <- flextable::padding(ft, padding = 4, part = "all")
  if (!is.null(largeurs)) ft <- flextable::width(ft, width = largeurs / 2.54) else ft <- flextable::autofit(ft)
  flextable::set_table_properties(ft, align = "center")
}

#' Colore une colonne « Statut » selon le statut (texte blanc sur couleur).
ft_colorer_statut <- function(ft, df, col = "Statut") {
  for (s in names(COULEURS_STATUT)) {
    i <- which(df[[col]] == s)
    if (length(i)) {
      ft <- flextable::bg(ft, i = i, j = col, bg = COULEURS_STATUT[[s]])
      ft <- flextable::color(ft, i = i, j = col, color = "white")
      ft <- flextable::bold(ft, i = i, j = col)
    }
  }
  ft
}

#' Thème mschart commun.
theme_mschart <- function(ch) {
  mschart::set_theme(ch, mschart::mschart_theme(
    main_title = officer::fp_text(font.family = POLICE_TEXTE, font.size = 12, bold = TRUE, color = NAVY),
    axis_title = officer::fp_text(font.family = POLICE_TEXTE, font.size = 9, color = TEXTE),
    axis_text  = officer::fp_text(font.family = POLICE_TEXTE, font.size = 8, color = TEXTE),
    legend_text = officer::fp_text(font.family = POLICE_TEXTE, font.size = 9, color = TEXTE),
    grid_major_line_y = officer::fp_border(color = "#E3E7ED", width = 0.75),
    grid_major_line_x = officer::fp_border(width = 0),
    legend_position = "b"))
}

#' Active la mise à jour des champs à l'ouverture (sommaires remplis
#' automatiquement par Word) et numérote les pages par section.
#' formats : un format par section dans l'ordre (NA = pas de numéro imposé).
finaliser_docx <- function(chemin, formats = NULL) {
  tmp <- tempfile("docx_"); dir.create(tmp)
  utils::unzip(chemin, exdir = tmp)
  reglages <- file.path(tmp, "word", "settings.xml")
  s <- xml2::read_xml(reglages)
  ns <- xml2::xml_ns(s)
  if (!length(xml2::xml_find_all(s, ".//w:updateFields", ns))) {
    xml2::xml_add_child(s, "w:updateFields", "w:val" = "true", .where = 0)
  }
  xml2::write_xml(s, reglages)
  # Interligne : sans w:lineRule, LibreOffice applique une hauteur EXACTE (texte
  # tronqué, logos coupés) ; Word suppose « auto ». On l'écrit explicitement.
  for (f in file.path(tmp, "word", c("document.xml", "styles.xml"))) {
    x <- readLines(f, warn = FALSE, encoding = "UTF-8")
    x <- gsub('(<w:spacing(?![^>]*lineRule)[^>]*w:line="[0-9]+")', '\\1 w:lineRule="auto"', x, perl = TRUE)
    writeLines(x, f, useBytes = TRUE)
  }
  if (!is.null(formats)) {
    docxml <- file.path(tmp, "word", "document.xml")
    d <- xml2::read_xml(docxml); nsd <- xml2::xml_ns(d)
    sect <- xml2::xml_find_all(d, ".//w:sectPr", nsd)
    for (k in seq_along(sect)) {
      f <- formats[min(k, length(formats))]
      if (is.na(f)) next
      old <- xml2::xml_find_all(sect[[k]], "w:pgNumType", nsd); xml2::xml_remove(old)
      noeud <- xml2::xml_add_child(sect[[k]], "w:pgNumType")
      xml2::xml_set_attr(noeud, "w:fmt", f); xml2::xml_set_attr(noeud, "w:start", "1")
    }
    xml2::write_xml(d, docxml)
  }
  fichiers <- list.files(tmp, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  chemin <- normalizePath(chemin, mustWork = TRUE)
  unlink(chemin)
  zip::zip(chemin, files = fichiers, root = tmp)
  unlink(tmp, recursive = TRUE)
  invisible(chemin)
}
