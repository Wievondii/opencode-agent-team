# OpenCode Agent Team

协调策划师/开发者/审查员/测试员四个子 agent，通过 Task + task_id 实现持久化开发团队。

## 特性

- **Task + task_id 持久化**：Agent 完成任务后休眠，通过 task_id 唤醒同一会话，上下文完整保留
- **谁犯错谁修复**：错误通过文件归属确定责任 Developer，用 task_id 恢复修复
- **并行开发**：多个 Developer 同时工作，各自写私有日志，零冲突
- **完整工作流**：策划 → 开发 → 集成检查 → 审查 → 测试 → 修复循环

## 安装

### 方式一：让 AI Agent 自动安装（推荐）

把以下内容发给你的 AI agent：

```
请帮我安装 opencode-agent-team 插件。

执行以下步骤：

1. 克隆仓库：
   git clone https://github.com/Wievondii/opencode-agent-team.git /tmp/opencode-agent-team

2. 创建目录：
   mkdir -p ~/.config/opencode/agents
   mkdir -p ~/.config/opencode/templates
   mkdir -p ~/.config/opencode/agent-team
   mkdir -p ~/.claude/agents
   mkdir -p ~/.claude/commands

3. 复制 agent 文件：
   cp /tmp/opencode-agent-team/agents/*.md ~/.config/opencode/agents/
   cp /tmp/opencode-agent-team/agents/*.md ~/.claude/agents/

4. 复制模板文件：
   cp /tmp/opencode-agent-team/templates/*.md ~/.config/opencode/templates/

5. 复制命令文件：
   cp /tmp/opencode-agent-team/commands/*.md ~/.claude/commands/

6. 复制配置文件：
   cp /tmp/opencode-agent-team/agent-team/boulder.json ~/.config/opencode/agent-team/
   cp /tmp/opencode-agent-team/team-config.json ~/.config/opencode/agent-team/

7. 如果 ~/.config/opencode/opencode.json 不存在，创建一个最小配置：
   {
     "$schema": "https://opencode.ai/config.json",
     "permission": { "bash": { "git*": "allow" } },
     "shell": "powershell"
   }

8. 清理临时文件：
   rm -rf /tmp/opencode-agent-team

9. 提示用户重启 OpenCode，然后按 Tab 选择 pm
```

### 方式二：手动安装

```bash
git clone https://github.com/Wievondii/opencode-agent-team.git /tmp/opencode-agent-team
cp /tmp/opencode-agent-team/agents/*.md ~/.config/opencode/agents/
cp /tmp/opencode-agent-team/agents/*.md ~/.claude/agents/
cp /tmp/opencode-agent-team/templates/*.md ~/.config/opencode/templates/
cp /tmp/opencode-agent-team/commands/*.md ~/.claude/commands/
mkdir -p ~/.config/opencode/agent-team
cp /tmp/opencode-agent-team/agent-team/boulder.json ~/.config/opencode/agent-team/
cp /tmp/opencode-agent-team/team-config.json ~/.config/opencode/agent-team/
rm -rf /tmp/opencode-agent-team
```

然后重启 OpenCode，按 Tab 选择 `pm`。

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
├── agent-team/
│   ├── boulder.json                # 持久化状态
│   └── team-config.json            # 模型配置
└── templates/                      # 日志模板
```

**项目目录（PM 运行时创建）：**

```
<project>/
└── .opencode/
    ├── agent-team-log.md           # 共享日志
    ├── dev-{module}.md             # Developer 私有日志
    └── notepads/                   # 学习成果
```

## 更改模型

编辑 agent .md 文件的 frontmatter 中的 `model` 字段：

```yaml
---
name: developer
model: your-provider/your-model    # 改这里
temperature: 0.3
---
```

所有 agent 文件位于 `~/.config/opencode/agents/`。

## 许可证

MIT
