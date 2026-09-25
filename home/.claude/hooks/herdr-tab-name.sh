#!/bin/sh
# Renomme la tab herdr courante avec le nom de la session Claude,
# uniquement quand ce nom a été posé manuellement (via /rename).
# Hook maison, à côté de herdr-agent-state.sh (géré par herdr, ne pas éditer).
set -eu

# Consomme le payload du hook (JSON sur stdin) une seule fois.
input="$(cat 2>/dev/null || true)"

# Rien à faire hors d'une tab herdr.
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_TAB_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# Résout le nom de session (matché sur session_id), seulement si nameSource == "user".
# Le payload passe par l'env (HERDR_HOOK_INPUT) : `python3 - <<PY` occupe déjà stdin
# avec le script lui-même, on ne peut donc pas y lire le JSON.
name="$(HERDR_HOOK_INPUT="$input" python3 - <<'PY'
import json, glob, os

try:
    data = json.loads(os.environ.get("HERDR_HOOK_INPUT", ""))
except Exception:
    raise SystemExit(0)

session_id = data.get("session_id")
if not session_id:
    raise SystemExit(0)

for path in glob.glob(os.path.expanduser("~/.claude/sessions/*.json")):
    try:
        with open(path, encoding="utf-8") as handle:
            session = json.load(handle)
    except Exception:
        continue
    if session.get("sessionId") != session_id:
        continue
    if session.get("nameSource") == "user":
        label = session.get("name")
        if isinstance(label, str) and label.strip():
            print(label.strip())
    break
PY
)"

[ -n "$name" ] || exit 0

herdr tab rename "$HERDR_TAB_ID" "$name" >/dev/null 2>&1 || true
exit 0
