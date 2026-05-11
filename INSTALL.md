# 安装指南

## 前置条件

- [OpenCode](https://opencode.ai) 已安装

## 安装步骤

### npm 包安装（推荐）

1. 编辑 `~/.config/opencode/opencode.json`，在 `plugin` 数组中添加：

```json
{
  "plugin": ["opencode-agent-team"]
}
```

2. 重启 OpenCode

插件会自动：
- 安装 npm 包
- 复制 agent 文件到 `~/.config/opencode/agents/`
- 复制模板文件到 `~/.config/opencode/templates/`
- 创建 `~/.config/opencode/agent-team/` 配置目录

3. 按 `Tab` 键选择 `pm` 开始使用

## 更新

删除 `~/.config/opencode/agents/pm.md` 等文件，重启 OpenCode。

或删除版本文件强制更新：

```bash
rm ~/.config/opencode/agent-team/.opencode-agent-team-version
```

## 更改模型

编辑 `~/.config/opencode/agents/` 下对应 agent 的 .md 文件，修改 frontmatter 中的 `model` 字段。

## 卸载

1. 从 `opencode.json` 的 `plugin` 数组中移除 `"opencode-agent-team"`

2. 删除相关文件：

```bash
rm ~/.config/opencode/agents/pm.md
rm ~/.config/opencode/agents/planner.md
rm ~/.config/opencode/agents/developer.md
rm ~/.config/opencode/agents/reviewer.md
rm ~/.config/opencode/agents/tester.md
rm ~/.config/opencode/templates/agent-team-log.md
rm ~/.config/opencode/templates/dev-workspace.md
rm -rf ~/.config/opencode/agent-team
```
