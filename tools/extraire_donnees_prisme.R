# ============================================================================
# extraire_donnees_prisme.R — Produit data/prisme_extrait.rds à partir de PRISME
# À lancer UNE fois, hors du dashboard, depuis un poste où PRISME fonctionne :
#   Rscript tools/extraire_donnees_prisme.R <dossier_prisme> <sortie.rds>
# Le dashboard ne lit ensuite que le .rds (pas de SQLite, lecture seule).
# Données : jeu d'exemple FICTIF de PRISME (aucune donnée BEAC réelle).
# ============================================================================
args <- commandArgs(TRUE)
dossier <- normalizePath(args[1]); sortie <- file.path(normalizePath(dirname(args[2])), basename(args[2]))
setwd(dossier)
g <- readLines("global.R", encoding = "UTF-8")
g <- g[!grepl("library\\((shinymanager|shinyWidgets)\\)", g)]   # inutiles pour l'extraction
eval(parse(text = g, encoding = "UTF-8"), envir = globalenv())
for (f in sort(list.files("R", pattern = "^[^_].*\\.[rR]$", full.names = TRUE))) source(f, encoding = "UTF-8")

ie <- indicateurs_effectifs()
seuils <- do.call(rbind, lapply(seq_len(nrow(ie)), function(k) {
  ls <- lignes_seuil(ie[k, ])
  data.frame(id = ie$id[k],
             alerte_1 = c(ls$alerte, NA)[1], alerte_2 = c(ls$alerte, NA, NA)[2],
             vigilance_1 = c(ls$vigilance, NA)[1], vigilance_2 = c(ls$vigilance, NA, NA)[2])
}))
indicateurs <- merge(ie[, c("id", "secteur", "nom", "unite", "type_seuil", "seuil", "phrase", "description_seuil")],
                     seuils, by = "id", sort = FALSE)
indicateurs <- indicateurs[match(ie$id, indicateurs$id), ]
indicateurs$ordre <- seq_len(nrow(indicateurs))

prep <- function(long, entite) {
  long <- long[order(long$indicateur_id, long$date), ]
  data.frame(entite = entite, date = long$date, indicateur_id = long$indicateur_id,
             valeur = long$valeur, statut = long$statut, estime = est_interpole(long),
             stringsAsFactors = FALSE)
}
series <- do.call(rbind, c(lapply(PAYS_CEMAC, function(p) prep(charger_series_pays(p), p)),
                           list(prep(charger_regional()$long, VUE_REGIONALE))))

# Carré de Kaldor : situation à chaque fin d'année (décembre), par entité.
kaldor <- do.call(rbind, lapply(unique(series$entite), function(e) {
  l <- series[series$entite == e, ]
  annees <- sort(unique(as.integer(format(l$date[format(l$date, "%m") == "12"], "%Y"))))
  do.call(rbind, lapply(annees, function(a) {
    k <- calculer_kaldor(l[l$date <= as.Date(sprintf("%d-12-01", a)), ], ie)
    cbind(entite = e, annee = a, k[, c("axe", "indicateur_id", "r", "valeur", "reference", "statut")])
  }))
}))

pays <- PAYS_INFO
pays$genitif[pays$nom == "Centrafrique"] <- "de la Centrafrique"
pays <- rbind(pays, data.frame(nom = VUE_REGIONALE, iso3 = NA, slug = "cemac", genitif = "de la CEMAC"))

saveRDS(list(series = series, indicateurs = indicateurs, kaldor = kaldor, pays = pays,
             kaldor_axes = KALDOR_AXES,
             meta = list(source = "PRISME — jeu d'exemple fictif", extrait_le = Sys.Date(),
                         derniere_date = max(series$date))),
        sortie)
cat("Extrait écrit :", sortie, "—", nrow(series), "lignes\n")
