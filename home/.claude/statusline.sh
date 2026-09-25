#!/usr/bin/env bash
# Statusline Claude Code : repo, branche git, jauge de contexte (gradient truecolor),
# coût de session, vélocité de code, modèle. Ne doit jamais échouer bruyamment.

input=$(cat 2>/dev/null)
[ -z "$input" ] && input='{}'

jqr() { jq -r "$1" 2>/dev/null <<<"$input"; }

RESET=$'\033[0m'
BOLD=$'\033[1m'
color() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

DIM_GRAY=$(color 110 110 110)
SEP="${DIM_GRAY} | ${RESET}"

# --- Dépôt & branche -----------------------------------------------------
cwd=$(jqr '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd="$PWD"
project_dir=$(jqr '.workspace.project_dir // empty')
[ -z "$project_dir" ] && project_dir="$cwd"

repo=$(jqr '.workspace.repo.name // empty')
[ -z "$repo" ] && repo=$(basename "$project_dir" 2>/dev/null)
[ -z "$repo" ] && repo="?"

branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

# --- Pourcentage de contexte (plusieurs sources de repli) ----------------
pct_raw=$(jqr '.context_window.used_percentage // empty')

if [ -z "$pct_raw" ] || [ "$pct_raw" = "null" ]; then
    total=$(jqr '.context_window.total_input_tokens // empty')
    size=$(jqr '.context_window.context_window_size // empty')
    if [ -n "$total" ] && [ -n "$size" ] && [ "$size" != "null" ] && [ "$size" != "0" ]; then
        pct_raw=$(awk -v t="$total" -v s="$size" 'BEGIN{printf "%.2f", (t/s)*100}' 2>/dev/null)
    fi
fi

if [ -z "$pct_raw" ] || [ "$pct_raw" = "null" ]; then
    transcript=$(jqr '.transcript_path // empty')
    if [ -n "$transcript" ] && [ -f "$transcript" ]; then
        tokens=$(tail -n 200 "$transcript" 2>/dev/null \
            | jq -r 'select(.message.usage) | .message.usage | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)' 2>/dev/null \
            | tail -n 1)
        if [ -n "$tokens" ]; then
            pct_raw=$(awk -v t="$tokens" 'BEGIN{printf "%.2f", (t/200000)*100}' 2>/dev/null)
        fi
    fi
fi

if [ -z "$pct_raw" ] || [ "$pct_raw" = "null" ]; then
    exceeds=$(jqr '.exceeds_200k_tokens // false')
    [ "$exceeds" = "true" ] && pct_raw=100 || pct_raw=0
fi

pct=$(awk -v p="$pct_raw" 'BEGIN{
    v = (p == "" ? 0 : p + 0)
    if (v < 0) v = 0
    if (v > 100) v = 100
    printf "%.0f", v
}' 2>/dev/null)
[ -z "$pct" ] && pct=0

# --- Palier (emoji + couleur du pourcentage) ------------------------------
if [ "$pct" -lt 20 ]; then
    emoji="🟢"; tr=0;   tg=200; tb=80
elif [ "$pct" -lt 70 ]; then
    emoji="⚡"; tr=220; tg=200; tb=0
elif [ "$pct" -lt 90 ]; then
    emoji="🔥"; tr=230; tg=120; tb=20
else
    emoji="🚨"; tr=220; tg=40;  tb=20
fi
pct_color=$(color "$tr" "$tg" "$tb")

# --- Barre de contexte : 20 blocs, gradient vert -> jaune -> rouge -------
bar=$(awk -v pct="$pct" -v block="█" -v empty=" " 'BEGIN{
    blocks = 20
    filled = int((pct / 100) * blocks + 0.5)
    if (filled > blocks) filled = blocks
    if (filled < 0) filled = 0
    out = ""
    for (i = 1; i <= blocks; i++) {
        if (i <= filled) {
            t = (blocks > 1) ? (i - 1) / (blocks - 1) : 1
            if (t <= 0.5) {
                t2 = t / 0.5
                r = int(0 + t2 * 220)
                g = 200
                b = int(80 - t2 * 80)
            } else {
                t2 = (t - 0.5) / 0.5
                r = 220
                g = int(200 - t2 * 160)
                b = int(t2 * 20)
            }
            out = out sprintf("\033[38;2;%d;%d;%dm%s", r, g, b, block)
        } else {
            out = out empty
        }
    }
    out = out "\033[0m"
    print out
}' 2>/dev/null)

# --- Coût de session -------------------------------------------------------
cost_raw=$(jqr '.cost.total_cost_usd // empty')
cost_fmt=$(awk -v c="$cost_raw" 'BEGIN{printf "%.2f", (c == "" ? 0 : c + 0)}' 2>/dev/null)
[ -z "$cost_fmt" ] && cost_fmt="0.00"

# --- Vélocité de code --------------------------------------------------
added=$(jqr '.cost.total_lines_added // 0')
case "$added" in (''|*[!0-9]*) added=0 ;; esac
removed=$(jqr '.cost.total_lines_removed // 0')
case "$removed" in (''|*[!0-9]*) removed=0 ;; esac

# --- Modèle -----------------------------------------------------------
model=$(jqr '.model.display_name // empty')
[ -z "$model" ] && model="?"

# --- Assemblage des segments ---------------------------------------------
YELLOW=$(color 230 200 30)
CYAN=$(color 0 200 200)
GREEN=$(color 0 200 80)
RED=$(color 220 40 20)
MAGENTA=$(color 200 60 200)

repo_seg="${BOLD}${YELLOW}${repo}${RESET}"
context_seg="${bar} ${pct_color}${emoji} ${pct}%${RESET}"
cost_seg="${YELLOW}\$${cost_fmt}${RESET}"
velocity_seg="${GREEN}+${added}${RESET} ${RED}-${removed}${RESET}"
model_seg="🤖 ${MAGENTA}${model}${RESET}"

segments=("$repo_seg")
[ -n "$branch" ] && segments+=("${BOLD}${CYAN}🌿 (${branch})${RESET}")
segments+=("$context_seg" "$cost_seg" "$velocity_seg" "$model_seg")

output=""
for i in "${!segments[@]}"; do
    if [ "$i" -eq 0 ]; then
        output="${segments[$i]}"
    else
        output="${output}${SEP}${segments[$i]}"
    fi
done

printf '%s\n' "$output"
