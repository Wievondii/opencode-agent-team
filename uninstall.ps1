# OpenCode Agent Team v2.0 — Uninstaller for Windows
$ErrorActionPreference = 'Stop'

$OcDir = Join-Path $env:USERPROFILE '.config\opencode'

function Write-Step($msg) { Write-Host "[agent-team] $msg" -ForegroundColor Cyan }

Write-Step 'Removing agent files ...'
foreach ($f in @('pm', 'planner', 'developer', 'reviewer', 'tester')) {
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OcDir "agents\$f.md")
}

Write-Step 'Removing template files ...'
$v2Templates = @(
    'agent-team-log-index.md', 'dev-workspace.md',
    'round-plan.md', 'round-review.md', 'round-test.md', 'round-integration.md'
)
foreach ($f in $v2Templates) {
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OcDir "templates\$f")
}
# v2 notepad templates
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $OcDir 'templates\notepads')
# v1 leftover (if still present)
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $OcDir 'templates\agent-team-log.md')

Write-Step 'Removing agent-team state directory (boulder/events/schemas/scripts/rounds) ...'
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $OcDir 'agent-team')

Write-Step '✅ Uninstalled.'
Write-Step 'Tip: project-level .opencode/ folders are untouched; remove them manually if desired.'
