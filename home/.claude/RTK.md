# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `pnpm install` → `rtk pnpm install` (transparent, 0 tokens overhead)

⚠️ **Exception : `git`.** `git` s'exécute toujours nu, jamais via `rtk` — une session Claude Code
isolée en worktree refuse toute commande `git` qu'elle soupçonne de passer par un wrapper non
vérifiable. Vaut aussi dans les chaînes `&&`.

Refer to CLAUDE.md for full command reference.
