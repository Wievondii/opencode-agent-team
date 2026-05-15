# OpenCode Agent Team — Uninstaller for Windows
$ErrorActionPreference = 'Stop'

$OcDir = Join-Path $env:USERPROFILE '.config\opencode'

function Write-Step($msg) { Write-Host "[agent-team] $msg" -ForegroundColor Cyan }

Write-Step 'Removing agent files ...'
foreach ($f in @('pm', 'planner', 'developer', 'reviewer', 'tester')) {
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OcDir "agents\$f.md")
}

Write-Step 'Removing template files ...'
foreach ($f in @('agent-team-log.md', 'dev-workspace.md')) {
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OcDir "templates\$f")
}

Write-Step 'Removing agent-team state directory ...'
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $OcDir 'agent-team')

Write-Step '✅ Uninstalled.'
Write-Step 'Tip: project-level .opencode/ folders are untouched; remove them manually if desired.'
