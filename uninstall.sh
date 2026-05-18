#!/usr/bin/env bash
# OpenCode Agent Team v2.0 — Uninstaller for Linux / macOS / WSL
set -euo pipefail

OC_DIR="${HOME}/.config/opencode"

log() { printf '\033[1;34m[agent-team]\033[0m %s\n' "$*"; }

log "Removing agent files ..."
for f in pm planner developer reviewer tester; do
  rm -f "${OC_DIR}/agents/${f}.md"
done

log "Removing template files ..."
# v2 templates
for f in agent-team-log-index.md dev-workspace.md \
         round-plan.md round-review.md round-test.md round-integration.md; do
  rm -f "${OC_DIR}/templates/${f}"
done
# v2 notepad templates
rm -rf "${OC_DIR}/templates/notepads"
# v1 leftover (if still present)
rm -f "${OC_DIR}/templates/agent-team-log.md"

log "Removing agent-team state directory (boulder/events/schemas/scripts/rounds) ..."
rm -rf "${OC_DIR}/agent-team"

log "✅ Uninstalled."
log "Tip: project-level .opencode/ folders are untouched; remove them manually if desired."
