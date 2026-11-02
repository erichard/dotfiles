---
name: linear-stats
description: >-
  Statistiques de tickets Linear : volume créé par semaine, top 3 des scopes, répartition par
  statut, filtrable par label et par fenêtre de semaines. À charger quand on demande combien de
  tickets ont été créés, comment ils se répartissent, ou d'où vient le flux (Service client…).
---

# Stats tickets Linear

## Aperçu

Génère des statistiques sur les tickets Linear : nombre de tickets créés par semaine, top 3 des scopes et répartition par statut. Filtrable par label et nombre de semaines.

## Paramètres

- **Label** : label Linear à filtrer (par défaut : "Service client")
- **Semaines** : nombre de semaines à analyser (par défaut : 4)

Les arguments du skill sont passés sous forme libre, par exemple : `/linear-stats Service client 8 semaines` ou `/linear-stats` (valeurs par défaut).

## Étapes

1. **Récupérer les tickets**

    - Utiliser `mcp__claude_ai_Linear__list_issues` avec le label spécifié, team ID `7741b9e1-bae9-46f1-a25b-a44a446073e5`, `orderBy: createdAt`, `limit: 250`, `includeArchived: true`
    - Paginer avec le curseur si `hasNextPage` est true
    - Les IDs de labels et statuts sont documentés dans le skill `linear-conventions` du dépôt Revel'Home

2. **Calculer les stats par semaine ISO**

    - Filtrer les tickets sur le nombre de semaines demandé à partir de la date courante
    - Pour chaque semaine, calculer :
      - Nombre total de tickets créés
      - Top 3 des labels de type **Scope** (voir liste ci-dessous)
      - Répartition par statut avec pourcentage

3. **Afficher les résultats**

    - Tableau récapitulatif : semaine, dates, nombre de tickets
    - Top 3 scopes par semaine
    - Répartition par statut par semaine (tableau avec nombre et pourcentage)
    - Points notables (tendances, pics, anomalies)

## Labels Scope

Les labels de type Scope à tracker : Interface pro, Projet/Devis, Paiements, GED, Signature, Notifications, Interventions, CRM, Offre commerciale, Admin Pro, Admin Revel'Home, Agenda, Moteur de recherche, Revel'Home, Statut.

## Règles

- Utiliser Python (via Bash) pour traiter les données JSON volumineuses avec jq/python3
- Sauvegarder les résultats intermédiaires dans `/tmp/` pour éviter de surcharger le contexte
- Afficher des barres visuelles (█) pour les pourcentages
- La semaine en cours doit être marquée "(en cours)"
- Être concis dans le résumé, aller droit au but
