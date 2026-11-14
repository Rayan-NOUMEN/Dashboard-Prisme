# Déployer le dashboard gratuitement sur Posit Connect Cloud

> Pourquoi pas shinyapps.io ? Posit migre shinyapps.io vers **Connect Cloud** et arrête shinyapps.io le **31 décembre 2026**. Connect Cloud est la plateforme recommandée, et son plan gratuit accepte les documents R Markdown Shiny comme celui-ci.

Durée totale : environ 20 minutes.

---

## Étape 1 : tester en local (5 min)

1. Dézippe le dossier `dashboard_stage`.
2. Dans RStudio : **File > Open Project** n'est pas nécessaire. Fais simplement **Session > Set Working Directory > Choose Directory…** et choisis le dossier `dashboard_stage`.
3. Dans la console :

```r
install.packages(c("flexdashboard", "shiny", "rmarkdown", "officer", "mschart",
                   "flextable", "ggplot2", "plotly", "dplyr", "tidyr", "rsconnect"))
rmarkdown::run("index.Rmd")
```

4. Vérifie que les 7 pages s'affichent, puis teste les 3 téléchargements : le PDF, la synthèse Word et la synthèse PowerPoint.
5. Arrête l'application avec le bouton **Stop** (carré rouge) de la console.

## Étape 2 : générer le fichier `manifest.json` (1 min)

Connect Cloud a besoin de ce fichier pour savoir quels packages installer. Il **doit** être généré sur ta machine, à partir de tes versions de packages. Toujours dans le dossier `dashboard_stage` :

```r
rsconnect::writeManifest(appPrimaryDoc = "index.Rmd")
```

Un fichier `manifest.json` apparaît dans le dossier.

## Étape 3 : pousser sur GitHub (5 min)

1. Sur github.com : **New repository** et nomme-le par exemple `dashboard-prisme`.
   - Choisis **Public**, car le plan gratuit de Connect Cloud déploie depuis un dépôt public.
   - Ne coche ni README ni .gitignore.
2. Envoie les fichiers, au choix :
   - **Le plus simple** : sur la page du dépôt vide, clique sur **uploading an existing file** et glisse **tout le contenu** du dossier (`index.Rmd`, `manifest.json`, `README.md`, et les dossiers `R/` et `www/`), puis **Commit changes**. Vérifie que les sous-dossiers `R/` et `www/img/` sont bien présents.
   - **Ou en ligne de commande**, dans le dossier :

```bash
git init
git add .
git commit -m "Dashboard PRISME - cours DATAVIZ"
git branch -M main
git remote add origin https://github.com/<ton-compte>/dashboard-prisme.git
git push -u origin main
```

## Étape 4 : déployer sur Connect Cloud (5 min)

1. Va sur **https://connect.posit.cloud** et clique sur **Sign up / Log in with GitHub**. Autorise l'accès.
2. Clique sur **Publish** (ou **+ New Content**), puis choisis **R Markdown** si on te demande le type.
3. Choisis le dépôt `dashboard-prisme`, la branche `main`, et le fichier principal **`index.Rmd`**.
4. Clique sur **Publish**. Le premier déploiement prend quelques minutes, le temps d'installer les packages.
5. Une fois en ligne, copie l'URL publique : c'est le lien à rendre.
6. Optionnel : active **Republish on push** pour que chaque push sur GitHub redéploie automatiquement.

## En cas de problème

| Symptôme | Solution |
|---|---|
| « manifest.json not found » | Refaire l'étape 2, puis pousser le fichier sur GitHub. |
| Erreur d'installation d'un package | Mettre à jour les packages en local (`update.packages()`), régénérer `manifest.json`, pousser. |
| Accents illisibles | Vérifier que les fichiers sont bien encodés en UTF-8 (c'est le cas dans l'archive). |
| Le PDF ne se télécharge pas | Vérifier que `www/Rapport_stage_NOUMEN_version_publique.pdf` est bien sur GitHub (fichier de 1,2 Mo). |
| L'application « s'endort » | C'est normal sur le plan gratuit : elle se réveille au premier visiteur, après quelques secondes d'attente. |

## Plan B : shinyapps.io (encore actif jusqu'au 31/12/2026)

```r
rsconnect::setAccountInfo(name = "<compte>", token = "<token>", secret = "<secret>")
rsconnect::deployApp(appPrimaryDoc = "index.Rmd", appName = "dashboard-prisme")
```

Le token et le secret se trouvent dans shinyapps.io, sous **Account > Tokens > Show**.
