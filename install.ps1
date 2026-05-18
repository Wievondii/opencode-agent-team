# OpenCode Agent Team v2.0 — One-shot installer for Windows (PowerShell 5+)
#
# Usage:
#   .\install.ps1                                                  # local checkout
#   irm https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.ps1 | iex
#
# v2.0 changes:
#   - Adds agent-team/schemas/ (5 JSON Schema files)
#   - Adds agent-team/scripts/ (validation + event scripts, requires Node 18+)
#   - templates/ now includes round-* and notepads/ subfolders
#   - templates/agent-team-log.md was REMOVED (replaced by agent-team-log-index.md)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoUrl    = 'https://github.com/Wievondii/opencode-agent-team.git'
$OcDir      = Join-Path $env:USERPROFILE '.config\opencode'
$AgentDst   = Join-Path $OcDir 'agents'
$TplDst     = Join-Path $OcDir 'templates'
$TplNotepads= Join-Path $TplDst 'notepads'
$TeamDst    = Join-Path $OcDir 'agent-team'
$SchemasDst = Join-Path $TeamDst 'schemas'
$ScriptsDst = Join-Path $TeamDst 'scripts'
$ScriptsLibDst = Join-Path $ScriptsDst 'lib'

function Write-Step($msg)  { Write-Host "[agent-team] $msg" -ForegroundColor Cyan }
function Write-Warn2($msg) { Write-Host "[agent-team] $msg" -ForegroundColor Yellow }
function Write-Err2($msg)  { Write-Host "[agent-team] $msg" -ForegroundColor Red }

# ── 0. Check prerequisites ────────────────────────────────────────────────────
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Err2 'Node.js >= 18 is required (for agent-team validation scripts). Install: https://nodejs.org/'
    exit 1
}
$NodeVersionRaw = (& node --version).Trim()
$NodeMajor = ($NodeVersionRaw -replace '^v', '' -split '\.')[0]
if ([int]$NodeMajor -lt 18) {
    Write-Err2 ("Node.js >= 18 is required, found {0}" -f $NodeVersionRaw)
    exit 1
}

# ── 1. Resolve source dir ────────────────────────────────────────────────────
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$SrcDir = $null
$TmpDir = $null

if ((Test-Path (Join-Path $ScriptDir 'agents')) -and
    (Test-Path (Join-Path $ScriptDir 'templates')) -and
    (Test-Path (Join-Path $ScriptDir 'agent-team'))) {
    $SrcDir = $ScriptDir
    Write-Step "Installing from local checkout: $SrcDir"
}
else {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Err2 'git is required but not installed.'
        exit 1
    }
    $TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("opencode-agent-team-" + [guid]::NewGuid())
    Write-Step "Cloning $RepoUrl into $TmpDir ..."
    git clone --depth 1 $RepoUrl (Join-Path $TmpDir 'opencode-agent-team') | Out-Null
    $SrcDir = Join-Path $TmpDir 'opencode-agent-team'
}

# ── 2. Verify source layout ───────────────────────────────────────────────────
$Required = @(
    'agents\pm.md', 'agents\planner.md', 'agents\developer.md',
    'agents\reviewer.md', 'agents\tester.md',
    'templates\agent-team-log-index.md', 'templates\dev-workspace.md',
    'templates\round-plan.md', 'templates\round-review.md',
    'templates\round-test.md', 'templates\round-integration.md',
    'templates\notepads\decisions.md', 'templates\notepads\learnings.md',
    'templates\notepads\issues.md', 'templates\notepads\verification.md',
    'templates\notepads\problems.md',
    'agent-team\boulder.json',
    'agent-team\schemas\boulder.schema.json',
    'agent-team\schemas\dev-log.schema.json',
    'agent-team\schemas\round-plan.schema.json',
    'agent-team\schemas\bug-report.schema.json',
    'agent-team\schemas\boulder-event.schema.json',
    'agent-team\scripts\package.json',
    'agent-team\scripts\ensure-deps.mjs',
    'agent-team\scripts\append-event.mjs',
    'agent-team\scripts\rebuild-boulder.mjs',
    'agent-team\scripts\check-file-conflicts.mjs',
    'agent-team\scripts\check-quality-gates.mjs',
    'agent-team\scripts\validate-dev-log.mjs',
    'agent-team\scripts\validate-plan.mjs',
    'agent-team\scripts\init-project.mjs',
    'agent-team\scripts\archive-round.mjs',
    'agent-team\scripts\check-task-id-fresh.mjs',
    'agent-team\scripts\derive-severity.mjs',
    'agent-team\scripts\check-budget.mjs',
    'agent-team\scripts\heartbeat.mjs',
    'agent-team\scripts\lib\paths.mjs',
    'agent-team\scripts\lib\locking.mjs',
    'agent-team\scripts\lib\schema-loader.mjs',
    'agent-team\scripts\lib\frontmatter.mjs',
    'agent-team\scripts\lib\git-helpers.mjs',
    'agent-team\scripts\lib\severity-matrix.mjs'
)
foreach ($f in $Required) {
    if (-not (Test-Path (Join-Path $SrcDir $f))) {
        Write-Err2 "Missing source file: $f"
        if ($TmpDir -and (Test-Path $TmpDir)) { Remove-Item -Recurse -Force $TmpDir }
        exit 1
    }
}

# ── 3. Install ────────────────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $AgentDst, $TplDst, $TplNotepads, `
                                          $TeamDst, $SchemasDst, $ScriptsDst, $ScriptsLibDst | Out-Null

Write-Step "Copying agents → $AgentDst"
Copy-Item -Force (Join-Path $SrcDir 'agents\*.md') $AgentDst

# Clean up v1 leftover if present
$LegacyLog = Join-Path $TplDst 'agent-team-log.md'
if (Test-Path $LegacyLog) {
    Write-Warn2 "Removing v1 leftover: $LegacyLog (replaced by agent-team-log-index.md)"
    Remove-Item -Force $LegacyLog
}

Write-Step "Copying templates → $TplDst"
Copy-Item -Force (Join-Path $SrcDir 'templates\*.md') $TplDst
Copy-Item -Force (Join-Path $SrcDir 'templates\notepads\*.md') $TplNotepads

Write-Step "Copying schemas → $SchemasDst"
Copy-Item -Force (Join-Path $SrcDir 'agent-team\schemas\*.json') $SchemasDst

Write-Step "Copying scripts → $ScriptsDst"
Copy-Item -Force (Join-Path $SrcDir 'agent-team\scripts\*.mjs') $ScriptsDst
Copy-Item -Force (Join-Path $SrcDir 'agent-team\scripts\package.json') $ScriptsDst
Copy-Item -Force (Join-Path $SrcDir 'agent-team\scripts\lib\*.mjs') $ScriptsLibDst

$BoulderDst = Join-Path $TeamDst 'boulder.json'
if (Test-Path $BoulderDst) {
    $ExistingVer = 'unknown'
    try {
        $boulder = Get-Content -Raw $BoulderDst | ConvertFrom-Json -ErrorAction Stop
        if ($boulder.schema_version) { $ExistingVer = [string]$boulder.schema_version } else { $ExistingVer = '1.x' }
    } catch {
        $ExistingVer = 'unknown'
    }
    if ($ExistingVer -ne '2.0') {
        Write-Warn2 "Existing boulder.json is $ExistingVer (v1). Backing up and re-seeding for v2.0."
        Copy-Item -Force $BoulderDst (Join-Path $TeamDst 'boulder.json.v1.bak')
        Copy-Item -Force (Join-Path $SrcDir 'agent-team\boulder.json') $BoulderDst
    }
    else {
        Write-Warn2 "Preserving existing v2.0 $BoulderDst"
    }
}
else {
    Write-Step "Seeding $BoulderDst (v2.0)"
    Copy-Item -Force (Join-Path $SrcDir 'agent-team\boulder.json') $BoulderDst
}

# ── 4. Pre-warm npm dependencies ──────────────────────────────────────────────
Write-Step 'Pre-installing scripts/ npm dependencies (one-time, ~10s)...'
$prevLoc = Get-Location
try {
    Set-Location $ScriptsDst
    & npm install --no-audit --no-fund --silent
    if ($LASTEXITCODE -ne 0) {
        Write-Warn2 "npm install failed; PM will retry on first run via ensure-deps.mjs"
    }
}
finally {
    Set-Location $prevLoc
}

if ($TmpDir -and (Test-Path $TmpDir)) { Remove-Item -Recurse -Force $TmpDir }

# ── 5. Done ───────────────────────────────────────────────────────────────────
Write-Step '✅ Installed v2.0.'
Write-Step 'Next steps:'
Write-Step '  1. Open OpenCode in any project.'
Write-Step "  2. Press Tab and select the 'pm' agent."
Write-Step '  3. Describe your feature; the team takes it from there.'
Write-Step ''
Write-Step 'Migration from v1: see MIGRATION.md (https://github.com/Wievondii/opencode-agent-team/blob/master/MIGRATION.md)'
