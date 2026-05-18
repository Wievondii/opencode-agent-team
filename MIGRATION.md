# OpenCode Agent Team — v1 → v2.0 Migration Guide

v2.0 是一次破坏性升级。本文档说明如何从 v1 迁移到 v2.0。

---

## 为什么要升级

v2.0 修复了 v1 的 18 个核心问题，包括：

| 问题 | v1 表现 | v2.0 修复 |
|------|---------|-----------|
| 私有日志格式自由 | dev-*.md 没有强制结构 | YAML frontmatter + JSON Schema 强校验 |
| 迭代上限粒度粗 | 单一 3 次硬上限 | 三类独立预算（reviewer_rejection/bug_fix_a/bug_fix_b）+ 总闸 |
| 并行写冲突无防护 | 多 Dev 改同一文件无机制 | check-file-conflicts.mjs + shared_files 协调员模式 |
| boulder.json 并发 | 多 Agent 直接覆写 | append-only events.jsonl + rebuild-boulder.mjs |
| 错误分类二元 | A/B 两类 | A/B/C/D/E 五类（增加环境/需求理解/测试用例错） |
| Reviewer 串/并矛盾 | 自相矛盾 | 拆分 reviewer 模式（并行）+ committer 模式（独占）|
| 集成修复跳过审查 | 直接修复无校验 | 强制简化审查（typecheck + 接口契约）|
| 共享日志膨胀 | 单文件 500 行触发 | 拆为 rounds/round-N/{plan,review,test,integration}.md |
| Bug 严重度主观 | 凭感觉打 🔴/🟡/🟢 | impact × frequency 矩阵脚本推导 |
| Agent 健康检查靠人脑 | 10 分钟无响应靠心算 | last_heartbeat 字段 + check-task-id-fresh.mjs |
| 质量门禁靠良心 | Developer 自报完成 | check-quality-gates.mjs 强制贴出命令证据 |
| 无回滚机制 | commit 后只能再开发 | round-N-baseline tag + git reset 选项 |

完整 18 项见 PR1-4 的 commit message。

---

## 不向后兼容

v2.0 选择**破坏式升级**（不提供自动迁移脚本），原因：

- v1 的 boulder.json schema 与 v2 完全不同，迁移脚本本身要测试
- 旧的 `.opencode/agent-team-log.md` 单文件结构无法 1:1 映射到新的 `rounds/round-N/` 目录
- 旧的 dev-*.md 自由格式无法自动转换为 frontmatter
- 维护双轨增加长期成本

但提供以下保护：

- `install.sh` / `install.ps1` 检测旧 v1 boulder.json，自动备份为 `boulder.json.v1.bak`
- 清理 `templates/agent-team-log.md` 旧模板（已被 `agent-team-log-index.md` 替代）

---

## 迁移步骤

### 步骤 1：备份现有数据

```bash
# 全局配置
cp -r ~/.config/opencode ~/.config/opencode.v1.backup

# 项目运行时数据
cd <你的项目>
cp -r .opencode .opencode.v1.backup
```

Windows PowerShell：

```powershell
Copy-Item -Recurse "$env:USERPROFILE\.config\opencode" "$env:USERPROFILE\.config\opencode.v1.backup"
Copy-Item -Recurse .\.opencode .\.opencode.v1.backup
```

---

### 步骤 2：检查 Node.js 版本

v2.0 要求 **Node.js ≥ 18**：

```bash
node -v   # 应输出 v18.x 或更高
```

如果没有 Node 18+，先安装：https://nodejs.org/

---

### 步骤 3：跑安装脚本

```bash
# Linux / macOS / WSL
curl -fsSL https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/Wievondii/opencode-agent-team/master/install.ps1 | iex
```

脚本会：
- 检查 Node 版本
- 拷贝 v2.0 的 agents / templates / schemas / scripts
- 自动备份旧 boulder.json 为 `boulder.json.v1.bak` 并替换为 v2 种子
- 预装 npm 依赖（ajv/fast-glob/proper-lockfile/yaml）

---

### 步骤 4：重置项目运行时

旧的 `.opencode/` 目录与 v2 不兼容。两个选择：

**选项 A：完全重置（推荐）**

```bash
cd <你的项目>
rm -rf .opencode    # 备份已在 .opencode.v1.backup
# 下次跑 PM 时会自动重建
```

Windows：
```powershell
Remove-Item -Recurse -Force .\.opencode
```

**选项 B：保留 notepads，重置其他**

```bash
cd <你的项目>
mkdir -p .opencode-keep
cp -r .opencode/notepads .opencode-keep/   # 保留学习成果（如果你之前有用）
rm -rf .opencode
mkdir -p .opencode
mv .opencode-keep/notepads .opencode/notepads
rm -rf .opencode-keep
```

注意：旧 notepads 没有结构化 schema，v2 模板会要求遵循新格式（YYYY-MM-DD · 标题 + 字段）。建议手工整理一遍。

---

### 步骤 5：验证安装

```bash
# 1. 确认 schemas 已部署
ls ~/.config/opencode/agent-team/schemas/
# 应有 5 个 .schema.json 文件

# 2. 确认 scripts 已部署
ls ~/.config/opencode/agent-team/scripts/
# 应有 13 个 .mjs + lib/ + package.json + node_modules/

# 3. 跑一个简单的脚本测试
node ~/.config/opencode/agent-team/scripts/check-budget.mjs
# 应输出 JSON 显示当前 4 个预算（全为 used: 0）

# 4. 确认 agent prompt 已更新
head -3 ~/.config/opencode/agents/pm.md
# 应包含 "v2.0" 字样
```

Windows 路径替换为 `$env:USERPROFILE\.config\opencode\...`。

---

### 步骤 6：开始新的 v2.0 轮次

```
打开 OpenCode → Tab 选择 pm agent → 描述需求
```

PM 会：
1. 启动钩子运行 `ensure-deps.mjs`（首次会装 npm 依赖，无感知）
2. 检测 boulder.json 是 v2.0 schema
3. 创建 `.opencode/rounds/round-1/` 等新结构
4. 走 v2 工作流

---

## 旧数据回看

如果你需要查阅 v1 的历史轮次记录：

```bash
# 旧共享日志
cat .opencode.v1.backup/agent-team-log.md

# 旧 notepads
ls .opencode.v1.backup/notepads/

# 旧 boulder
cat ~/.config/opencode/agent-team/boulder.json.v1.bak
```

这些数据保留为只读参考，不会被 v2.0 自动读取。

---

## 回滚到 v1

如果 v2.0 不合适：

```bash
# 1. 卸载 v2.0
bash uninstall.sh

# 2. 恢复 v1 备份
rm -rf ~/.config/opencode
mv ~/.config/opencode.v1.backup ~/.config/opencode

# 3. 检出 v1 仓库（最后一个 v1 commit）
cd opencode-agent-team
git checkout <v1-tag-or-sha>
bash install.sh
```

---

## 常见问题

### Q1：v1 的 task_id 还能继续用吗？

不能。v2 的 boulder schema 不兼容 v1 task_id 结构。建议在 v1 当前轮结束后再升级，避免中断。

### Q2：能不能不用 Node.js？

不能。v2 的所有校验/事件脚本都是 Node.js (mjs)。这是 5b 决策的核心：硬约束需要可执行代码，prompt 软约束在 v1 已被证明不够可靠。

### Q3：v2 的 npm 依赖会安装到哪？

`~/.config/opencode/agent-team/scripts/node_modules/`，不影响你的项目 node_modules。卸载脚本会一并清理。

### Q4：可以把 v2 的 scripts 放到我自己的项目里吗？

不建议。这些脚本是 PM/Agent 共用的，应该全局只装一份。在每个项目里复制会导致版本漂移。

### Q5：pre-warm npm install 失败怎么办？

不影响首次使用——PM 启动时会调用 `ensure-deps.mjs` 自动重试。如果一直失败，手动跑：

```bash
cd ~/.config/opencode/agent-team/scripts
npm install
```

---

## 反馈

升级遇到问题请提 issue：https://github.com/Wievondii/opencode-agent-team/issues
