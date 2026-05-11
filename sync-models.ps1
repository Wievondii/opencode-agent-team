# sync-models.ps1 - Agent Team 模型同步脚本
# 用法：.\sync-models.ps1 [-ConfigPath <path>]
# 从 team-config.json 读取模型配置，同步到 agent .md 文件
# 只操作 ~/.config/opencode/agents/ 和 ~/.claude/agents/

param(
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

$OC_AGENTS = Join-Path $env:USERPROFILE ".config\opencode\agents"
$CLAUDE_AGENTS = Join-Path $env:USERPROFILE ".claude\agents"
$OC_TEAM = Join-Path $env:USERPROFILE ".config\opencode\agent-team"

if ($ConfigPath -eq "") {
    $ConfigPath = Join-Path $OC_TEAM "team-config.json"
}

if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Config not found: $ConfigPath" -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$models = $config.models

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Agent Team - Model Sync" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Config: $ConfigPath" -ForegroundColor Gray
Write-Host ""

function Update-AgentMd {
    param([string]$AgentName, [string]$NewModel, [string]$Dir)

    $file = Join-Path $Dir "$AgentName.md"
    if (-not (Test-Path $file)) {
        Write-Host "  [SKIP] $AgentName.md not found" -ForegroundColor Yellow
        return
    }

    $content = Get-Content $file -Raw -Encoding UTF8

    if ($content -match '(?m)^(model:\s*)(.+)$') {
        $oldModel = $Matches[2].Trim()
        if ($oldModel -eq $NewModel) {
            Write-Host "  [OK] $AgentName -> $NewModel" -ForegroundColor Green
            return
        }
        $content = $content -replace '(?m)^(model:\s*)(.+)$', "`${1}$NewModel"
        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  [UPDATE] $AgentName : $oldModel -> $NewModel" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] No model: line in $AgentName.md" -ForegroundColor Yellow
    }
}

Write-Host "-- Syncing agent models --" -ForegroundColor Cyan
Write-Host ""

$models.PSObject.Properties | ForEach-Object {
    $name = $_.Name
    $model = $_.Value

    Write-Host "[$name] -> $model" -ForegroundColor White
    Update-AgentMd -AgentName $name -NewModel $model -Dir $OC_AGENTS
    Update-AgentMd -AgentName $name -NewModel $model -Dir $CLAUDE_AGENTS
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sync done! Restart OpenCode." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
