# OpenCode Agent Team

协调策划师/开发者/审查员/测试员四个子 agent，通过 Task + task_id 实现持久化开发团队。

## 特性

- **Task + task_id 持久化**：Agent 完成任务后休眠，通过 task_id 唤醒同一会话，上下文完整保留
- **谁犯错谁修复**：错误通过文件归属确定责任 Developer，用 task_id 恢复修复
- **并行开发**：多个 Developer 同时工作，各自写私有日志，零冲突
- **完整工作流**：策划 → 开发 → 集成检查 → 审查 → 测试 → 修复循环

## 安装

### 方式一：npm 包（推荐）

在 `~/.config/opencode/opencode.json` 中添加插件：

```json
{
  "plugin": ["opencode-agent-team"]
}
```

重启 OpenCode，插件会自动：
1. 安装 npm 包
2. 复制 agent 文件到 `~/.config/opencode/agents/`
3. 复制模板文件到 `~/.config/opencode/templates/`
4. 创建 `~/.config/opencode/agent-team/` 配置目录

### 方式二：让 AI Agent 安装

把以下内容发给你的 AI agent：

```
请帮我安装 opencode-agent-team 插件。

在 ~/.config/opencode/opencode.json 的 plugin 数组中添加 "opencode-agent-team"，然后重启 OpenCode。

如果 opencode.json 不存在，创建：
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["opencode-agent-team"],
  "permission": { "bash": { "git*": "allow" } }
}
```

### 方式三：手动安装

```bash
git clone https://github.com/Wievondii/opencode-agent-team.git /tmp/opencode-agent-team
cp /tmp/opencode-agent-team/agents/*.md ~/.config/opencode/agents/
cp /tmp/opencode-agent-team/templates/*.md ~/.config/opencode/templates/
mkdir -p ~/.config/opencode/agent-team
cp /tmp/opencode-agent-team/agent-team/boulder.json ~/.config/opencode/agent-team/
rm -rf /tmp/opencode-agent-team
```

## 使用

1. 按 `Tab` 键选择 `pm`（项目经理）
2. 描述你的需求，例如："帮我创建一个 React 待办事项应用"
3. PM 会自动协调团队完成开发

## 架构

```
PM (项目经理)
├── Planner (策划师) - 制定开发计划
├── Developer (开发者)×N - 并行编写代码
├── Reviewer (审查员) - 代码审查 + git commit
└── Tester (测试员)×N - 并行测试
```

### 工作流程

```
用户需求 → PM → Planner → Developer(s) → 集成检查 → Reviewer → Tester
                                    ↑                    ↓
                                    └── task_id 恢复修复 ←┘
```

### 文件结构

**运行时（自动创建）：**

```
~/.config/opencode/
├── agents/                         # Agent 提示词（自动加载）
│   ├── pm.md
│   ├── planner.md
│   ├── developer.md
│   ├── reviewer.md
│   └── tester.md
├── agent-team/
│   └── boulder.json                # 持久化状态
└── templates/                      # 日志模板
    ├── agent-team-log.md
    └── dev-workspace.md
```

**项目目录（PM 运行时创建）：**

```
<project>/
└── .opencode/
    ├── agent-team-log.md           # 共享日志
    ├── dev-{module}.md             # Developer 私有日志
    └── notepads/                   # 学习成果
```

## 更新插件

删除 `~/.config/opencode/agents/pm.md` 等文件，重启 OpenCode → 插件检测到文件不存在 → 自动复制新版本。

或者删除版本文件强制更新：

```bash
rm ~/.config/opencode/agent-team/.opencode-agent-team-version
```

## 更改模型

编辑 `~/.config/opencode/agents/` 下对应 agent 的 .md 文件，修改 frontmatter 中的 `model` 字段。

## 许可证

MIT
