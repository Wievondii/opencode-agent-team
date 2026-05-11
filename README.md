# OpenCode Agent Team

OpenCode 插件，协调策划师/开发者/审查员/测试员四个子 agent，通过 Task + task_id 实现持久化开发团队。

## 特性

- **Task + task_id 持久化**：Agent 完成任务后休眠，通过 task_id 唤醒同一会话，上下文完整保留
- **谁犯错谁修复**：错误通过文件归属确定责任 Developer，用 task_id 恢复修复
- **内置完整提示词**：所有 agent 提示词自包含，无需外部 skill 加载
- **并行开发支持**：多个 Developer 可并行工作，通过共享日志同步进度
- **完整工作流**：策划 → 开发 → 集成检查 → 审查 → 测试 → 修复循环

## 安装

### 方式一：压缩包安装（推荐）

1. 下载并解压到任意目录（如 `D:\opencode-agent-team`）
2. 打开 PowerShell，进入解压目录
3. 运行安装脚本：

```powershell
.\install.ps1
```

4. 重启 OpenCode
5. 按 `Tab` 选择 `pm` 开始使用

### 方式二：Git 安装

```powershell
git clone https://github.com/Wievondii/opencode-agent-team.git
cd opencode-agent-team
.\install.ps1
```

### 安装脚本做了什么

`install.ps1` 会将文件安装到**运行时目录**（不是引用仓库路径）：

- `agents/*.md` → `~/.config/opencode/agents/` + `~/.claude/agents/`
- `commands/*.md` → `~/.claude/commands/`
- `templates/` → `~/.config/opencode/templates/`
- `team-config.json` → `~/.config/opencode/agent-team/`
- `sync-models.ps1` → `~/.config/opencode/agent-team/`
- 插件代码 → `~/.config/opencode/plugins/agent-team/`
- 自动更新 `opencode.json`（添加 plugin 引用和 agent 定义）

安装后，运行时目录和仓库完全独立，互不影响。

## 使用

### 1. 切换到 PM Agent

在 OpenCode 中按 `Tab` 键，选择 `pm`（项目经理）。

### 2. 描述需求

对 PM 说你的需求，例如：

> "帮我创建一个 React 待办事项应用"

PM 会自动：
1. 拉起 Planner 制定计划
2. 分配 Developer 并行开发
3. 集成检查
4. Reviewer 审查 + 提交
5. Tester 测试
6. 如有 Bug，用 task_id 恢复 Developer 修复

### 3. 持久化验证

Developer 写完代码后会休眠（不是销毁）。测试发现 Bug 时，PM 用记录的 task_id 唤醒同一个 Developer 会话，上下文完整保留。

## 更改模型

安装后如需更改 agent 模型：

1. 编辑配置文件：

```powershell
notepad ~/.config/opencode/agent-team/team-config.json
```

2. 运行同步脚本：

```powershell
powershell ~/.config/opencode/agent-team/sync-models.ps1
```

3. 重启 OpenCode

## 架构

```
PM (项目经理)
├── Planner (策划师) - 制定开发计划
├── Developer (开发者) - 编写代码，修复 Bug
├── Reviewer (审查员) - 代码审查，提交代码
└── Tester (测试员) - 功能测试，Bug 报告
```

### 工作流程

```
用户需求 → PM → Planner → Developer(s) → 集成检查 → Reviewer → Tester
                                    ↑                    ↓
                                    └── task_id 恢复修复 ←┘
```

### 目录结构

**运行时目录（安装后自动生成）：**

```
~/.config/opencode/
├── agents/                         # Agent 提示词文件
├── agent-team/
│   ├── boulder.json                # 持久化状态 + task_id 追踪
│   ├── team-config.json            # 模型配置
│   └── sync-models.ps1             # 模型同步脚本
├── plugins/agent-team/             # 插件代码
└── templates/                      # 共享日志模板

~/.claude/
├── agents/                         # Agent 提示词（Claude Code 兼容）
└── commands/agent-team.md          # Claude Code 命令
```

**项目目录（PM 运行时创建）：**

```
<project>/
└── .opencode/
    ├── agent-team-log.md           # 共享日志
    └── notepads/                   # 学习成果
```

## 许可证

MIT
