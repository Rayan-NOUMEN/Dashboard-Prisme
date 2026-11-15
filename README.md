# Dashboard PRISME — rapport de stage (cours DATAVIZ)

Tableau de bord **flexdashboard + shiny** qui présente le rapport de stage de NOUMEN DJOFANG Yvan Rayan
(BEAC, DERSRI, 2026) et les indicateurs clés de l’application PRISME.
Données : jeu d’exemple **fictif** de PRISME (aucune donnée réelle de la BEAC).

| Onglet | Contenu | Outils |
|---|---|---|
| Accueil | Chiffres clés, téléchargement du rapport, statuts des 6 pays (clic → page du pays) | valueBox, plotly |
| Vue CEMAC | Carte des alertes + grille 6 pays × 16 indicateurs, animée année par année | plotly |
| Indicateurs | Courbe avec zones d’alerte / vigilance, tuiles, commentaire IA (repli PRISME) | plotly, Groq |
| Kaldor | Carré de Kaldor de 1 à 3 pays, animé par année | plotly |
| Comparaison | 2 ou 3 pays sur un indicateur : trajectoires + dernière valeur face au seuil | plotly |
| Exports | Rapport de stage complet et fiche indicateurs personnalisée, en Word | officer, mschart, flextable |

Les graphiques de la page sont en **plotly** ; ceux des documents Word sont en **mschart** (graphiques Word
natifs : clic droit > *Modifier les données*). Les tableaux Word sont en **flextable**.

## Arborescence

```
index.Rmd                     le dashboard (6 onglets + code serveur)
R/00_theme.R                  couleurs et constantes (source unique)
R/01_donnees.R                lecture de data/prisme_extrait.rds, mise en forme des nombres
R/02_commentaires_prisme.R    commentaires par règles (repris de PRISME)
R/03_commentaires_ia.R        commentaires IA (Groq) + repli automatique
R/04_word_commun.R            styles Word, texte enrichi, tableaux, thème mschart
R/05_rapport_complet.R        rapport de stage complet (Word)
R/06_fiche_word.R             fiche indicateurs personnalisée (Word)
R/07_graphiques.R             graphiques plotly de la page
rapport/contenu_*.md          texte du rapport (modifiable), rapport/images/ ses illustrations
data/prisme_extrait.rds       extrait des données PRISME (lecture seule)
tools/extraire_donnees_prisme.R  régénère l’extrait depuis l’application PRISME
www/                          style.css, logo, favicon
```

**Modifier le texte du rapport** : éditer `rapport/contenu_corps.md` (titres `#`, `##`, `###`, puces `- `,
`**gras**`, `*italique*`). Les balises `!tableau`, `!image`, `!equation`, `!graphique` insèrent les éléments.

## 1. Lancer en local

```r
install.packages(c("flexdashboard", "shiny", "rmarkdown", "plotly", "officer", "mschart",
                   "flextable", "httr2", "png", "jpeg", "xml2", "zip", "rsconnect"))
rmarkdown::run("index.Rmd")
```
(Session > Set Working Directory > Choose Directory… sur ce dossier avant de lancer.)

## 2. Commentaires IA (gratuit, facultatif)

Sans clé, le dashboard fonctionne : il utilise les commentaires PRISME. Pour activer l’IA :

1. Créer un compte sur https://console.groq.com (gratuit, sans carte), menu **API Keys > Create API Key**.
2. **En local** : `Sys.setenv(IA_CLE = "gsk_...")` avant `rmarkdown::run()`. Ne jamais écrire la clé dans un fichier.
3. **Sur Posit Connect Cloud** : contenu > ⚙ Settings > **Variables** > ajouter `IA_CLE` = la clé (cocher *secret*),
   puis republier.

Options : `IA_MODELE` (défaut `openai/gpt-oss-120b`), `IA_URL` (tout service compatible OpenAI, par ex. Gemini :
`https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`), `IA_DELAI` (secondes, défaut 8).

Garde-fous : l’IA ne reçoit que les chiffres calculés par PRISME ; si sa réponse contient un nombre qui n’en fait pas
partie, si l’API ne répond pas, si la clé est absente ou le quota atteint, le commentaire PRISME est affiché à la
place. La source est toujours indiquée sous le commentaire.

## 3. Déployer sur Posit Connect Cloud (dépôt GitHub existant)

1. Lancer une fois en local (étape 1) pour vérifier que tout fonctionne.
2. Générer le manifeste **sur ta machine** : `rsconnect::writeManifest(appPrimaryDoc = "index.Rmd")`.
3. Remplacer le contenu du dépôt GitHub par ce dossier (avec `manifest.json`), puis *Commit*.
4. Si « Republier à chaque push » est activé, le déploiement est automatique ; sinon **Republish** sur Connect Cloud.
5. Ajouter la variable `IA_CLE` (étape 2) si l’IA est souhaitée.

## Points d’attention

* **Sommaires du Word** : à l’ouverture, Word demande de mettre à jour les champs → répondre **Oui** ; le sommaire,
  la table des matières et les listes se remplissent. (LibreOffice : Outils > Mettre à jour > Tout.)
* **Carte** : le fond de carte est chargé par le navigateur depuis `cdn.plot.ly` ; il faut une connexion Internet
  côté visiteur (c’est le cas sur Posit Connect Cloud).
* **Régénérer les données** : `Rscript tools/extraire_donnees_prisme.R <dossier_prisme> data/prisme_extrait.rds`.
