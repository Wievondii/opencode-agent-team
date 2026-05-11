# sync-models.ps1 - Agent Team 模型同步脚本
# 用法：.\sync-models.ps1 [-ConfigPath <path>]
# 从 team-config.json 读取模型配置，同步到所有 agent 文件和 opencode.json

param(
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

# ── 路径 ──
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($ConfigPath -eq "") {
    $ConfigPath = Join-Path $ScriptDir "team-config.json"
}

$OC_AGENTS = Join-Path $env:USERPROFILE ".config\opencode\agents"
$CLAUDE_AGENTS = Join-Path $env:USERPROFILE ".claude\agents"
$OC_JSON = Join-Path $env:USERPROFILE ".config\opencode\opencode.json"

# ── 读取配置 ──
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] 找不到配置文件: $ConfigPath" -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$models = $config.models

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Agent Team 模型同步" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "配置来源: $ConfigPath" -ForegroundColor Gray
Write-Host ""

# ── 同步 .md frontmatter ──
function Update-AgentMd {
    param([string]$AgentName, [string]$NewModel, [string]$Dir)

    $file = Join-Path $Dir "$AgentName.md"
    if (-not (Test-Path $file)) {
        Write-Host "  [SKIP] $file 不存在" -ForegroundColor Yellow
        return
    }

    $content = Get-Content $file -Raw -Encoding UTF8
    $oldModel = ""

    # 匹配 frontmatter 中的 model: 行（在 --- 之间）
    if ($content -match '(?m)^(model:\s*)(.+)$') {
        $oldModel = $Matches[2].Trim()
        if ($oldModel -eq $NewModel) {
            Write-Host "  [OK] $AgentName.md -> $NewModel (无变化)" -ForegroundColor Green
            return
        }
        $content = $content -replace '(?m)^(model:\s*)(.+)$', "`${1}$NewModel"
        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  [UPDATE] $AgentName.md: $oldModel -> $NewModel" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] $AgentName.md 中未找到 model: 行" -ForegroundColor Yellow
    }
}

Write-Host "── 同步 Agent .md 文件 ──" -ForegroundColor Cyan
Write-Host ""

# 遍历配置中的每个 agent
$models.PSObject.Properties | ForEach-Object {
    $name = $_.Name
    $model = $_.Value

    Write-Host "[$name] -> $model" -ForegroundColor White

    # 更新 ~/.config/opencode/agents/
    Update-AgentMd -AgentName $name -NewModel $model -Dir $OC_AGENTS

    # 更新 ~/.claude/agents/
    Update-AgentMd -AgentName $name -NewModel $model -Dir $CLAUDE_AGENTS
}

# ── 同步 opencode.json ──
Write-Host ""
Write-Host "── 同步 opencode.json ──" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $OC_JSON)) {
    Write-Host "  [SKIP] opencode.json 不存在: $OC_JSON" -ForegroundColor Yellow
} else {
    $ocConfig = Get-Content $OC_JSON -Raw | ConvertFrom-Json

    $models.PSObject.Properties | ForEach-Object {
        $name = $_.Name
        $model = $_.Value

        if ($ocConfig.agent.$name) {
            $oldModel = $ocConfig.agent.$name.model
            if ($oldModel -eq $model) {
                Write-Host "  [OK] opencode.json agent.$name -> $model (无变化)" -ForegroundColor Green
            } else {
                $ocConfig.agent.$name.model = $model
                Write-Host "  [UPDATE] opencode.json agent.${name}: $oldModel -> $model" -ForegroundColor Green
            }
        } else {
            Write-Host "  [SKIP] opencode.json 中无 agent.$name 定义" -ForegroundColor Yellow
        }
    }

    # 写回 opencode.json（保持格式）
    $json = $ocConfig | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($OC_JSON, $json, [System.Text.Encoding]::UTF8)
}

# ── 同步 oc-team/agents/ 源文件 ──
Write-Host ""
Write-Host "── 同步 oc-team 源文件 ──" -ForegroundColor Cyan
Write-Host ""

$RepoAgents = Join-Path $ScriptDir "agents"
if (Test-Path $RepoAgents) {
    $models.PSObject.Properties | ForEach-Object {
        $name = $_.Name
        $model = $_.Value
        Update-AgentMd -AgentName $name -NewModel $model -Dir $RepoAgents
    }
} else {
    Write-Host "  [SKIP] 源文件目录不存在: $RepoAgents" -ForegroundColor Yellow
}

# done
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sync done! Restart OpenCode to apply" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
