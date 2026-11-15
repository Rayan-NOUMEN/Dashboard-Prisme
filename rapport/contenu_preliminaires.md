#* Dédicace

!dedicace Je dédie ce rapport de stage à mes chers parents, || M. et Mme NOUMEN, || pour leur amour et leur soutien inconditionnels.

#* Remerciements

Je tiens à remercier toutes les personnes qui m’ont accueilli et accompagné à la BEAC, ainsi que celles qui ont contribué à ma formation à l’ISSEA. Ma reconnaissance va particulièrement :

- à M. Yvon SANA BANGUI, Gouverneur de la Banque des États de l’Afrique Centrale, pour m’avoir donné l’opportunité d’effectuer mon stage au sein des Services Centraux de la Banque ;

- à M. Evrard Ulrich Herménégilde MOUNKALA, directeur de la DERSRI, pour son accueil et pour l’organisation du programme d’immersion qui m’a permis de découvrir les activités de sa direction ;

- à M. Emile Thierry MVONDO, premier adjoint au directeur de la DERSRI et mon encadreur professionnel, pour sa disponibilité, sa confiance, ses orientations et ses remarques qui ont guidé la conception de PRISME ;

- à M. Hardit BATOUMEN et à l’ensemble des responsables des pôles de la DERSRI, pour la qualité de leurs présentations, leurs explications et le partage de leur expérience professionnelle ;

- à Dr. Marcel OPOUMBA, Directeur Général de l’ISSEA, pour la qualité de la formation dont nous bénéficions à l’Institut ;

- à Dr. Dieudonné KINKIELELE, Directeur des Études, et à M. Symplice NGAH NGAH, coordonnateur de la filière Analyste Statisticien, pour leurs conseils et les efforts qu’ils déploient afin de nous inculquer la discipline, la rigueur et la ponctualité ;

- à Dr. Paul Brice DONGMEZO, coordonnateur de la filière ISE et notre enseignant de R, pour la richesse technique de ses enseignements, ses astuces de programmation et son exigence qui m’ont particulièrement servi dans le développement de PRISME ; ainsi qu’à Dr. WANSOUWE WANBITCHING et Dr. Igor-Mathieu GONDJEDACKA, pour leurs conseils, leur soutien et leur accompagnement depuis mon entrée à l’ISSEA ;

- à KINGUE Serge, mon camarade de l’ISSEA et co-stagiaire, pour m’avoir suggéré l’idée d’intégrer un assistant intelligent à PRISME ;

- enfin, à mes parents, à ma famille, à mes camarades et à toutes les personnes qui m’ont encouragé tout au long de ce stage.

#* Sigles et abréviations

!sigles AS | Analyste Statisticien ;; BEAC | Banque des États de l’Afrique Centrale ;; CEMAC | Communauté Économique et Monétaire de l’Afrique Centrale ;; DERSRI | Direction des Études, de la Recherche, des Statistiques et des Relations Internationales ;; DGEFRI | Direction Générale des Études, Finances et Relations Internationales ;; FMI | Fonds monétaire international ;; INS | Institut national de statistique ;; IPC | Indice des prix à la consommation ;; ISSEA | Institut Sous-régional de Statistique et d’Économie Appliquée ;; M2 | Agrégat monétaire large M2 ;; PDF | Portable Document Format ;; PIB | Produit intérieur brut ;; PRISME | Dénomination de la plateforme développée au cours du stage ;; R | Langage et environnement de calcul statistique ;; SQLite | Moteur de base de données relationnelle embarquée ;; TCER | Taux de change effectif réel ;; UMAC | Union Monétaire de l’Afrique Centrale

#* Avant-propos

L’Institut Sous-régional de Statistique et d’Économie Appliquée (ISSEA) est un établissement spécialisé de formation et de recherche dans l’espace de la Communauté Économique et Monétaire de l’Afrique Centrale. Ses missions s’articulent autour de trois axes complémentaires : la formation initiale de cadres statisticiens et économistes, la formation continue et le perfectionnement des professionnels, ainsi que la recherche appliquée en méthodologie, collecte, traitement et analyse de l’information statistique et économique.

La formation d’Analyste Statisticien associe des enseignements théoriques à des applications pratiques destinées à développer la capacité de répondre à des problèmes concrets de production et d’exploitation de données. Le stage académique constitue, à cet égard, une étape de confrontation des connaissances scolaires aux exigences du travail institutionnel. Il contribue au développement de l’autonomie, de la rigueur et du sens des responsabilités.

Le présent rapport rend compte d’un stage réalisé du 3 août au 25 septembre 2026 à la Banque des États de l’Afrique Centrale (BEAC), au sein de sa Direction des Études, de la Recherche, des Statistiques et des Relations Internationales. Ce cadre a permis de découvrir les activités de plusieurs pôles et de travailler sur un besoin identifié par l’encadreur : faciliter le diagnostic macroéconomique dans la zone CEMAC, auparavant organisé au moyen de multiples feuilles de calcul.

C’est dans ce contexte que j’ai travaillé sur le thème : « Conception d’un outil de diagnostic macroéconomique et de suivi des alertes pour les pays de la CEMAC ». La réalisation de PRISME m’a permis de mettre en pratique les enseignements reçus, de découvrir la façon dont les services économiques organisent leurs analyses et de mesurer l’importance de rendre l’information à la fois fiable et facilement accessible. Le présent rapport retrace le déroulement de cette expérience et les principales étapes de réalisation de l’outil. Résumé

#* Résumé

Le diagnostic macroéconomique permet à une banque centrale de suivre les tendances économiques, d’identifier les déséquilibres et d’éclairer l’analyse des risques. À la Direction des Études, de la Recherche, des Statistiques et des Relations Internationales de la BEAC, la gestion de multiples fichiers Excel rendait les consultations et la consolidation des informations particulièrement laborieuses. Ce stage avait pour objectif de concevoir un outil interactif de diagnostic macroéconomique et de suivi des alertes applicable aux six pays de la CEMAC.

À partir d’une note de cadrage et d’une trame d’indicateurs communiquées par l’encadreur, une application dénommée PRISME a été développée avec le langage R, le framework Shiny et une base de données SQLite. L’outil organise seize indicateurs en quatre secteurs, présente une consultation nationale et régionale, associe les valeurs à des règles de vigilance et d’alerte, propose une comparaison entre pays, un carré de Kaldor, un circuit de validation des données, une gestion des droits, un assistant intégré nommé Iris et des exports PDF et Word. La démarche repose sur l’étude de l’existant, la formalisation des besoins, la modélisation des traitements et une démonstration sur données synthétiques.

Le résultat principal est la réalisation d’une plateforme fonctionnelle, présentée à l’encadreur et dont une version lui a été remise. En l’absence de données opérationnelles, il n’est pas possible de conclure sur la situation économique réelle des pays étudiés ni sur l’efficacité institutionnelle après déploiement. Les recommandations portent sur la qualification des sources, l’arbitrage des seuils, la validation des traitements, la sécurité et l’intégration ultérieure dans l’infrastructure de la Banque.

**Mots-clés :** diagnostic macroéconomique ; CEMAC ; tableau de bord ; systèmes d’alerte ; R Shiny ; aide à la décision.

#* Abstract

Macroeconomic diagnosis enables a central bank to monitor economic developments, identify imbalances and support risk assessment. At the BEAC’s Directorate of Studies, Research, Statistics and International Relations, the management of multiple Excel spreadsheets made consultation and consolidation of macroeconomic information time-consuming. The objective of this internship was to design an interactive macroeconomic diagnostic and alert-monitoring tool for the six CEMAC member states.

Based on a methodological brief and an indicator template provided by the supervisor, a platform called PRISME was developed using R, Shiny and a SQLite database. It organises sixteen indicators into four sectors and includes national and regional views, threshold-based alerts, cross-country comparison, a Kaldor-style chart, a data approval workflow, access controls, a built-in assistant named Iris, and PDF/Word reporting. The approach combines assessment of existing processes, requirements analysis, software design and functional demonstrations using synthetic data.

The main deliverable is a functional application that was demonstrated to the professional supervisor and handed over to him. Because operational economic data were not available for this work, the project does not establish findings about actual CEMAC economic conditions or confirm results under production conditions. Further steps include data-source qualification, institutional approval of thresholds, functional validation, security assessment and potential deployment within BEAC infrastructure.

**Keywords :** macroeconomic diagnosis ; CEMAC ; dashboard ; early warning ; R Shiny ; decision support.
