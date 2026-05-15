#!/usr/bin/env bash
# OpenCode Agent Team — One-shot installer for Linux / macOS / WSL
#
# Usage:
#   bash install.sh                    # install/update from current dir (after git clone)
#   curl -fsSL <raw-url> | bash        # remote install (clones to a temp dir)

set -euo pipefail

REPO_URL="https://github.com/Wievondii/opencode-agent-team.git"
OC_DIR="${HOME}/.config/opencode"
AGENT_DST="${OC_DIR}/agents"
TPL_DST="${OC_DIR}/templates"
TEAM_DST="${OC_DIR}/agent-team"

log()  { printf '\033[1;34m[agent-team]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[agent-team]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[agent-team]\033[0m %s\n' "$*" >&2; exit 1; }

# ── 1. Resolve source dir ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)"

if [[ -d "${SCRIPT_DIR}/agents" && -d "${SCRIPT_DIR}/templates" ]]; then
  SRC_DIR="${SCRIPT_DIR}"
  log "Installing from local checkout: ${SRC_DIR}"
else
  command -v git >/dev/null 2>&1 || die "git is required but not installed."
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT
  log "Cloning ${REPO_URL} into ${TMP_DIR} ..."
  git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/opencode-agent-team" >/dev/null
  SRC_DIR="${TMP_DIR}/opencode-agent-team"
fi

# ── 2. Verify source layout ───────────────────────────────────────────────────
for f in agents/pm.md agents/planner.md agents/developer.md agents/reviewer.md agents/tester.md \
         templates/agent-team-log.md templates/dev-workspace.md \
         agent-team/boulder.json; do
  [[ -f "${SRC_DIR}/${f}" ]] || die "Missing source file: ${f}"
done

# ── 3. Install ────────────────────────────────────────────────────────────────
mkdir -p "${AGENT_DST}" "${TPL_DST}" "${TEAM_DST}"

log "Copying agents → ${AGENT_DST}"
cp -f "${SRC_DIR}"/agents/*.md "${AGENT_DST}/"

log "Copying templates → ${TPL_DST}"
cp -f "${SRC_DIR}"/templates/*.md "${TPL_DST}/"

# Only seed boulder.json if it doesn't already exist (preserves user state)
if [[ -f "${TEAM_DST}/boulder.json" ]]; then
  warn "Preserving existing ${TEAM_DST}/boulder.json (state would otherwise be reset)"
else
  log "Seeding ${TEAM_DST}/boulder.json"
  cp -f "${SRC_DIR}/agent-team/boulder.json" "${TEAM_DST}/boulder.json"
fi

# ── 4. Done ───────────────────────────────────────────────────────────────────
log "✅ Installed."
log "Next steps:"
log "  1. Open OpenCode in any project."
log "  2. Press Tab and select the 'pm' agent."
log "  3. Describe your feature; the team takes it from there."
