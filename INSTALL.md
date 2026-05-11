# 安装指南

## 前置条件

- Windows 10/11
- PowerShell 5.1+
- [OpenCode](https://opencode.ai) 已安装

## 安装步骤

### 1. 获取插件

**压缩包方式：**
- 下载 zip 文件，解压到任意目录

**Git 方式：**
```powershell
git clone https://github.com/Wievondii/opencode-agent-team.git
```

### 2. 运行安装脚本

打开 PowerShell，进入插件目录：

```powershell
cd D:\opencode-agent-team  # 或你解压的目录
.\install.ps1
```

安装脚本会：
- 复制 agent 文件到 `~/.config/opencode/agents/` 和 `~/.claude/agents/`
- 复制插件代码到 `~/.config/opencode/plugins/agent-team/`
- 复制配置文件到 `~/.config/opencode/agent-team/`
- 更新 `opencode.json`（添加 plugin 引用和 agent 定义）

### 3. 重启 OpenCode

关闭并重新打开 OpenCode。

### 4. 使用

按 `Tab` 键选择 `pm`（项目经理），然后描述你的需求。

## 更改模型

默认模型为 `xiaomi-token-plan-cn/mimo-v2.5-pro`。如需更改：

1. 编辑 `~/.config/opencode/agent-team/team-config.json`：

```json
{
  "models": {
    "pm": "你的模型",
    "planner": "你的模型",
    "developer": "你的模型",
    "reviewer": "你的模型",
    "tester": "你的模型"
  }
}
```

2. 运行同步：

```powershell
powershell ~/.config/opencode/agent-team/sync-models.ps1
```

3. 重启 OpenCode

## 卸载

删除以下目录：

```powershell
Remove-Item ~/.config/opencode/plugins/agent-team -Recurse -Force
Remove-Item ~/.config/opencode/agent-team -Recurse -Force
Remove-Item ~/.config/opencode/templates/comm-log.md -Force
# Agent 文件可保留，不影响其他功能
```

从 `~/.config/opencode/opencode.json` 的 `plugin` 数组中移除 `~/.config/opencode/plugins/agent-team`。
