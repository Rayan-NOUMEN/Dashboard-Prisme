# ============================================================================
# 00_theme.R — Charte graphique commune (dashboard ET documents Word)
# Source unique des couleurs : ne jamais coder une couleur ailleurs.
# Même logique que PRISME : bleu marine BEAC pour la structure, doré pour la
# marque, vert / orange / rouge réservés aux statuts (jamais décoratifs).
# ============================================================================

NAVY      <- "#0B2545"
GOLD      <- "#C2A712"
SAIN      <- "#2E7D5B"
VIGILANCE <- "#D98E04"
ALERTE    <- "#B23A3A"
NEUTRE    <- "#8A94A3"
FOND      <- "#F4F6F9"
TEXTE     <- "#1B2A41"

COULEURS_STATUT <- c(Sain = SAIN, Vigilance = VIGILANCE, Alerte = ALERTE, "n.d." = NEUTRE)

# Séries comparées (pays) : teintes neutres, distinctes des couleurs de statut.
COULEURS_PAYS <- c("#3E7CB1", "#7B5EA7", "#2A8C99")

PAYS_CEMAC    <- c("Cameroun", "Centrafrique", "Congo", "Gabon", "Guinée Équatoriale", "Tchad")
VUE_REGIONALE <- "CEMAC"
PILIERS       <- c("Réel", "Finances publiques", "Monétaire", "Extérieur")

couleur_statut <- function(s) {
  s <- ifelse(is.na(s) | !s %in% names(COULEURS_STATUT), "n.d.", s)
  unname(COULEURS_STATUT[s])
}
