@echo off
chcp 65001 >nul
echo ============================================
echo   OpenCode Agent Team - 一键配置
echo ============================================
echo.

set "SRC=%~dp0"
set "CLAUDE=%USERPROFILE%\.claude"
set "OC=%USERPROFILE%\.config\opencode"

echo [1/4] 创建目录...
mkdir "%CLAUDE%\agents" 2>nul
mkdir "%CLAUDE%\commands" 2>nul
mkdir "%OC%\templates" 2>nul
mkdir "%OC%\agent-team" 2>nul

echo [2/4] 复制 Agent 文件...
copy /Y "%SRC%agents\*.md" "%CLAUDE%\agents\" >nul
copy /Y "%SRC%commands\*.md" "%CLAUDE%\commands\" >nul

echo [3/4] 复制模板和配置...
copy /Y "%SRC%templates\agent-team-log.md" "%OC%\templates\comm-log.md" >nul
copy /Y "%SRC%agent-team\boulder.json" "%OC%\agent-team\" >nul

echo [4/4] 配置 opencode.json...
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
    echo   已创建 opencode.json（模型默认 xiaomi-token-plan-sgp/mimo-v2.5-pro，可自行修改）
)

echo.
echo ============================================
echo   配置完成！
echo   重启 OpenCode -^> 按 Tab 选 pm -^> 开始使用
echo ============================================
pause
