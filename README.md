# OpenCode Agent Team

一个 OpenCode 插件，用于协调策划师/开发者/审查员/测试员四个子 agent，通过 Task + task_id 实现持久化开发团队。

## 特性

- **Task + task_id 持久化**：Agent 完成任务后休眠，通过 task_id 唤醒同一会话，上下文完整保留
- **谁犯错谁修复**：错误通过文件归属确定责任 Developer，用 task_id 恢复修复
- **内置完整提示词**：所有 agent 提示词自包含，无需外部 skill 加载
- **并行开发支持**：多个 Developer 可并行工作，通过共享日志同步进度
- **完整工作流**：策划 → 开发 → 集成检查 → 审查 → 测试 → 修复循环

## 安装

### 方式 1：npm 全局安装

```bash
npm install -g opencode-agent-team
```

### 方式 2：本地开发安装

```bash
git clone https://github.com/your-username/opencode-agent-team.git
cd opencode-agent-team
npm link
```

### 方式 3：直接在 opencode.json 中配置

在 `~/.config/opencode/opencode.json` 的 `plugin` 数组中添加：

```json
{
  "plugin": [
    "opencode-browser-plugin",
    "opencode-agent-team"
  ]
}
```

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

### 持久化机制

- **Task + task_id**：PM 首次调用 Task 记录 task_id，后续用 task_id 恢复同一会话
- **boulder.json**：持久化状态追踪（项目、轮次、agent 状态、task_id）
- **共享日志**：agent 间通过 `.opencode/agent-team-log.md` 沟通
- **错误追踪**：记录错误到 `~/.config/opencode/agent-team/errors/`

## 目录结构

```
<project>/
├── .opencode/
│   ├── agent-team-log.md           # 共享日志
│   └── notepads/                   # 学习成果
│       ├── learnings.md
│       ├── decisions.md
│       ├── issues.md
│       ├── verification.md
│       └── problems.md
└── ... (项目代码)

~/.config/opencode/agent-team/
├── boulder.json                    # 持久化状态 + task_id 追踪
├── errors/                         # 错误记录
├── rounds/                         # 轮次归档
└── notepads/                       # 跨项目学习成果
```

## 配置

插件会自动创建所需的目录和文件。如需手动配置：

### boulder.json

```json
{
  "version": "1.0.0",
  "active_plan": null,
  "current_round": 0,
  "status": "idle",
  "task_ids": {},
  "errors": [],
  "learnings": []
}
```

### 共享日志模板

模板文件位于 `templates/` 目录，PM 启动时会从模板创建共享日志。

## 开发

```bash
# 克隆仓库
git clone https://github.com/your-username/opencode-agent-team.git
cd opencode-agent-team

# 安装依赖
npm install

# 链接到本地 OpenCode
npm link

# 测试插件
# 在 OpenCode 中切换到 pm agent，描述需求
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT
