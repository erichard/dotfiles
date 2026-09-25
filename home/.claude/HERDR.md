# herdr — gestion des workspaces/onglets

herdr pilote le terminal (workspaces, onglets, panes) via une API socket. Un **workspace dédié par
sujet** (un ticket, une PR) garde chaque fil de travail dans son propre onglet plutôt que d'empiler
les sessions dans un seul workspace fourre-tout.

## Créer un workspace dédié à un sujet

```bash
herdr workspace list
herdr workspace create --cwd /chemin/vers/le/worktree --label "RVH-2695" --focus
```

`--cwd` pointe vers le worktree du sujet (`.claude/worktrees/<nom>`), `--label` porte l'identifiant
du ticket (`RVH-XXXX`) pour le retrouver dans `herdr workspace list`.

## Déplacer l'onglet courant (celui de la session en cours) dans ce workspace

```bash
herdr pane current
herdr pane move <pane_id> --new-tab --workspace <workspace_id> --focus
```

`herdr pane current` donne le `pane_id` de la session qui exécute la commande. `pane move
--new-tab --workspace <id>` migre ce pane dans un nouvel onglet du workspace cible et ferme
l'ancien onglet — la session continue sans interruption, seul son support visuel change.

## Autres commandes utiles

```bash
herdr tab rename <tab_id> <label>       # renommer un onglet
herdr agent list                         # lister les agents actifs par pane
herdr agent focus <target>               # amener le focus sur un agent nommé
```
