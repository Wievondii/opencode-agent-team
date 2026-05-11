@echo off
chcp 65001 >nul
echo ============================================
echo   OpenCode Agent Team - 一键配置
echo ============================================
echo.

set "SRC=%~dp0"
set "CLAUDE=%USERPROFILE%\.claude"
set "OC=%USERPROFILE%\.config\opencode"

echo [1/5] 创建目录...
mkdir "%CLAUDE%\agents" 2>nul
mkdir "%CLAUDE%\commands" 2>nul
mkdir "%OC%\templates" 2>nul
mkdir "%OC%\agent-team" 2>nul

echo [2/5] 复制 Agent 文件...
copy /Y "%SRC%agents\*.md" "%CLAUDE%\agents\" >nul
copy /Y "%SRC%commands\*.md" "%CLAUDE%\commands\" >nul

echo [3/5] 复制模板和配置...
copy /Y "%SRC%templates\agent-team-log.md" "%OC%\templates\comm-log.md" >nul
copy /Y "%SRC%agent-team\boulder.json" "%OC%\agent-team\" >nul

echo [4/5] 复制模型配置...
copy /Y "%SRC%team-config.json" "%OC%\agent-team\" >nul
copy /Y "%SRC%sync-models.ps1" "%OC%\agent-team\" >nul

echo [5/5] 配置 opencode.json...
if exist "%OC%\opencode.json" (
    echo.
    echo ⚠️  opencode.json 已存在，请手动在 "agent" 段添加以下内容：
    echo.
    echo   "pm":      { "mode":"primary", "model":"你的模型名", "temperature":0.2 },
    echo   "planner":  { "mode":"subagent", "model":"你的模型名", "temperature":0.2 },
    echo   "developer":{ "mode":"subagent", "model":"你的模型名", "temperature":0.3 },
    echo   "reviewer": { "mode":"subagent", "model":"你的模型名", "temperature":0.2 },
    echo   "tester":   { "mode":"subagent", "model":"你的模型名", "temperature":0.2 }
    echo.
) else (
    copy /Y "%SRC%opencode-sample.json" "%OC%\opencode.json" >nul
    echo   已创建 opencode.json
)

echo.
echo ============================================
echo   配置完成！
echo.
echo   重启 OpenCode -^> 按 Tab 选 pm -^> 开始使用
echo.
echo   更改模型：编辑 team-config.json 后运行 sync-models.ps1
echo   位置：%OC%\agent-team\team-config.json
echo   同步：powershell %OC%\agent-team\sync-models.ps1
echo ============================================
pause
