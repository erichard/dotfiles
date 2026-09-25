---
name: support-ticket
description: "Instruit un ticket de support de bout en bout : synthèse du ticket, diagnostic externe et code via l'agent analyste, décision, commentaire Linear en brouillon, puis bascule vers un correctif ou clôture sans suite. À invoquer pour diagnostiquer un ticket de support, une anomalie signalée, un « pourquoi ça a fait ça »."
---

Tu instruis un **ticket de support**, du signalement à la décision. Le but n'est pas de corriger —
c'est de comprendre, documenter, et choisir la suite. La correction elle-même, si elle a lieu, est un
travail distinct qui commence après ce skill, pas dedans.

## L'invariant qui gouverne ce skill

Le contexte principal ne lit **jamais** directement les logs, Sentry ou le code applicatif — il
délègue la collecte à l'agent `analyste` en **un seul appel** et se contente ensuite de synthétiser et
décider. Et le commentaire Linear de la phase 4 est **toujours un brouillon soumis à validation**,
jamais posté d'initiative : cf. la préférence semi-auto (correction silencieuse de l'indicatif
DOM-TOM, RVH-1951/2058) — un commentaire mal posé sur un ticket client est aussi difficile à expliquer
qu'une donnée réécrite en silence.

## Phase 0 — Lancer le workspace

Avant toute lecture : si la session tourne sous herdr (`$HERDR_ENV = 1`), promouvoir le pane courant
en workspace dédié à ce ticket, plutôt que de rester dans le workspace ambiant.

```bash
[ "${HERDR_ENV:-}" = "1" ] && herdr pane move "$HERDR_PANE_ID" --new-workspace \
    --label "<ticket>" --tab-label "<ticket>" --focus
```

Pas de worktree à ce stade : les phases 1 à 4 sont en lecture seule, elles restent sur le checkout
principal (`worktrees.md`). Le worktree n'apparaît qu'en phase 5, si la décision est un correctif —
et c'est l'outil `EnterWorktree`, pas `herdr worktree create`, qui le crée : lui seul déclenche le
provisioning Docker/composer/pnpm du hook `WorktreeCreate`. Hors herdr (`$HERDR_ENV` absent), sauter
cette phase sans le signaler — ce n'est pas un échec, juste un contexte différent.

## Phase 1 — Synthèse du ticket

Lire le ticket (`mcp__claude_ai_Linear__get_issue`) et ses commentaires
(`mcp__claude_ai_Linear__list_comments`). En tirer : ce qui est signalé, par qui (contact ou
organisation), depuis quand, et le contexte déjà apporté par le support ou le client. Charger
`linear-conventions` si un rôle ou un label doit être interprété — ne jamais déduire un rôle d'un
prénom.

## Phase 2 — Diagnostic externe et code, en un appel à l'agent analyste

Un seul appel à l'agent `analyste`, avec un prompt autonome : la synthèse de la phase 1, la question
précise à trancher, et les pistes déjà connues (organisation/projet concerné, période, symptôme). Le
skill `observabilite` porte les identifiants de sources s'il faut les rappeler dans le prompt — mais
c'est l'agent qui les charge, pas le contexte principal.

L'agent est en **lecture seule** : il collecte et corrèle (logs BetterStack, erreurs Sentry, requêtes
`prod-db-query`, lecture de code si la piste le demande), il ne modifie rien. Son rapport revient sous
forme de preuves + hypothèse de cause, pas de correctif.

## Phase 3 — Collecte, synthèse et décision

Croiser la synthèse du ticket et le rapport de l'agent. Trancher explicitement l'un des deux cas :

| Décision              | Quand                                                                      |
|------------------------|------------------------------------------------------------------------------|
| **Sans suite**         | comportement attendu, cas non reproductible, déjà couvert par un correctif existant |
| **Correctif / amélioration** | bug confirmé, ou piste d'amélioration pour fiabiliser un futur diagnostic (ex. log manquant) |

Une décision sans preuve à l'appui n'est pas une décision — si le rapport de l'agent ne tranche pas,
le dire et proposer un complément d'investigation plutôt que de trancher à l'aveugle.

## Phase 4 — Commentaire Linear, en brouillon

Rédiger le commentaire : synthèse du symptôme, preuve retenue, décision et sa justification. Le
présenter à Erwan **avant** tout envoi. Une fois validé (tel quel ou amendé), poster avec
`mcp__claude_ai_Linear__save_comment` et ajuster le statut si la convention l'exige — `linear-conventions`
porte les IDs de statut.

## Phase 5 — Bifurcation

- **Sans suite** : le ticket se ferme sur ce commentaire. Rien d'autre à faire.
- **Correctif ou amélioration** : la suite sort de ce skill et entre dans le gradient habituel — pour
  une correction de bug, directement à l'implémentation (table du `CLAUDE.md` racine). Le rappeler à
  Erwan plutôt que d'enchaîner seul : c'est le point où une nouvelle tâche démarre (worktree, éventuel
  espace de travail dédié), une décision qui lui revient.
