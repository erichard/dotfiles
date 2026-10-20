---
name: scw-tem
description: "Interroger Scaleway Transactional Email (TEM) via `scw tem` : retrouver un email envoyé à une adresse, lire son statut et ses tentatives SMTP, compter les échecs, vérifier la blocklist ou l'état DNS d'un domaine. À charger dès qu'on se demande si un email est parti, pourquoi un client ne l'a pas reçu, s'il a rebondi, ou combien d'emails ont échoué."
---

Scaleway TEM envoie les emails transactionnels de Revel'Home. `scw` est installé par Home Manager et
déjà authentifié (`~/.config/scw/config.yaml`, région `fr-par`, projet par défaut). Ce skill ne
couvre que `scw tem`.

## Le piège : jamais de liste sans filtre

Le volume tourne autour de **16 000 emails par jour**. `scw tem email list` sans filtre pagine
**tout** l'historique, et même une heure de trafic suffit à dépasser le timeout. Toujours restreindre
par un critère sélectif :

- `mail-rcpt=<adresse>`, le cas courant (répond en moins d'une seconde) ;
- `message-id=<id>` ou `subject=<sujet exact>` ;
- `since`/`until` en ISO 8601 UTC, avec des fenêtres de quelques minutes si c'est le seul filtre.

Même règle pour `get-statistics` : sans `since`, l'appel tourne dans le vide.

Toujours passer `-o json` et réduire avec `jq` : la sortie `human` tronque les tentatives.

## Recettes

```bash
# Emails envoyés à une adresse sur 7 jours
scw tem email list mail-rcpt=client@example.com since=$(date -u -d '-7 day' +%FT%TZ) \
  order-by=created_at_desc -o json \
  | jq '.[] | {id, created_at, subject, status, status_details, flags}'

# Détail d'un email : tentatives SMTP et réponse du serveur distant
scw tem email get <email-id> -o json | jq '{status, status_details, try_count, flags, last_tries}'

# Échecs récents (statuses et flags sont des listes indexées)
scw tem email list statuses.0=failed since=$(date -u -d '-15 min' +%FT%TZ) -o json \
  | jq '.[] | {created_at, mail_rcpt, subject, status_details, flags}'

# File bloquée ? Emails en attente par domaine destinataire. Un seul domaine qui domine
# (orange.fr + wanadoo.fr, même MX) = le fournisseur nous limite : chercher son code 421 dans last_tries
scw tem email list statuses.0=sending since=$(date -u -d '-3 hour' +%FT%TZ) -o json \
  | jq -r '.[] | "\(.mail_rcpt | split("@")[1]) \(.status_details)"' | sort | uniq -c | sort -rn

# Compteurs sur 24 h
scw tem email get-statistics since=$(date -u -d '-1 day' +%FT%TZ)

# L'adresse est-elle bloquée (rebond dur, boîte pleine) ? domain-id obligatoire : tester les deux
for d in 0496edbf-ec43-4e3f-a03e-dfc9e6bf98cb f144bbfc-0a51-4e2f-8082-ee4025d9a476; do
  scw tem blocklists list domain-id=$d email=client@example.com -o json
done

# Santé DNS d'un domaine (SPF, DKIM, DMARC, MX)
scw tem domain list -o json | jq -r '.[] | "\(.id) \(.name) \(.status)"'
scw tem domain get-last-status <domain-id>
```

Domaines d'envoi : `revelhome.app` (`0496edbf-ec43-4e3f-a03e-dfc9e6bf98cb`) et `pro.revelhome.app`
(`f144bbfc-0a51-4e2f-8082-ee4025d9a476`).

## Lire le résultat

- `status` : `new` → `sending` → `sent`, ou `failed` / `canceled`. `sending` qui dure, c'est un
  serveur distant qui temporise (greylisting, retries) : regarder `last_tries`.
- `last_tries[].code` et `.message` : la réponse SMTP du serveur du destinataire, la preuve à citer.
  `250` veut dire **accepté par le serveur distant**, pas lu ni arrivé en boîte de réception : un
  `sent` qui n'est pas arrivé se cherche côté spam ou filtrage du destinataire.
- `flags` : `hard_bounce`, `mailbox_not_found`, `blocklisted`, `spam`… expliquent un échec sans qu'on
  ait à interpréter le code SMTP.

Pour découvrir une sous-commande : `scw tem --list-sub-commands`, puis `scw tem <cmd> --help`.

## Écritures : confirmer d'abord

Lecture libre. Toute écriture se fait **après accord explicite d'Erwan**, commande montrée avant :

- `email create` envoie un vrai email à une vraie personne ;
- `email cancel`, `blocklists create|delete`, `domain revoke|update`, `webhook create|update|delete`
  modifient la production.

Les emails contiennent des adresses et des sujets de clients : n'en recopier dans Linear ou Slack que
ce que le diagnostic exige.
