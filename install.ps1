# install.ps1 - Agent Team 安装脚本
# 用法：.\install.ps1
# 从仓库目录安装到 OpenCode 和 Claude Code 运行时目录
# 安装后 opencode.json 不再引用仓库路径

param()

$ErrorActionPreference = "Stop"

# ── 路径 ──
$SRC = Split-Path -Parent $MyInvocation.MyCommand.Path
$OC = Join-Path $env:USERPROFILE ".config\opencode"
$CLAUDE = Join-Path $env:USERPROFILE ".claude"
$PLUGIN_DIR = Join-Path $OC "plugins\agent-team"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Agent Team - Install" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: $SRC" -ForegroundColor Gray
Write-Host "Target: $OC" -ForegroundColor Gray
Write-Host ""

# ── 1. Create directories ──
Write-Host "[1/6] Creating directories..." -ForegroundColor Yellow

$dirs = @(
    (Join-Path $OC "agents"),
    (Join-Path $OC "templates"),
    (Join-Path $OC "agent-team"),
    (Join-Path $OC "plugins"),
    (Join-Path $CLAUDE "agents"),
    (Join-Path $CLAUDE "commands")
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "  Created: $d" -ForegroundColor Gray
    }
}

# ── 2. Copy agents ──
Write-Host "[2/6] Copying agent files..." -ForegroundColor Yellow

$agentFiles = Get-ChildItem (Join-Path $SRC "agents") -Filter "*.md" -ErrorAction SilentlyContinue
if ($agentFiles) {
    foreach ($f in $agentFiles) {
        Copy-Item $f.FullName (Join-Path $OC "agents\$($f.Name)") -Force
        Copy-Item $f.FullName (Join-Path $CLAUDE "agents\$($f.Name)") -Force
        Write-Host "  $($f.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No agent files found in agents/" -ForegroundColor Yellow
}

# ── 3. Copy commands ──
Write-Host "[3/6] Copying command files..." -ForegroundColor Yellow

$cmdFiles = Get-ChildItem (Join-Path $SRC "commands") -Filter "*.md" -ErrorAction SilentlyContinue
if ($cmdFiles) {
    foreach ($f in $cmdFiles) {
        Copy-Item $f.FullName (Join-Path $CLAUDE "commands\$($f.Name)") -Force
        Write-Host "  $($f.Name)" -ForegroundColor Gray
    }
}

# ── 4. Copy templates and config ──
Write-Host "[4/6] Copying templates and config..." -ForegroundColor Yellow

# Templates
$tplFiles = Get-ChildItem (Join-Path $SRC "templates") -Filter "*.md" -ErrorAction SilentlyContinue
if ($tplFiles) {
    foreach ($f in $tplFiles) {
        Copy-Item $f.FullName (Join-Path $OC "templates\$($f.Name)") -Force
        Write-Host "  templates/$($f.Name)" -ForegroundColor Gray
    }
}

# boulder.json
$boulderSrc = Join-Path $SRC "agent-team\boulder.json"
if (Test-Path $boulderSrc) {
    Copy-Item $boulderSrc (Join-Path $OC "agent-team\boulder.json") -Force
    Write-Host "  agent-team/boulder.json" -ForegroundColor Gray
}

# team-config.json
$configSrc = Join-Path $SRC "team-config.json"
if (Test-Path $configSrc) {
    Copy-Item $configSrc (Join-Path $OC "agent-team\team-config.json") -Force
    Write-Host "  agent-team/team-config.json" -ForegroundColor Gray
}

# sync-models.ps1
$syncSrc = Join-Path $SRC "sync-models.ps1"
if (Test-Path $syncSrc) {
    Copy-Item $syncSrc (Join-Path $OC "agent-team\sync-models.ps1") -Force
    Write-Host "  agent-team/sync-models.ps1" -ForegroundColor Gray
}

# ── 5. Install plugin ──
Write-Host "[5/6] Installing plugin..." -ForegroundColor Yellow

if (Test-Path $PLUGIN_DIR) {
    Remove-Item $PLUGIN_DIR -Recurse -Force
}

# Copy plugin code
New-Item -ItemType Directory -Path $PLUGIN_DIR -Force | Out-Null
Copy-Item (Join-Path $SRC "src\*") $PLUGIN_DIR -Recurse -Force
Copy-Item (Join-Path $SRC "package.json") $PLUGIN_DIR -Force
Write-Host "  Plugin installed to: $PLUGIN_DIR" -ForegroundColor Gray

# ── 6. Update opencode.json ──
Write-Host "[6/6] Updating opencode.json..." -ForegroundColor Yellow

$ocJsonPath = Join-Path $OC "opencode.json"
$pluginRef = "~/.config/opencode/plugins/agent-team"

if (Test-Path $ocJsonPath) {
    $config = Get-Content $ocJsonPath -Raw | ConvertFrom-Json

    # Update plugin reference
    if (-not $config.plugin) {
        $config | Add-Member -NotePropertyName "plugin" -NotePropertyValue @()
    }

    # Remove old repo references and add new plugin path
    $newPlugins = @()
    foreach ($p in $config.plugin) {
        if ($p -match "oc-team" -or $p -match "D:\\\\repositories") {
            Write-Host "  Removed old plugin ref: $p" -ForegroundColor Gray
        } else {
            $newPlugins += $p
        }
    }
    $newPlugins += $pluginRef
    $config.plugin = $newPlugins

    # Ensure agent section exists
    if (-not $config.agent) {
        $config | Add-Member -NotePropertyName "agent" -NotePropertyValue ([ordered]@{})
    }

    # Add missing agent definitions
    $agentDefs = @{
        "pm" = @{ mode="primary"; temperature=0.2 }
        "planner" = @{ mode="subagent"; temperature=0.2 }
        "developer" = @{ mode="subagent"; temperature=0.3 }
        "reviewer" = @{ mode="subagent"; temperature=0.2 }
        "tester" = @{ mode="subagent"; temperature=0.2 }
    }

    # Read models from team-config.json
    $teamConfigPath = Join-Path $OC "agent-team\team-config.json"
    if (Test-Path $teamConfigPath) {
        $teamConfig = Get-Content $teamConfigPath -Raw | ConvertFrom-Json
    }

    foreach ($name in $agentDefs.Keys) {
        if (-not $config.agent.$name) {
            $agentDef = $agentDefs[$name].Clone()
            $agentDef["model"] = $teamConfig.models.$name
            $config.agent | Add-Member -NotePropertyName $name -NotePropertyValue $agentDef
            Write-Host "  Added agent: $name" -ForegroundColor Gray
        } else {
            Write-Host "  Agent exists: $name" -ForegroundColor Gray
        }
    }

    # Write back
    $json = $config | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($ocJsonPath, $json, [System.Text.Encoding]::UTF8)
    Write-Host "  opencode.json updated" -ForegroundColor Green
} else {
    # Create new opencode.json from sample
    $samplePath = Join-Path $SRC "opencode-sample.json"
    if (Test-Path $samplePath) {
        $sample = Get-Content $samplePath -Raw | ConvertFrom-Json
        $sample.plugin = @($pluginRef)
        $json = $sample | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($ocJsonPath, $json, [System.Text.Encoding]::UTF8)
        Write-Host "  opencode.json created" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] No opencode.json and no sample found" -ForegroundColor Yellow
    }
}

# ── Done ──
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Install complete!" -ForegroundColor Green
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
