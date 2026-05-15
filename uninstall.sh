#!/usr/bin/env bash
# OpenCode Agent Team — Uninstaller for Linux / macOS / WSL
set -euo pipefail

OC_DIR="${HOME}/.config/opencode"

log()  { printf '\033[1;34m[agent-team]\033[0m %s\n' "$*"; }

log "Removing agent files ..."
for f in pm planner developer reviewer tester; do
  rm -f "${OC_DIR}/agents/${f}.md"
done

log "Removing template files ..."
for f in agent-team-log.md dev-workspace.md; do
  rm -f "${OC_DIR}/templates/${f}"
done

log "Removing agent-team state directory ..."
rm -rf "${OC_DIR}/agent-team"

log "✅ Uninstalled."
log "Tip: project-level .opencode/ folders are untouched; remove them manually if desired."
