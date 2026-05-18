// agent-team/scripts/lib/paths.mjs
// 解析 agent-team 全局目录与项目本地 .opencode 目录的路径。
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { existsSync } from 'node:fs';

export function getGlobalAgentTeamDir() {
  // OpenCode 全局配置目录
  // Linux/macOS: ~/.config/opencode/agent-team
  // Windows: %USERPROFILE%\.config\opencode\agent-team（install.ps1 也用此路径）
  return join(homedir(), '.config', 'opencode', 'agent-team');
}

export function getSchemasDir() {
  return join(getGlobalAgentTeamDir(), 'schemas');
}

export function getScriptsDir() {
  return join(getGlobalAgentTeamDir(), 'scripts');
}

export function getBoulderPath() {
  return join(getGlobalAgentTeamDir(), 'boulder.json');
}

export function getEventsPath() {
  return join(getGlobalAgentTeamDir(), 'boulder-events.jsonl');
}

export function getProjectOpencodeDir(projectRoot = process.cwd()) {
  return join(resolve(projectRoot), '.opencode');
}

export function getRoundDir(round, projectRoot = process.cwd()) {
  return join(getProjectOpencodeDir(projectRoot), 'rounds', `round-${round}`);
}

export function ensureGlobalDirsExist() {
  // 校验全局目录已通过 install 脚本创建
  const dir = getGlobalAgentTeamDir();
  if (!existsSync(dir)) {
    throw new Error(
      `agent-team 全局目录不存在：${dir}\n请先运行 install.sh / install.ps1`
    );
  }
}
