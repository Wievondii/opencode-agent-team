<p align="right"><a href="./README.md">简体中文 README</a> · <strong>v2.0</strong></p>

# OpenCode Agent Team

<p align="center">
  <strong>A multi-agent dev team that runs inside OpenCode</strong><br>
  Planner plans · Multiple Developers code in parallel · Reviewer guards quality · Tester verifies · PM orchestrates
</p>

> **v2.0 is a breaking upgrade.** 18 core improvements: 3 independent budgets, 5-class error routing, parallel-write conflict protection, strict YAML frontmatter schemas, append-only event log, etc. Migration: see [MIGRATION.md](./MIGRATION.md). The Chinese [README.md](./README.md) reflects the full v2.0 design; this English README is being progressively updated below.

**Prerequisites:** Node.js >= 18 (required for v2.0 validation scripts), Git, OpenCode.

---

## What is this?

A bundle of [OpenCode](https://opencode.ai) subagent configs that splits the dev workflow across 5 roles:

| Role | Responsibility |
|---|---|
| **PM** | Receives requirements, dispatches the team, maintains the event log + `boulder.json` view, routes errors |
| **Planner** | Analyzes the request, defines interface / style specs + semantic_constraints, splits modules, produces round-plan.md |
| **Developer** ×N | Implements assigned modules **in parallel**; private `dev-{module}.md` with YAML frontmatter; must paste `self_check` evidence |
| **Reviewer** | Two modes: `reviewer` (parallel review, write report only) + `committer` (exclusive `git add` + `git commit`) |
| **Tester** ×N | Runs tests in parallel, classifies bugs as A/B/C/D/E; severity auto-derived from impact × frequency matrix |

**Core mechanics:**
- **task_id persistence** — when the Tester finds a bug, PM wakes the original Developer session via the recorded task_id; full context preserved.
- **Three independent budgets** — `reviewer_rejection` (3) / `bug_fix_a` (3) / `bug_fix_b` (2) + `round_total` (8). Class-B bugs no longer eat the same pool as reviewer rework.
- **Append-only event log** — all boulder.json changes go through `boulder-events.jsonl` + `rebuild-boulder.mjs`; no concurrency races.
- **Hard schema validation** — dev-log / round-plan / bug-report all validated against JSON Schema via Node.js scripts; non-conforming outputs are rejected immediately.
- **Shared-file coordinator** — to prevent parallel write conflicts: shared files get a single `coordinator`; other devs write `shared_file_requests` instead of editing directly. PM enforces with `check-file-conflicts.mjs`.
- **Rollback** — every round starts with `git tag round-N-baseline`; on budget exhaustion, one-click `git reset` is offered.

---

## Install

### Option 1 — One-line remote install (recommended)

**Linux / macOS / WSL:**

```bash
curl -fsSL https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.ps1 | iex
```

### Option 2 — Clone first, install second

```bash
git clone https://github.com/Wievondii/opencode-agent-team.git
cd opencode-agent-team
bash install.sh                     # Linux / macOS / WSL
# or
powershell -File install.ps1        # Windows
```

### Option 3 — Manual copy

```bash
git clone https://github.com/Wievondii/opencode-agent-team.git
cd opencode-agent-team

mkdir -p ~/.config/opencode/agents \
         ~/.config/opencode/templates \
         ~/.config/opencode/agent-team

cp agents/*.md            ~/.config/opencode/agents/
cp templates/*.md         ~/.config/opencode/templates/
cp agent-team/boulder.json ~/.config/opencode/agent-team/    # first time only
```

> ❌ **Do not try `npm install`.** This repo is no longer published as an npm package — that route does not work.

---

## Use

1. Open OpenCode inside any project directory.
2. Press **`Tab`** and pick the `pm` primary agent.
3. Describe what you want, e.g. *"Build me a React todo app with a counter."*
4. The PM runs the full pipeline:

```
You → PM → Planner → Developer×N → Integration check → Reviewer → Tester×N
                                  ↑                                ↓
                                  └─ wake same Developer via task_id
```

The PM creates `.opencode/` inside your project (shared log, each Developer's private log, learning notes) and writes global state to `~/.config/opencode/agent-team/boulder.json`.

---

## Layout

**Repo:**

```
opencode-agent-team/
├── agents/                 # 5 OpenCode subagent definitions
│   ├── pm.md               # primary
│   ├── planner.md
│   ├── developer.md
│   ├── reviewer.md
│   └── tester.md
├── templates/              # Templates the PM/Developers stamp into your project
│   ├── agent-team-log.md
│   └── dev-workspace.md
├── agent-team/
│   └── boulder.json        # Seed for the persistent-state file
├── install.sh / install.ps1
├── uninstall.sh / uninstall.ps1
├── opencode-sample.json    # Example OpenCode global config
├── INSTALL.md              # Install troubleshooting
├── README.md / README.en.md
└── LICENSE
```

**Installed on the user machine:**

```
~/.config/opencode/
├── agents/                 # OpenCode auto-loads these roles
│   ├── pm.md
│   ├── planner.md
│   ├── developer.md
│   ├── reviewer.md
│   └── tester.md
├── templates/
│   ├── agent-team-log.md
│   └── dev-workspace.md
└── agent-team/
    └── boulder.json        # Cross-session persistent state
```

**At runtime (PM creates these inside your project):**

```
your-project/
└── .opencode/
    ├── agent-team-log.md         # Shared cross-agent log
    ├── dev-{module}.md           # Per-Developer private log
    └── notepads/                 # Long-lived learnings
```

---

## Customizing models

Each agent's `model:` field in its frontmatter is the model name. Edit after install:

```bash
$EDITOR ~/.config/opencode/agents/reviewer.md
# Change e.g.
#   model: xiaomi-token-plan-cn/mimo-v2.5-pro
# to
#   model: anthropic/claude-opus-4
```

Default models (as shipped):

| Role | Model |
|---|---|
| PM | `opencode/deepseek-v4-flash-free` (lightweight orchestrator) |
| Planner | `xiaomi-token-plan-cn/mimo-v2.5-pro` |
| Developer | `xiaomi-token-plan-cn/mimo-v2.5-pro` |
| Reviewer | `xiaomi-token-plan-cn/mimo-v2.5-pro` |
| Tester | `xiaomi-token-plan-cn/mimo-v2.5` |

---

## Update

Just re-run the installer — it overwrites `agents/` and `templates/` but **preserves** `boulder.json` so your runtime state isn't reset:

```bash
curl -fsSL https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.sh | bash
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/uninstall.sh | bash
# or local:
bash uninstall.sh
powershell -File uninstall.ps1
```

The script does not delete project-level `.opencode/` folders — `rm -rf` them manually if you want.

---

## Recommended OpenCode global config

`~/.config/opencode/opencode.json` should at minimum allow git commands so the Reviewer can `git add` / `git commit`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "bash": {
      "git*": "allow"
    }
  }
}
```

A full example lives in [`opencode-sample.json`](./opencode-sample.json).

---

## Key design decisions

1. **Tool whitelisting in `tools:` frontmatter** — hard role-permission boundaries, not prompt-level "please don't" hints.
2. **Reviewer commits, not Developer** — only reviewed code reaches the repo.
3. **`task_id` persistence** — bug fixes resume the original Developer session; no need to rebuild context from logs.
4. **PM never reads private logs** — keeps PM's context window lean and avoids cross-role pollution.
5. **3-iteration hard cap** — prevents runaway dev↔review and test↔fix loops; escalates to the user.
6. **Bug taxonomy: A in-module / B cross-module** — decides whether a bug returns to a Developer or to the Planner.

---

## License

[MIT](./LICENSE)
