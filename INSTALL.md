# 安装指南

## 压缩包安装（你已经有了）

### 1. 解压到固定目录

```
推荐：C:\opencode-agent-team
```

不要放在桌面或临时文件夹，放固定位置。

### 2. 配置 OpenCode

编辑 `C:\Users\你的用户名\.config\opencode\opencode.json`：

找到 `plugin` 那行，加一条本地路径：

```jsonc
{
  "plugin": [
    "C:\\opencode-agent-team"
  ]
}
```

> 如果已经有 `"opencode-browser-plugin"`，保留它，逗号分隔加新的。

### 3. 重启 OpenCode

完全关闭再打开。

### 4. 验证

按 `Tab` 键，agent 列表里出现 `pm` → 成功。

---

## 如果没有出现

手动复制文件（在压缩包解压目录执行）：

```powershell
# PowerShell
$src = "C:\opencode-agent-team"
$claude = "$env:USERPROFILE\.claude"

# 创建目录
New-Item -ItemType Directory "$claude\agents" -Force | Out-Null
New-Item -ItemType Directory "$claude\commands" -Force | Out-Null
New-Item -ItemType Directory "$env:USERPROFILE\.config\opencode\templates" -Force | Out-Null
New-Item -ItemType Directory "$env:USERPROFILE\.config\opencode\agent-team" -Force | Out-Null

# 复制 agent
Copy-Item "$src\agents\*.md" "$claude\agents\" -Force

# 复制 command
Copy-Item "$src\commands\*.md" "$claude\commands\" -Force

# 复制模板
Copy-Item "$src\templates\agent-team-log.md" "$env:USERPROFILE\.config\opencode\templates\comm-log.md" -Force

# 复制 boulder
Copy-Item "$src\agent-team\boulder.json" "$env:USERPROFILE\.config\opencode\agent-team\" -Force

Write-Output "手动部署完成，重启 OpenCode"
```

手动部署后不需要配 plugin，直接重启即可。

---

## 使用

**OpenCode：** Tab → 选 `pm` → 输入需求

**Claude Code：** 输入 `/agent-team 帮我做xxx`
