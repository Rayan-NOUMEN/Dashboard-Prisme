# PRISME · Dashboard du rapport de stage (cours DATAVIZ)

Dashboard **flexdashboard + Shiny** qui présente le rapport de stage de NOUMEN DJOFANG Yvan Rayan (ISSEA, AS3) :
*« Conception d'un outil de diagnostic macroéconomique et de suivi des alertes pour les pays de la CEMAC »* (BEAC / DERSRI, août–septembre 2026).
Le rapport (version publique) est téléchargeable depuis l'application.

## Packages et rôle de chacun

| Package | Rôle dans le dashboard |
|---|---|
| **flexdashboard** | Structure : pages, lignes et colonnes, cartes, `valueBox` |
| **shiny** | Interactivité : filtres, calculs réactifs, téléchargements |
| **ggplot2 + plotly** | Graphiques affichés à l'écran (interactifs) |
| **flextable** | Tableaux mis en forme (écran, Word, PowerPoint) |
| **officer** | Génération des fichiers `.docx` et `.pptx` |
| **mschart** | Graphiques **natifs** Office, modifiables dans Word / PowerPoint |

## Pages

1. **Accueil** : chiffres clés, résumé du projet, téléchargement du rapport PDF
2. **Le stage** : chronologie (Gantt interactif), structure d'accueil, difficultés
3. **Cadre du diagnostic** : référentiel des 16 indicateurs (flextable), règle de statut, simulateur interactif
4. **PRISME** : chaîne fonctionnelle, démarche GIMSI, fonctionnalités, captures de l'application
5. **Démonstration** : carte des statuts, évolution, comparaison, carré de Kaldor (données **fictives**)
6. **Bilan** : apports, limites, recommandations
7. **Exports** : synthèse Word ou PowerPoint générée à la demande (officer + mschart + flextable)

## Arborescence

```
index.Rmd                 # le dashboard (flexdashboard, runtime: shiny)
R/donnees.R               # référentiel, données synthétiques, moteur de statuts, Kaldor
R/exports.R               # génération Word / PowerPoint
www/style.css             # habillage
www/img/                  # captures de PRISME extraites du rapport, favicon
www/Rapport_stage_NOUMEN_version_publique.pdf   # rapport sans annexes A et C
```

## Lancer en local (RStudio)

```r
install.packages(c("flexdashboard", "shiny", "rmarkdown", "officer", "mschart",
                   "flextable", "ggplot2", "plotly", "dplyr", "tidyr", "rsconnect"))
rmarkdown::run("index.Rmd")
```

Dans RStudio, on peut aussi ouvrir `index.Rmd` et cliquer sur **Run Document**.

## Données

Toutes les séries de la page « Démonstration » et des exports sont **synthétiques** (`set.seed(2026)`). Elles suivent la structure décrite dans le rapport (tableau 2), mais ne décrivent pas la situation réelle des pays de la CEMAC. Les seuils sont ceux du prototype (annexe D) et ne sont pas homologués par la BEAC.
