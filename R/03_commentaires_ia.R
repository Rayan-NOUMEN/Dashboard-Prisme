# ============================================================================
# 03_commentaires_ia.R — Commentaire rédigé par une IA, avec repli PRISME
#
# Par défaut : API Groq (gratuite, compatible OpenAI). Tout fournisseur
# compatible OpenAI fonctionne en changeant les variables d'environnement :
#   IA_CLE      clé API (ou GROQ_API_KEY)          — jamais dans le code / GitHub
#   IA_URL      défaut https://api.groq.com/openai/v1/chat/completions
#   IA_MODELE   défaut openai/gpt-oss-120b (llama-3.3-70b-versatile a été retiré
#               de l'offre gratuite de Groq en août 2026)
#   IA_DELAI    délai max en secondes (défaut 8)
# Sur Posit Connect Cloud : Settings > Variables (secret).
#
# Garde-fous : l'IA ne reçoit QUE les chiffres calculés par PRISME ; tout
# nombre de sa réponse absent de ces chiffres => réponse rejetée et repli
# automatique sur le commentaire par règles (02_commentaires_prisme.R).
# ============================================================================

ia_config <- function() {
  cle <- Sys.getenv("IA_CLE", unset = Sys.getenv("GROQ_API_KEY"))
  list(cle = cle,
       url = Sys.getenv("IA_URL", unset = "https://api.groq.com/openai/v1/chat/completions"),
       modele = Sys.getenv("IA_MODELE", unset = "openai/gpt-oss-120b"),
       delai = as.numeric(Sys.getenv("IA_DELAI", unset = "8")))
}
ia_disponible <- function() nzchar(ia_config()$cle)

.cache_ia <- new.env(parent = emptyenv())

#' Message envoyé à l'IA : uniquement des faits vérifiables.
prompt_ia <- function(f) {
  i <- f$ind
  paste0(
    "Rédige un commentaire de diagnostic macroéconomique en français, 2 à 3 phrases, ton sobre de banque centrale.\n",
    "Règles strictes : n'utilise AUCUN chiffre autre que ceux fournis ci-dessous ; n'invente ni cause, ni événement, ",
    "ni prévision ; n'affirme rien sur la politique de la BEAC ; pas de titre, pas de liste, pas de markdown.\n\n",
    "Périmètre : ", libelle_entite(f$entite), "\n",
    "Indicateur : ", i$nom, " (pilier ", i$secteur, ", unité : ", i$unite, ")\n",
    "Dernière valeur : ", formater_valeur(f$valeur, i$unite), " en ", formater_mois(f$date),
    if (isTRUE(f$estime)) " (valeur estimée par interpolation)" else "", "\n",
    "Variation sur douze mois : ", if (is.na(f$variation)) "non disponible" else
      paste(formater_nombre(f$variation, 1), unite_variation(i$unite)), "\n",
    "Seuil d'alerte : ", i$description_seuil, "\n",
    "Statut calculé par PRISME : ", f$statut, "\n",
    "Rappel : données fictives de démonstration.")
}

#' Nombres présents dans un texte (format français ou anglais).
nombres_du_texte <- function(txt) {
  m <- regmatches(txt, gregexpr("-?[0-9]+(?:[.,][0-9]+)?", txt, perl = TRUE))[[1]]
  as.numeric(sub(",", ".", m, fixed = TRUE))
}

#' Vrai si tous les nombres de la réponse proviennent des faits fournis.
chiffres_conformes <- function(reponse, f) {
  permis <- c(nombres_du_texte(prompt_ia(f)), 1:12, 0)
  n <- nombres_du_texte(reponse)
  all(vapply(n, function(v) any(abs(abs(v) - abs(permis)) < 0.051), logical(1)))
}

appel_ia <- function(f, cfg = ia_config()) {
  req <- httr2::request(cfg$url) |>
    httr2::req_auth_bearer_token(cfg$cle) |>
    httr2::req_timeout(cfg$delai) |>
    httr2::req_retry(max_tries = 1) |>
    httr2::req_body_json(c(list(
      model = cfg$modele, temperature = 0.3, max_tokens = 700,
      messages = list(
        list(role = "system", content = "Tu es économiste. Tu ne cites que les chiffres fournis."),
        list(role = "user", content = prompt_ia(f)))),
      # Modèles « à raisonnement » (gpt-oss) : raisonnement court pour répondre vite.
      if (grepl("gpt-oss", cfg$modele)) list(reasoning_effort = "low")))
  rep <- httr2::req_perform(req)
  txt <- httr2::resp_body_json(rep)$choices[[1]]$message$content
  trimws(gsub("\\*+", "", txt))
}

#' Commentaire d'un indicateur : IA si possible, sinon PRISME.
#' Retourne list(texte, source, ia = TRUE/FALSE, raison).
commenter <- function(entite, id, jusqu_a = DERNIERE_DATE, utiliser_ia = TRUE) {
  f <- faits_indicateur(entite, id, jusqu_a)
  repli <- function(raison) list(texte = commentaire_prisme(f), source = "Commentaire PRISME (règles)",
                                 ia = FALSE, raison = raison)
  if (!utiliser_ia) return(repli("IA non demandée"))
  if (is.na(f$valeur)) return(repli("pas de donnée"))
  cfg <- ia_config()
  if (!nzchar(cfg$cle)) return(repli("aucune clé API configurée"))
  cle_cache <- paste(entite, id, f$date, cfg$modele, sep = "|")
  if (!is.null(.cache_ia[[cle_cache]])) return(.cache_ia[[cle_cache]])
  res <- tryCatch({
    txt <- appel_ia(f, cfg)
    if (!nzchar(txt)) repli("réponse vide")
    else if (!chiffres_conformes(txt, f)) repli("chiffres non conformes dans la réponse IA")
    else list(texte = txt, source = paste0("Rédigé par IA (", cfg$modele, ") — à vérifier"), ia = TRUE, raison = "")
  }, error = function(e) repli(paste("API indisponible :", strsplit(conditionMessage(e), "\n")[[1]][1])))
  if (isTRUE(res$ia)) assign(cle_cache, res, envir = .cache_ia)
  res
}
