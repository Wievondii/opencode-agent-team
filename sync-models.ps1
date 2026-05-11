# sync-models.ps1 - Agent Team 模型同步脚本
# 用法：.\sync-models.ps1 [-ConfigPath <path>]
# 从 team-config.json 读取模型配置，同步到运行时目录
# 只操作 ~/.config/opencode/ 和 ~/.claude/，不碰仓库源文件

param(
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

# ── 路径（只操作运行时目录）──
$OC_AGENTS = Join-Path $env:USERPROFILE ".config\opencode\agents"
$CLAUDE_AGENTS = Join-Path $env:USERPROFILE ".claude\agents"
$OC_JSON = Join-Path $env:USERPROFILE ".config\opencode\opencode.json"
$OC_TEAM = Join-Path $env:USERPROFILE ".config\opencode\agent-team"

if ($ConfigPath -eq "") {
    $ConfigPath = Join-Path $OC_TEAM "team-config.json"
}

# ── Read config ──
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Config not found: $ConfigPath" -ForegroundColor Red
    Write-Host "Run install.ps1 first, or edit team-config.json" -ForegroundColor Yellow
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

# ── Update .md frontmatter ──
function Update-AgentMd {
    param([string]$AgentName, [string]$NewModel, [string]$Dir)

    $file = Join-Path $Dir "$AgentName.md"
    if (-not (Test-Path $file)) {
        Write-Host "  [SKIP] $file not found" -ForegroundColor Yellow
        return
    }

    $content = Get-Content $file -Raw -Encoding UTF8

    if ($content -match '(?m)^(model:\s*)(.+)$') {
        $oldModel = $Matches[2].Trim()
        if ($oldModel -eq $NewModel) {
            Write-Host "  [OK] $AgentName -> $NewModel (unchanged)" -ForegroundColor Green
            return
        }
        $content = $content -replace '(?m)^(model:\s*)(.+)$', "`${1}$NewModel"
        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  [UPDATE] $AgentName : $oldModel -> $NewModel" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] No model: line in $AgentName.md" -ForegroundColor Yellow
    }
}

Write-Host "-- Agent .md files --" -ForegroundColor Cyan
Write-Host ""

$models.PSObject.Properties | ForEach-Object {
    $name = $_.Name
    $model = $_.Value

    Write-Host "[$name] -> $model" -ForegroundColor White
    Update-AgentMd -AgentName $name -NewModel $model -Dir $OC_AGENTS
    Update-AgentMd -AgentName $name -NewModel $model -Dir $CLAUDE_AGENTS
}

# ── Update opencode.json ──
Write-Host ""
Write-Host "-- opencode.json --" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $OC_JSON)) {
    Write-Host "  [SKIP] opencode.json not found" -ForegroundColor Yellow
} else {
    $ocConfig = Get-Content $OC_JSON -Raw | ConvertFrom-Json

    $models.PSObject.Properties | ForEach-Object {
        $name = $_.Name
        $model = $_.Value

        if ($ocConfig.agent.$name) {
            $oldModel = $ocConfig.agent.$name.model
            if ($oldModel -eq $model) {
                Write-Host "  [OK] agent.${name} -> $model (unchanged)" -ForegroundColor Green
            } else {
                $ocConfig.agent.$name.model = $model
                Write-Host "  [UPDATE] agent.${name} : $oldModel -> $model" -ForegroundColor Green
            }
        } else {
            Write-Host "  [SKIP] agent.${name} not in opencode.json" -ForegroundColor Yellow
        }
    }

    $json = $ocConfig | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($OC_JSON, $json, [System.Text.Encoding]::UTF8)
}

# ── Done ──
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sync done! Restart OpenCode." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
