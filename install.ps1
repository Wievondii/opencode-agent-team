# install.ps1 - Agent Team 安装脚本
# 用法：.\install.ps1
# 将 agent 文件和插件安装到 OpenCode 运行时目录
# 不修改 opencode.json 的 agent 配置（agent 由 .md 文件定义）

param()

$ErrorActionPreference = "Stop"

$SRC = Split-Path -Parent $MyInvocation.MyCommand.Path
$OC = Join-Path $env:USERPROFILE ".config\opencode"
$CLAUDE = Join-Path $env:USERPROFILE ".claude"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Agent Team - Install" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: $SRC" -ForegroundColor Gray
Write-Host ""

# ── 1. Create directories ──
Write-Host "[1/5] Creating directories..." -ForegroundColor Yellow

$dirs = @(
    (Join-Path $OC "agents"),
    (Join-Path $OC "plugins\agent-team"),
    (Join-Path $OC "templates"),
    (Join-Path $OC "agent-team"),
    (Join-Path $CLAUDE "agents"),
    (Join-Path $CLAUDE "commands")
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "  Created: $d" -ForegroundColor Gray
    }
}

# ── 2. Copy agent .md files ──
Write-Host "[2/5] Copying agent files..." -ForegroundColor Yellow

$agentFiles = Get-ChildItem (Join-Path $SRC "agents") -Filter "*.md" -ErrorAction SilentlyContinue
if ($agentFiles) {
    foreach ($f in $agentFiles) {
        Copy-Item $f.FullName (Join-Path $OC "agents\$($f.Name)") -Force
        Copy-Item $f.FullName (Join-Path $CLAUDE "agents\$($f.Name)") -Force
        Write-Host "  $($f.Name)" -ForegroundColor Gray
    }
}

# ── 3. Copy commands ──
Write-Host "[3/5] Copying commands..." -ForegroundColor Yellow

$cmdFiles = Get-ChildItem (Join-Path $SRC "commands") -Filter "*.md" -ErrorAction SilentlyContinue
if ($cmdFiles) {
    foreach ($f in $cmdFiles) {
        Copy-Item $f.FullName (Join-Path $CLAUDE "commands\$($f.Name)") -Force
        Write-Host "  $($f.Name)" -ForegroundColor Gray
    }
}

# ── 4. Copy templates, config, plugin ──
Write-Host "[4/5] Copying templates and plugin..." -ForegroundColor Yellow

# Templates
$tplFiles = Get-ChildItem (Join-Path $SRC "templates") -Filter "*.md" -ErrorAction SilentlyContinue
if ($tplFiles) {
    foreach ($f in $tplFiles) {
        Copy-Item $f.FullName (Join-Path $OC "templates\$($f.Name)") -Force
        Write-Host "  templates/$($f.Name)" -ForegroundColor Gray
    }
}

# Plugin files
$pluginDir = Join-Path $OC "plugins\agent-team"
Copy-Item (Join-Path $SRC "src\*") $pluginDir -Recurse -Force
Copy-Item (Join-Path $SRC "package.json") $pluginDir -Force
Write-Host "  plugins/agent-team/" -ForegroundColor Gray

# Config files
$boulderSrc = Join-Path $SRC "agent-team\boulder.json"
if (Test-Path $boulderSrc) {
    Copy-Item $boulderSrc (Join-Path $OC "agent-team\boulder.json") -Force
}

$configSrc = Join-Path $SRC "team-config.json"
if (Test-Path $configSrc) {
    Copy-Item $configSrc (Join-Path $OC "agent-team\team-config.json") -Force
}

$syncSrc = Join-Path $SRC "sync-models.ps1"
if (Test-Path $syncSrc) {
    Copy-Item $syncSrc (Join-Path $OC "agent-team\sync-models.ps1") -Force
}

Write-Host "  agent-team/ config files" -ForegroundColor Gray

# ── 5. Create opencode.json if missing ──
Write-Host "[5/5] Checking opencode.json..." -ForegroundColor Yellow

$ocJsonPath = Join-Path $OC "opencode.json"
if (-not (Test-Path $ocJsonPath)) {
    # Create minimal config with just global settings
    $samplePath = Join-Path $SRC "opencode-sample.json"
    if (Test-Path $samplePath) {
        Copy-Item $samplePath $ocJsonPath -Force
        Write-Host "  Created opencode.json from sample" -ForegroundColor Green
    } else {
        # Create absolute minimal config
        $minimal = @{
            '$schema' = 'https://opencode.ai/config.json'
            permission = @{
                bash = @{ 'git*' = 'allow' }
            }
        }
        $minimal | ConvertTo-Json -Depth 10 | Set-Content $ocJsonPath -Encoding UTF8
        Write-Host "  Created minimal opencode.json" -ForegroundColor Green
    }
} else {
    Write-Host "  opencode.json exists, not modified" -ForegroundColor Green
}

# ── Done ──
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Install complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Agents are auto-loaded from:" -ForegroundColor White
Write-Host "    $OC\agents\" -ForegroundColor Gray
Write-Host ""
Write-Host "  Plugin is auto-loaded from:" -ForegroundColor White
Write-Host "    $OC\plugins\agent-team\" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Restart OpenCode" -ForegroundColor White
Write-Host "    2. Tab -> select pm" -ForegroundColor White
Write-Host ""
Write-Host "  Change models:" -ForegroundColor White
Write-Host "    Edit: $OC\agent-team\team-config.json" -ForegroundColor White
Write-Host "    Run:  powershell $OC\agent-team\sync-models.ps1" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
