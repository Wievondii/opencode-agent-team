# pack.ps1 - 创建发布压缩包
# 用法：.\pack.ps1
# 在仓库目录外创建干净的 zip 文件，排除 .git 等无关文件

param()

$ErrorActionPreference = "Stop"

$SRC = Split-Path -Parent $MyInvocation.MyCommand.Path
$OUT = Join-Path (Split-Path $SRC -Parent) "opencode-agent-team.zip"

Write-Host "Creating distribution zip..." -ForegroundColor Cyan

# Remove old zip
if (Test-Path $OUT) {
    Remove-Item $OUT -Force
}

# Create temp dir for clean copy
$TMP = Join-Path $env:TEMP "agent-team-pack"
if (Test-Path $TMP) {
    Remove-Item $TMP -Recurse -Force
}
New-Item -ItemType Directory -Path $TMP -Force | Out-Null

# Copy files (exclude .git, .gitignore, etc.)
$include = @(
    "agents",
    "commands",
    "templates",
    "agent-team",
    "src",
    "install.ps1",
    "sync-models.ps1",
    "team-config.json",
    "package.json",
    "opencode-sample.json",
    "README.md",
    "INSTALL.md"
)

foreach ($item in $include) {
    $srcPath = Join-Path $SRC $item
    if (Test-Path $srcPath) {
        $dstPath = Join-Path $TMP $item
        if (Test-Path $srcPath -PathType Container) {
            Copy-Item $srcPath $dstPath -Recurse -Force
        } else {
            Copy-Item $srcPath $dstPath -Force
        }
    }
}

# Create zip
Compress-Archive -Path "$TMP\*" -DestinationPath $OUT -Force
Remove-Item $TMP -Recurse -Force

$size = (Get-Item $OUT).Length / 1KB
Write-Host ""
Write-Host "Created: $OUT" -ForegroundColor Green
Write-Host "Size: $([math]::Round($size, 1)) KB" -ForegroundColor Gray
Write-Host ""
