# =============================================================================
# donnees.R — Référentiel des indicateurs, données synthétiques et moteur de statuts
# Dashboard DATAVIZ — Rapport de stage PRISME (BEAC / DERSRI, 2026)
#
# IMPORTANT : toutes les séries générées ici sont FICTIVES (set.seed). Elles
# reproduisent la structure décrite dans le rapport (tableau 2) et servent
# uniquement à illustrer le fonctionnement du diagnostic. Elles ne décrivent
# pas la situation réelle des pays de la CEMAC.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# ---- Palette commune (écran + exports) --------------------------------------
pal <- list(
  navy     = "#0B2545",
  navy2    = "#13315C",
  or       = "#B8860B",
  gris     = "#5F6B7A",
  sain     = "#2E7D32",
  vigilance = "#E0A100",
  alerte   = "#C0392B",
  na       = "#BDC3C7"
)
couleurs_statut <- c(Sain = pal$sain, Vigilance = pal$vigilance,
                     Alerte = pal$alerte, `Non disponible` = pal$na)

couleurs_secteur <- c(`Réel` = "#1F4E79", `Finances publiques` = "#7A4E9C",
                      `Monétaire et financier` = "#0E7C7B", `Extérieur` = "#B5651D")

# ---- Pays et pondérations ----------------------------------------------------
# Poids de consolidation (part indicative du PIB régional) — hypothèse du
# prototype, à remplacer par les poids officiels avant tout usage réel.
pays_cemac <- c("Cameroun", "Centrafrique", "Congo", "Gabon",
                "Guinée équatoriale", "Tchad")
poids_pib <- c(Cameroun = 0.42, Centrafrique = 0.04, Congo = 0.14,
               Gabon = 0.18, `Guinée équatoriale` = 0.11, Tchad = 0.11)

# ---- Référentiel (tableau 1 + annexe D du rapport) --------------------------
referentiel <- tibble::tribble(
  ~id,          ~secteur,                 ~indicateur,                        ~unite,                ~regle,            ~s1,   ~s2,  ~libelle_seuil,
  "pib",        "Réel",                   "Croissance du PIB réel",           "%",                   "plancher",          2,   NA,  "Inférieur à 2 %",
  "inflation",  "Réel",                   "Inflation (IPC)",                  "%",                   "plafond",           3,   NA,  "Supérieur à 3 %",
  "gap",        "Réel",                   "Écart de production",              "% du PIB potentiel",  "intervalle",       -1,    1,  "Hors de [-1 % ; 1 %]",
  "chomage",    "Réel",                   "Taux de chômage",                  "%",                   "hausse_continue",   3,   NA,  "3 trimestres de hausse",
  "solde_glob", "Finances publiques",     "Solde budgétaire global",          "% du PIB",            "plancher",         -3,   NA,  "Inférieur à -3 % du PIB",
  "solde_prim", "Finances publiques",     "Solde primaire",                   "% du PIB",            "plancher",          0,   NA,  "Inférieur à 0 % du PIB",
  "recettes",   "Finances publiques",     "Recettes fiscales",                "% du PIB",            "plancher",         15,   NA,  "Inférieur à 15 % du PIB",
  "dette_pub",  "Finances publiques",     "Dette publique totale",            "% du PIB",            "plafond",          70,   NA,  "Supérieure à 70 % du PIB",
  "taux_dir",   "Monétaire et financier", "Taux directeur",                   "%",                   "taux_reel",         0,   NA,  "Taux réel négatif",
  "m2",         "Monétaire et financier", "Croissance de M2",                 "%",                   "m2_dynamique",      2,   NA,  "Au-delà du PIB nominal + 2 points",
  "credit",     "Monétaire et financier", "Crédit au secteur privé",          "Variation en %",      "plancher",         -5,   NA,  "Recul supérieur à 5 points",
  "creances",   "Monétaire et financier", "Créances en souffrance",           "% du crédit",         "plafond",           5,   NA,  "Supérieures à 5 %",
  "cc",         "Extérieur",              "Solde du compte courant",          "% du PIB",            "plancher",         -5,   NA,  "Inférieur à -5 % du PIB",
  "reserves",   "Extérieur",              "Réserves de change",               "Mois d'importations", "plancher",          3,   NA,  "Moins de 3 mois d'importations",
  "tcer",       "Extérieur",              "Taux de change effectif réel",     "Indice (base 100)",   "plafond",         110,   NA,  "Appréciation supérieure à 10 %",
  "dette_ext",  "Extérieur",              "Dette extérieure",                 "% du PIB",            "plafond",          40,   NA,  "Supérieure à 40 % du PIB"
) %>%
  mutate(secteur = factor(secteur, levels = names(couleurs_secteur)),
         type_regle = recode(regle,
           plancher = "Plancher", plafond = "Plafond", intervalle = "Intervalle",
           hausse_continue = "Hausse continue", taux_reel = "Calcul dérivé",
           m2_dynamique = "Référence dynamique"))

# Marge de vigilance par défaut (rapport, § 2.4.1) : 20 % du seuil
MARGE_VIGILANCE <- 0.20

# ---- Génération des séries synthétiques -------------------------------------
dates_trim <- seq(as.Date("2018-03-31"), by = "quarter", length.out = 32)
dates_trim <- as.Date(format(dates_trim, "%Y-%m-01")) # 1er jour du dernier mois
# Fin de trimestre propre : 2018-03-01 ... (affichage en trimestres)
libelle_trim <- function(d) paste0(format(d, "%Y"), "-T", (as.integer(format(d, "%m")) - 1) %/% 3 + 1)

ar1 <- function(n, sd, rho = 0.6) {
  e <- stats::rnorm(n, 0, sd); x <- numeric(n); x[1] <- e[1]
  for (t in 2:n) x[t] <- rho * x[t - 1] + e[t]
  x
}

generer_donnees <- function(seed = 2026) {
  set.seed(seed)
  n <- length(dates_trim)
  annee <- as.integer(format(dates_trim, "%Y"))
  choc_covid <- ifelse(annee == 2020, -4.5, ifelse(annee == 2021, -1, 0))

  # Niveaux de base par pays (valeurs plausibles mais FICTIVES)
  base <- tibble::tribble(
    ~pays,                ~pib, ~infl, ~chom, ~sg,  ~rec, ~dp, ~cred, ~npl, ~cc,  ~res, ~de, ~petro,
    "Cameroun",            3.8,  3.2,  6.0,  -2.0, 16.0, 45,  6,      9,   -3.5, 4.5,  32,  0.3,
    "Centrafrique",        1.5,  4.0, 11.0,  -3.5,  9.0, 50,  3,     22,   -7.0, 2.8,  33,  0.0,
    "Congo",               1.8,  3.0, 18.0,  -1.0, 11.0, 85,  4,     18,    2.0, 2.6,  60,  1.0,
    "Gabon",               2.6,  2.0, 20.0,  -1.5, 17.0, 62,  5,      4.2,    1.0, 4.0,  38,  1.0,
    "Guinée équatoriale",  0.8,  2.4,  8.5,  -0.5, 15.5, 40,  2,     20,   -3.0, 3.2,  20,  1.0,
    "Tchad",               3.0,  3.5,  9.0,  -2.5,  8.5, 48,  5,     24,   -4.0, 2.2,  27,  0.8
  )
  # Cycle pétrolier commun (choc 2020, rebond 2022)
  petrole <- c(rep(0, 8), -3, -4, -3, -2, 0, 0, 1, 1, 3, 3.5, 3, 2, 1, 0.5, 0, 0,
               -0.5, -1, -1, -0.5, 0, 0, 0, 0)

  # Taux directeur commun BEAC (trajectoire FICTIVE, identique pour les 6 pays)
  taux <- c(rep(3.5, 8), rep(3.25, 6), rep(3.25, 2), 3.5, 4.0, 4.0, 4.5,
            rep(4.5, 8), rep(4.25, 4))

  lignes <- lapply(seq_len(nrow(base)), function(i) {
    b <- base[i, ]
    pk <- b$petro * petrole
    infl <- b$infl + ar1(n, 0.6) + ifelse(annee == 2022, 2.5, 0) * runif(1, .6, 1.2)
    pib  <- b$pib + choc_covid + 0.4 * pk + ar1(n, 0.7)
    gap  <- 0.5 * (pib - mean(pib)) + ar1(n, 0.4)
    chom <- b$chom + cumsum(stats::rnorm(n, 0.02, 0.18)) + ifelse(annee == 2020, 1.2, 0)
    sg   <- b$sg + 0.6 * pk + ar1(n, 0.8)
    sp   <- sg + runif(1, 1.0, 2.0) + ar1(n, 0.2)
    rec  <- b$rec + 0.15 * pk + ar1(n, 0.5)
    dp   <- b$dp + cumsum(stats::rnorm(n, -0.6 * (sg + 1) / 3, 0.8))
    m2   <- pib + infl + 1.5 + ar1(n, 1.8)
    cred <- b$cred + 0.8 * choc_covid + ar1(n, 2.2)
    npl  <- b$npl + ar1(n, 0.8) + ifelse(annee %in% 2020:2021, 1.5, 0)
    cc   <- b$cc + 0.9 * pk + ar1(n, 0.9)
    res  <- pmax(0.6, b$res + 0.25 * pk + ar1(n, 0.35))
    tcer <- 100 + cumsum(stats::rnorm(n, 0.15, 1.2))
    de   <- b$de + cumsum(stats::rnorm(n, 0.1, 0.6))

    tibble::tibble(
      pays = b$pays, date = rep(dates_trim, 16),
      id = rep(c("pib", "inflation", "gap", "chomage", "solde_glob", "solde_prim",
                 "recettes", "dette_pub", "taux_dir", "m2", "credit", "creances",
                 "cc", "reserves", "tcer", "dette_ext"), each = n),
      valeur = c(pib, infl, gap, chom, sg, sp, rec, dp, taux, m2, cred, npl,
                 cc, res, tcer, de)
    )
  })
  bind_rows(lignes) %>% mutate(valeur = round(valeur, 2))
}

# ---- Consolidation régionale (rapport, § 2.3.3) -----------------------------
# Moyenne pondérée par le PIB, sauf le taux directeur (commun, non moyenné).
# Simplification assumée du prototype : les réserves sont aussi moyennées
# (le rapport recommande le rapport réserves totales / importations agrégées).
agreger_cemac <- function(d) {
  d %>%
    mutate(w = poids_pib[pays]) %>%
    group_by(date, id) %>%
    summarise(valeur = if (first(id) == "taux_dir") first(valeur)
                       else sum(w * valeur) / sum(w),
              .groups = "drop") %>%
    mutate(pays = "CEMAC", valeur = round(valeur, 2))
}

# ---- Moteur de statuts (rapport, éq. 2.5 + annexe D) ------------------------
# Bande de vigilance = marge × max(|seuil|, 1) : la valeur minimale de 1 unité
# évite une bande nulle quand le seuil vaut 0 (solde primaire).
statut_seuil <- function(x, regle, s1, s2, m = MARGE_VIGILANCE) {
  bande <- m * pmax(abs(s1), 1)
  out <- dplyr::case_when(
    is.na(x) ~ "Non disponible",
    regle == "plafond"  & x > s1          ~ "Alerte",
    regle == "plafond"  & x > s1 - bande  ~ "Vigilance",
    regle == "plafond"                    ~ "Sain",
    regle == "plancher" & x < s1          ~ "Alerte",
    regle == "plancher" & x < s1 + bande  ~ "Vigilance",
    regle == "plancher"                   ~ "Sain",
    regle == "intervalle" & (x < s1 | x > s2) ~ "Alerte",
    regle == "intervalle" & abs(x - (s1 + s2) / 2) > (1 - m) * (s2 - s1) / 2 ~ "Vigilance",
    regle == "intervalle"                 ~ "Sain",
    TRUE ~ NA_character_
  )
  out
}

# Nombre de hausses trimestrielles consécutives (règle chômage)
hausses_consecutives <- function(x) {
  h <- c(0, diff(x) > 0); r <- integer(length(x))
  for (t in seq_along(x)) r[t] <- if (h[t] == 1) (if (t > 1) r[t - 1] else 0) + 1 else 0
  r
}

calculer_statuts <- function(d) {
  aux <- d %>% filter(id %in% c("pib", "inflation")) %>%
    select(pays, date, id, valeur) %>%
    pivot_wider(names_from = id, values_from = valeur)

  d %>%
    left_join(referentiel %>% select(id, regle, s1, s2), by = "id") %>%
    left_join(aux, by = c("pays", "date")) %>%
    group_by(pays, id) %>% arrange(date, .by_group = TRUE) %>%
    mutate(
      hausses   = if (first(regle) == "hausse_continue") hausses_consecutives(valeur) else NA_integer_,
      reference = case_when(
        regle == "taux_reel"    ~ valeur - inflation,           # taux directeur réel
        regle == "m2_dynamique" ~ pib + inflation + s1,          # PIB nominal + 2 pts
        TRUE ~ NA_real_)
    ) %>% ungroup() %>%
    mutate(statut = case_when(
      regle == "hausse_continue" & hausses >= 3 ~ "Alerte",
      regle == "hausse_continue" & hausses == 2 ~ "Vigilance",
      regle == "hausse_continue"                ~ "Sain",
      regle == "taux_reel"    ~ statut_seuil(reference, "plancher", 0, NA),
      regle == "m2_dynamique" & valeur > reference        ~ "Alerte",
      regle == "m2_dynamique" & valeur > reference - 1    ~ "Vigilance",
      regle == "m2_dynamique"                             ~ "Sain",
      TRUE ~ statut_seuil(valeur, regle, s1, s2)
    )) %>%
    select(pays, date, id, valeur, reference, statut)
}

# ---- Jeu de données complet (pays + CEMAC) ----------------------------------
construire_base <- function(seed = 2026) {
  brut <- generer_donnees(seed)
  bind_rows(brut, agreger_cemac(brut)) %>%
    calculer_statuts() %>%
    left_join(referentiel %>% select(id, secteur, indicateur, unite), by = "id") %>%
    mutate(pays = factor(pays, levels = c("CEMAC", pays_cemac)),
           statut = factor(statut, levels = names(couleurs_statut)),
           trimestre = libelle_trim(date))
}

# ---- Carré de Kaldor ----------------------------------------------------------
# Scores normalisés dans [0 ; 1] (1 = situation favorable). Conventions du
# prototype : croissance /8 %, inflation 1 - |π-2|/8, chômage 1 - Δ4 trim./2 pts,
# compte courant (CC + 10)/15.  La référence (pointillés) applique les mêmes
# formules aux seuils d'alerte de l'annexe D.
kaldor_scores <- function(base, perimetre, date_sel) {
  v <- base %>% filter(pays == perimetre, id %in% c("pib", "inflation", "chomage", "cc"))
  dern <- v %>% filter(date == date_sel)
  ch_var <- v %>% filter(id == "chomage") %>% arrange(date)
  k <- which(ch_var$date == date_sel)
  d_chom <- if (length(k) && k > 4) ch_var$valeur[k] - ch_var$valeur[k - 4] else 0
  val <- setNames(dern$valeur, dern$id)
  clamp <- function(z) pmin(pmax(z, 0), 1)
  tibble::tibble(
    axe = c("Croissance", "Inflation", "Chômage (variation 1 an)", "Compte courant"),
    valeur = round(c(val["pib"], val["inflation"], d_chom, val["cc"]), 1) + 0,
    unite = c("%", "%", "pt", "% du PIB"),
    score = clamp(c(val["pib"] / 8, 1 - abs(val["inflation"] - 2) / 8,
                    1 - d_chom / 2, (val["cc"] + 10) / 15)),
    reference = clamp(c(2 / 8, 1 - abs(3 - 2) / 8, 1 - 0.5 / 2, (-5 + 10) / 15))
  )
}

kaldor_coords <- function(sc) {
  ang <- pi / 2 - (seq_len(nrow(sc)) - 1) * 2 * pi / nrow(sc)
  sc %>% mutate(angle = ang,
                x = score * cos(ang), y = score * sin(ang),
                xr = reference * cos(ang), yr = reference * sin(ang),
                xl = 1.18 * cos(ang), yl = 1.18 * sin(ang))
}
