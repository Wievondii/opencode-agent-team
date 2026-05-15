# OpenCode Agent Team — One-shot installer for Windows (PowerShell 5+)
#
# Usage:
#   .\install.ps1                                                  # local checkout
#   irm https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.ps1 | iex

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/Wievondii/opencode-agent-team.git'
$OcDir   = Join-Path $env:USERPROFILE '.config\opencode'
$AgentDst = Join-Path $OcDir 'agents'
$TplDst   = Join-Path $OcDir 'templates'
$TeamDst  = Join-Path $OcDir 'agent-team'

function Write-Step($msg)  { Write-Host "[agent-team] $msg" -ForegroundColor Cyan }
function Write-Warn2($msg) { Write-Host "[agent-team] $msg" -ForegroundColor Yellow }
function Write-Err2($msg)  { Write-Host "[agent-team] $msg" -ForegroundColor Red }

# ── 1. Resolve source dir ────────────────────────────────────────────────────
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$SrcDir = $null
$TmpDir = $null

if ((Test-Path (Join-Path $ScriptDir 'agents')) -and (Test-Path (Join-Path $ScriptDir 'templates'))) {
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
    'templates\agent-team-log.md', 'templates\dev-workspace.md',
    'agent-team\boulder.json'
)
foreach ($f in $Required) {
    if (-not (Test-Path (Join-Path $SrcDir $f))) {
        Write-Err2 "Missing source file: $f"
        if ($TmpDir -and (Test-Path $TmpDir)) { Remove-Item -Recurse -Force $TmpDir }
        exit 1
    }
}

# ── 3. Install ────────────────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $AgentDst, $TplDst, $TeamDst | Out-Null

Write-Step "Copying agents → $AgentDst"
Copy-Item -Force (Join-Path $SrcDir 'agents\*.md') $AgentDst

Write-Step "Copying templates → $TplDst"
Copy-Item -Force (Join-Path $SrcDir 'templates\*.md') $TplDst

$BoulderDst = Join-Path $TeamDst 'boulder.json'
if (Test-Path $BoulderDst) {
    Write-Warn2 "Preserving existing $BoulderDst (state would otherwise be reset)"
}
else {
    Write-Step "Seeding $BoulderDst"
    Copy-Item -Force (Join-Path $SrcDir 'agent-team\boulder.json') $BoulderDst
}

if ($TmpDir -and (Test-Path $TmpDir)) { Remove-Item -Recurse -Force $TmpDir }

# ── 4. Done ───────────────────────────────────────────────────────────────────
Write-Step '✅ Installed.'
Write-Step 'Next steps:'
Write-Step '  1. Open OpenCode in any project.'
Write-Step "  2. Press Tab and select the 'pm' agent."
Write-Step '  3. Describe your feature; the team takes it from there.'
