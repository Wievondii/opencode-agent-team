# Agent Team Index

> **项目**：{project_name}
> **创建时间**：{timestamp}

本文件作为 `.opencode/` 目录的索引入口。各角色按需要读取对应文件，避免一次性加载全部内容。

---

## 当前状态

- 当前轮次：见 `~/.config/opencode/agent-team/boulder.json` → `current_round`
- 预算消耗：`node ~/.config/opencode/agent-team/scripts/check-budget.mjs`

---

## 轮次目录

每轮一个独立目录，避免单文件膨胀：

```
.opencode/rounds/
├── round-1/
│   ├── plan.md          # Planner 输出（YAML frontmatter + 自由说明）
│   ├── review.md        # Reviewer 输出
│   ├── test.md          # Tester 输出（含 Bug 列表）
│   └── integration.md   # 集成检查报告（如适用）
├── round-2/
└── ...
```

## 私有工作日志

```
.opencode/dev-{module}.md   # 每个 Developer 私有，YAML frontmatter 严格 schema
```

## 跨轮 Notepads

```
.opencode/notepads/
├── decisions.md       # 关键技术决策（Planner 选型时强制写）
├── learnings.md       # 跨轮经验沉淀（PM 在轮次结束时提炼）
├── issues.md          # Reviewer/Tester 发现问题归集
├── verification.md    # 验证结果（Tester 通过时写入）
└── problems.md        # 未解决问题/blocker 升级
```

## 共享文件协调

```
.opencode/shared-file-changes/
└── round-N.md   # 非集成负责人对 shared_files 的修改请求汇总
```

## 测试证据

```
.opencode/test-evidence/round-N/
└── *.png | *.log
```
