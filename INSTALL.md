# 安装指南

## 前置条件

- [OpenCode](https://opencode.ai) 已安装
- Git 已安装

## 安装步骤

### 1. 克隆仓库

```bash
git clone https://github.com/Wievondii/opencode-agent-team.git /tmp/opencode-agent-team
```

### 2. 复制文件

```bash
# Agent 文件（自动加载）
cp /tmp/opencode-agent-team/agents/*.md ~/.config/opencode/agents/
cp /tmp/opencode-agent-team/agents/*.md ~/.claude/agents/

# 模板文件
cp /tmp/opencode-agent-team/templates/*.md ~/.config/opencode/templates/

# 命令文件（Claude Code）
cp /tmp/opencode-agent-team/commands/*.md ~/.claude/commands/

# 配置文件
mkdir -p ~/.config/opencode/agent-team
cp /tmp/opencode-agent-team/agent-team/boulder.json ~/.config/opencode/agent-team/
cp /tmp/opencode-agent-team/team-config.json ~/.config/opencode/agent-team/
```

### 3. 配置 opencode.json

如果 `~/.config/opencode/opencode.json` 不存在，创建最小配置：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": { "bash": { "git*": "allow" } },
  "shell": "powershell"
}
```

### 4. 清理

```bash
rm -rf /tmp/opencode-agent-team
```

### 5. 使用

重启 OpenCode，按 `Tab` 选择 `pm`。

## 更改模型

编辑 `~/.config/opencode/agents/` 下对应 agent 的 .md 文件，修改 frontmatter 中的 `model` 字段。

## 卸载

```bash
rm ~/.config/opencode/agents/pm.md
rm ~/.config/opencode/agents/planner.md
rm ~/.config/opencode/agents/developer.md
rm ~/.config/opencode/agents/reviewer.md
rm ~/.config/opencode/agents/tester.md
rm ~/.config/opencode/templates/agent-team-log.md
rm ~/.config/opencode/templates/dev-workspace.md
rm -rf ~/.config/opencode/agent-team
rm ~/.claude/agents/pm.md
rm ~/.claude/agents/planner.md
rm ~/.claude/agents/developer.md
rm ~/.claude/agents/reviewer.md
rm ~/.claude/agents/tester.md
rm ~/.claude/commands/agent-team.md
```
