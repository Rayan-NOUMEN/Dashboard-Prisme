# ============================================================================
# 01_donnees.R — Chargement de l'extrait PRISME et fonctions d'accès
# data/prisme_extrait.rds est produit par tools/extraire_donnees_prisme.R.
# Lecture seule : le dashboard n'écrit jamais dans les données.
# ============================================================================

charger_extrait <- function(chemin = file.path("data", "prisme_extrait.rds")) {
  if (!file.exists(chemin)) stop("Données introuvables : ", chemin, call. = FALSE)
  x <- readRDS(chemin)
  x$series$annee <- as.integer(format(x$series$date, "%Y"))
  x
}

PRISME <- charger_extrait()
IND    <- PRISME$indicateurs                      # 16 indicateurs, ordre des piliers
DERNIERE_DATE <- max(PRISME$series$date)
ANNEES <- range(PRISME$series$annee)

ind_info <- function(id) IND[IND$id == id, , drop = FALSE]
genitif  <- function(entite) PRISME$pays$genitif[PRISME$pays$nom == entite]
libelle_entite <- function(e) ifelse(e == VUE_REGIONALE, "Zone CEMAC", e)
fin_annee <- function(a) min(DERNIERE_DATE, as.Date(sprintf("%d-12-01", as.integer(a))))

#' Série d'un indicateur pour une entité, éventuellement bornée en années.
serie <- function(entite, id, annees = NULL) {
  s <- PRISME$series[PRISME$series$entite == entite & PRISME$series$indicateur_id == id, , drop = FALSE]
  if (!is.null(annees)) s <- s[s$annee >= annees[1] & s$annee <= annees[2], , drop = FALSE]
  s[order(s$date), , drop = FALSE]
}

#' Dernier point (jusqu'à une date limite) de chaque indicateur d'une entité.
derniers_points <- function(entite, jusqu_a = DERNIERE_DATE) {
  s <- PRISME$series[PRISME$series$entite == entite & PRISME$series$date <= jusqu_a & !is.na(PRISME$series$valeur), ]
  s <- s[order(s$indicateur_id, s$date), ]
  d <- do.call(rbind, lapply(split(s, s$indicateur_id), function(x) x[nrow(x), ]))
  d <- merge(IND[, c("id", "secteur", "nom", "unite", "ordre", "description_seuil")], d,
             by.x = "id", by.y = "indicateur_id", all.x = TRUE)
  d$statut[is.na(d$statut)] <- "n.d."
  d[order(d$ordre), ]
}

#' Grille des statuts : une ligne par (entité, indicateur) à la dernière date.
grille_statuts <- function(entites = PAYS_CEMAC, jusqu_a = DERNIERE_DATE) {
  do.call(rbind, lapply(entites, function(e) cbind(entite = e, derniers_points(e, jusqu_a))))
}

# --- Mise en forme française ---------------------------------------------------
formater_nombre <- function(x, digits = 1) {
  ifelse(is.na(x), "n.d.", formatC(x, format = "f", digits = digits, decimal.mark = ",", big.mark = " "))
}
formater_valeur <- function(x, unite, digits = 1) {
  n <- formater_nombre(x, digits); unite <- rep_len(unite, length(x))
  ifelse(is.na(x), "n.d.",
         ifelse(startsWith(unite, "%"), paste0(n, " ", unite),
                ifelse(grepl("^Indice", unite), paste0(n, " (", tolower(unite), ")"), paste(n, tolower(unite)))))
}
MOIS_FR <- c("janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc.")
formater_mois <- function(d) paste(MOIS_FR[as.integer(format(as.Date(d), "%m"))], format(as.Date(d), "%Y"))
