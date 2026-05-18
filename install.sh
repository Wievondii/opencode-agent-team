#!/usr/bin/env bash
# OpenCode Agent Team v2.0 — One-shot installer for Linux / macOS / WSL
#
# Usage:
#   bash install.sh                    # install/update from current dir (after git clone)
#   curl -fsSL <raw-url> | bash        # remote install (clones to a temp dir)
#
# v2.0 changes:
#   - Adds agent-team/schemas/ (5 JSON Schema files)
#   - Adds agent-team/scripts/ (validation + event scripts, requires Node 18+)
#   - templates/ now includes round-* and notepads/ subfolders
#   - templates/agent-team-log.md was REMOVED (replaced by agent-team-log-index.md)

set -euo pipefail

REPO_URL="https://github.com/Wievondii/opencode-agent-team.git"
OC_DIR="${HOME}/.config/opencode"
AGENT_DST="${OC_DIR}/agents"
TPL_DST="${OC_DIR}/templates"
TEAM_DST="${OC_DIR}/agent-team"
SCHEMAS_DST="${TEAM_DST}/schemas"
SCRIPTS_DST="${TEAM_DST}/scripts"

log()  { printf '\033[1;34m[agent-team]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[agent-team]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[agent-team]\033[0m %s\n' "$*" >&2; exit 1; }

# ── 0. Check prerequisites ────────────────────────────────────────────────────
if ! command -v node >/dev/null 2>&1; then
  die "Node.js >= 18 is required (for agent-team validation scripts). Install: https://nodejs.org/"
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [[ "${NODE_MAJOR}" -lt 18 ]]; then
  die "Node.js >= 18 is required, found $(node -v)"
fi

# ── 1. Resolve source dir ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)"

if [[ -d "${SCRIPT_DIR}/agents" && -d "${SCRIPT_DIR}/templates" && -d "${SCRIPT_DIR}/agent-team" ]]; then
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
         templates/agent-team-log-index.md templates/dev-workspace.md \
         templates/round-plan.md templates/round-review.md templates/round-test.md \
         templates/round-integration.md \
         templates/notepads/decisions.md templates/notepads/learnings.md \
         templates/notepads/issues.md templates/notepads/verification.md \
         templates/notepads/problems.md \
         agent-team/boulder.json \
         agent-team/schemas/boulder.schema.json \
         agent-team/schemas/dev-log.schema.json \
         agent-team/schemas/round-plan.schema.json \
         agent-team/schemas/bug-report.schema.json \
         agent-team/schemas/boulder-event.schema.json \
         agent-team/scripts/package.json \
         agent-team/scripts/ensure-deps.mjs \
         agent-team/scripts/append-event.mjs \
         agent-team/scripts/rebuild-boulder.mjs \
         agent-team/scripts/check-file-conflicts.mjs \
         agent-team/scripts/check-quality-gates.mjs \
         agent-team/scripts/validate-dev-log.mjs \
         agent-team/scripts/validate-plan.mjs \
         agent-team/scripts/init-project.mjs \
         agent-team/scripts/archive-round.mjs \
         agent-team/scripts/check-task-id-fresh.mjs \
         agent-team/scripts/derive-severity.mjs \
         agent-team/scripts/check-budget.mjs \
         agent-team/scripts/heartbeat.mjs \
         agent-team/scripts/lib/paths.mjs \
         agent-team/scripts/lib/locking.mjs \
         agent-team/scripts/lib/schema-loader.mjs \
         agent-team/scripts/lib/frontmatter.mjs \
         agent-team/scripts/lib/git-helpers.mjs \
         agent-team/scripts/lib/severity-matrix.mjs; do
  [[ -f "${SRC_DIR}/${f}" ]] || die "Missing source file: ${f}"
done

# ── 3. Install ────────────────────────────────────────────────────────────────
mkdir -p "${AGENT_DST}" "${TPL_DST}" "${TPL_DST}/notepads" \
         "${TEAM_DST}" "${SCHEMAS_DST}" "${SCRIPTS_DST}" "${SCRIPTS_DST}/lib"

log "Copying agents → ${AGENT_DST}"
cp -f "${SRC_DIR}"/agents/*.md "${AGENT_DST}/"

# Clean up v1 leftover if present
if [[ -f "${TPL_DST}/agent-team-log.md" ]]; then
  warn "Removing v1 leftover: ${TPL_DST}/agent-team-log.md (replaced by agent-team-log-index.md)"
  rm -f "${TPL_DST}/agent-team-log.md"
fi

log "Copying templates → ${TPL_DST}"
cp -f "${SRC_DIR}"/templates/*.md "${TPL_DST}/"
cp -f "${SRC_DIR}"/templates/notepads/*.md "${TPL_DST}/notepads/"

log "Copying schemas → ${SCHEMAS_DST}"
cp -f "${SRC_DIR}"/agent-team/schemas/*.json "${SCHEMAS_DST}/"

log "Copying scripts → ${SCRIPTS_DST}"
cp -f "${SRC_DIR}"/agent-team/scripts/*.mjs "${SCRIPTS_DST}/"
cp -f "${SRC_DIR}"/agent-team/scripts/package.json "${SCRIPTS_DST}/"
cp -f "${SRC_DIR}"/agent-team/scripts/lib/*.mjs "${SCRIPTS_DST}/lib/"

# Only seed boulder.json if it doesn't already exist (preserves user state)
if [[ -f "${TEAM_DST}/boulder.json" ]]; then
  EXISTING_VER="$(node -e "try{const j=require('${TEAM_DST}/boulder.json');console.log(j.schema_version||'1.x')}catch{console.log('unknown')}")"
  if [[ "${EXISTING_VER}" != "2.0" ]]; then
    warn "Existing boulder.json is ${EXISTING_VER} (v1). Backing up and re-seeding for v2.0."
    cp -f "${TEAM_DST}/boulder.json" "${TEAM_DST}/boulder.json.v1.bak"
    cp -f "${SRC_DIR}/agent-team/boulder.json" "${TEAM_DST}/boulder.json"
  else
    warn "Preserving existing v2.0 ${TEAM_DST}/boulder.json"
  fi
else
  log "Seeding ${TEAM_DST}/boulder.json (v2.0)"
  cp -f "${SRC_DIR}/agent-team/boulder.json" "${TEAM_DST}/boulder.json"
fi

# ── 4. Pre-warm npm dependencies (optional, makes first PM run instant) ───────
log "Pre-installing scripts/ npm dependencies (one-time, ~10s)..."
( cd "${SCRIPTS_DST}" && npm install --no-audit --no-fund --silent ) || \
  warn "npm install failed; PM will retry on first run via ensure-deps.mjs"

# ── 5. Done ───────────────────────────────────────────────────────────────────
log "✅ Installed v2.0."
log "Next steps:"
log "  1. Open OpenCode in any project."
log "  2. Press Tab and select the 'pm' agent."
log "  3. Describe your feature; the team takes it from there."
log ""
log "Migration from v1: see MIGRATION.md (https://github.com/Wievondii/opencode-agent-team/blob/master/MIGRATION.md)"
