# Installation Guide

> 🇨🇳 中文版与英文版安装步骤一致，下面用中英对照写一遍并附**故障排查**。

## Prerequisites · 前置条件

- [OpenCode](https://opencode.ai) installed and runnable from terminal.
- `git` available on `PATH` (the installer uses it for the remote-install path).
- Linux / macOS / WSL → `bash`. Windows → PowerShell 5+.

> ❌ **No npm required.** This project is not distributed via npm. Any `npm install` command you may have seen in older docs is obsolete.
> ❌ **不需要 npm。** 此项目不再以 npm 包形式分发，旧文档中的 `npm install` 指令已废弃。

---

## Quick Install · 快速安装

**Linux / macOS / WSL**

```bash
curl -fsSL https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.ps1 | iex
```

The installer:

1. Clones this repo to a temp directory (skipped if you already cloned and ran the script locally).
2. Copies `agents/*.md` → `~/.config/opencode/agents/`.
3. Copies `templates/*.md` → `~/.config/opencode/templates/`.
4. Seeds `agent-team/boulder.json` → `~/.config/opencode/agent-team/boulder.json` (only on first install — your runtime state is preserved on re-runs).
5. Cleans up the temp directory.

---

## Verify · 验证安装

```bash
ls ~/.config/opencode/agents/         # → pm.md planner.md developer.md reviewer.md tester.md
ls ~/.config/opencode/templates/      # → agent-team-log.md dev-workspace.md
ls ~/.config/opencode/agent-team/     # → boulder.json
```

Open OpenCode in any project, press `Tab`, you should see `pm` (and the four subagents) in the picker.

---

## Update · 更新

Just re-run the installer. It overwrites `agents/` and `templates/` but preserves `boulder.json` so your team state survives the upgrade.

```bash
curl -fsSL https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.sh | bash
```

If you want a hard reset of state too, delete `boulder.json` first:

```bash
rm ~/.config/opencode/agent-team/boulder.json
# then re-run the installer
```

---

## Uninstall · 卸载

```bash
# Linux / macOS / WSL
bash uninstall.sh

# Windows (PowerShell)
powershell -File uninstall.ps1
```

The uninstaller removes the 5 agent files, the 2 template files, and the `~/.config/opencode/agent-team/` directory.

It deliberately leaves project-level `.opencode/` folders alone — those are user-owned runtime data. Remove them yourself if you want.

---

## OpenCode global config · OpenCode 全局配置

`~/.config/opencode/opencode.json` should at minimum allow git commands so the Reviewer can `git add` / `git commit`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "bash": {
      "git*": "allow"
    }
  }
}
```

See `opencode-sample.json` in the repo for the example used during development.

---

## Troubleshooting · 故障排查

### `pm` 不出现在 OpenCode 的 agent 列表里 · `pm` agent doesn't show up in OpenCode

1. Confirm the files exist:
   ```bash
   ls ~/.config/opencode/agents/pm.md
   ```
2. Make sure OpenCode is reading from `~/.config/opencode/`. Some packaged builds use a different XDG path; check OpenCode's logs / docs.
3. Restart OpenCode.

### Reviewer 报权限错误，无法 `git commit` · Reviewer can't run git commands

Add the `permission.bash."git*": "allow"` entry to `~/.config/opencode/opencode.json` (see "Recommended OpenCode global config" above), then restart OpenCode.

### 安装脚本提示找不到 git · Installer says git is missing

```bash
# Debian / Ubuntu
sudo apt install git

# macOS
brew install git

# Windows
winget install --id Git.Git -e
```

### 模型不可用 · Model unavailable

The shipped defaults reference `xiaomi-token-plan-cn/mimo-v2.5(-pro)` and `opencode/deepseek-v4-flash-free`. If your OpenCode setup doesn't have those, edit each agent file under `~/.config/opencode/agents/` and change the `model:` line in frontmatter to a model your install does have (e.g. `anthropic/claude-opus-4`, `openai/gpt-4o`, etc).

### Windows: PowerShell 执行策略报错 · Execution policy blocks the script

Run PowerShell as your user (not admin) and either:

```powershell
# one-shot bypass
powershell -ExecutionPolicy Bypass -File install.ps1

# or persistently allow signed remote scripts
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 我装错了想从头来 · I want to start fresh

```bash
bash uninstall.sh        # or powershell -File uninstall.ps1
rm -rf ~/.config/opencode/agent-team
# re-run the installer
```
