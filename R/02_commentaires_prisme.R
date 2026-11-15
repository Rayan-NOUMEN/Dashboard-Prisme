# ============================================================================
# 02_commentaires_prisme.R — Commentaires par règles, repris de PRISME
# (utils_commentaires.R). Sert de REPLI quand l'IA ne répond pas : gratuit,
# instantané, toujours exact sur les chiffres (il ne fait que les reformuler).
# ============================================================================

VARIANTES_COMMENTAIRE <- list(
  Sain = c(
    "{sujet} s'établit à {valeur} en {date}{tendance}, dans la norme (seuil d'alerte : {seuil}). Aucun point d'attention.",
    "En {date}, {sujet} ressort à {valeur}{tendance}. Ce niveau reste éloigné du seuil d'alerte ({seuil}) : la situation est saine.",
    "{sujet} est mesuré à {valeur} en {date}{tendance}, sans tension par rapport au seuil retenu ({seuil}).",
    "Situation satisfaisante : {sujet} atteint {valeur} en {date}{tendance}, à distance confortable du seuil d'alerte ({seuil})."),
  Vigilance = c(
    "{sujet} atteint {valeur} en {date}{tendance} et se rapproche du seuil d'alerte ({seuil}) : une surveillance rapprochée est recommandée.",
    "En {date}, {sujet} s'établit à {valeur}{tendance}. La marge de sécurité par rapport au seuil ({seuil}) se réduit ; l'indicateur est placé en vigilance.",
    "Point de vigilance : {sujet} ressort à {valeur} en {date}{tendance}, à proximité du seuil d'alerte ({seuil}).",
    "{sujet} ({valeur} en {date}){tendance} entre dans la zone de vigilance avant le seuil d'alerte ({seuil}) ; l'évolution des prochains mois sera déterminante."),
  Alerte = c(
    "{sujet} atteint {valeur} en {date}{tendance} : le seuil d'alerte ({seuil}) est franchi. Un examen approfondi et des mesures correctrices sont nécessaires.",
    "Alerte : en {date}, {sujet} s'établit à {valeur}{tendance}, au-delà du seuil critique ({seuil}). Cette situation appelle une réponse de politique économique.",
    "{sujet} ressort à {valeur} en {date}{tendance}, en dépassement du seuil d'alerte ({seuil}) : l'indicateur est classé en alerte.",
    "Le franchissement du seuil d'alerte ({seuil}) par {sujet} ({valeur} en {date}){tendance} constitue un signal de dégradation à traiter en priorité."),
  "n.d." = c(
    "Aucune donnée récente n'est disponible pour {sujet} : le diagnostic ne peut pas être établi.",
    "{sujet} n'est pas renseigné à ce jour ; il n'est donc pas possible d'apprécier sa position par rapport au seuil ({seuil}).")
)

unite_variation <- function(unite) {
  if (startsWith(unite, "%")) "point(s) de pourcentage"
  else if (grepl("^Indice", unite)) "point(s) d'indice"
  else "mois d'importations"
}

#' Faits chiffrés d'un indicateur à une date limite (servent à la fois au
#' commentaire PRISME et au message envoyé à l'IA : une seule source de vérité).
faits_indicateur <- function(entite, id, jusqu_a = DERNIERE_DATE) {
  i <- ind_info(id)
  s <- serie(entite, id); s <- s[s$date <= jusqu_a & !is.na(s$valeur), ]
  if (!nrow(s)) return(list(entite = entite, ind = i, valeur = NA, statut = "n.d.", date = NA, variation = NA))
  d <- s[nrow(s), ]
  prec <- s[s$date == seq(d$date, by = "-1 year", length.out = 2)[2], ]
  list(entite = entite, ind = i, valeur = d$valeur, statut = ifelse(is.na(d$statut), "n.d.", d$statut),
       date = d$date, variation = if (nrow(prec)) d$valeur - prec$valeur[1] else NA_real_,
       estime = isTRUE(d$estime))
}

commentaire_prisme <- function(f) {
  i <- f$ind; statut <- if (is.na(f$valeur)) "n.d." else f$statut
  variantes <- VARIANTES_COMMENTAIRE[[statut]]
  sujet_pays <- genitif(f$entite)
  gabarit <- variantes[(sum(utf8ToInt(paste(sujet_pays, i$id))) %% length(variantes)) + 1]
  tendance <- ""
  if (!is.na(f$variation) && statut != "n.d.") {
    tendance <- if (abs(f$variation) < 0.05) ", stable sur douze mois"
      else paste0(", en ", if (f$variation > 0) "hausse" else "baisse", " de ",
                  formater_nombre(abs(f$variation), 1), " ", unite_variation(i$unite), " sur douze mois")
  }
  sujet <- paste(i$phrase, sujet_pays)
  sujet <- if (grepl("^\\{sujet\\}", gabarit)) paste0(toupper(substr(sujet, 1, 1)), substring(sujet, 2)) else sujet
  txt <- gabarit
  txt <- gsub("{sujet}", sujet, txt, fixed = TRUE)
  txt <- gsub("{valeur}", if (statut == "n.d.") "n.d." else formater_valeur(f$valeur, i$unite), txt, fixed = TRUE)
  txt <- gsub("{date}", if (is.na(f$date)) "—" else formater_mois(f$date), txt, fixed = TRUE)
  txt <- gsub("{seuil}", i$description_seuil, txt, fixed = TRUE)
  gsub("{tendance}", tendance, txt, fixed = TRUE)
}
