/**
 * OpenCode Agent Team Plugin (npm package)
 *
 * 协调策划师/开发者/审查员/测试员四个子agent
 * 通过Task + task_id实现持久化开发团队
 *
 * 首次加载时自动安装 agent 和 template 文件到正确位置
 * 后续加载时检测版本，如有更新则覆盖
 */

import { readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 版本管理
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const PACKAGE_VERSION = '1.0.0';
const VERSION_FILE = '.opencode-agent-team-version';

function getHome() {
  return process.env.USERPROFILE || process.env.HOME || '~';
}

function getVersionFilePath() {
  return join(getHome(), '.config', 'opencode', 'agent-team', VERSION_FILE);
}

function getInstalledVersion() {
  const versionFile = getVersionFilePath();
  if (!existsSync(versionFile)) return null;
  try {
    return readFileSync(versionFile, 'utf8').trim();
  } catch {
    return null;
  }
}

function setInstalledVersion(version) {
  const versionFile = getVersionFilePath();
  const dir = dirname(versionFile);
  mkdirSync(dir, { recursive: true });
  writeFileSync(versionFile, version, 'utf8');
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 文件安装
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const AGENT_FILES = ['pm.md', 'planner.md', 'developer.md', 'reviewer.md', 'tester.md'];
const TEMPLATE_FILES = ['agent-team-log.md', 'dev-workspace.md'];
const CONFIG_FILES = [
  { src: 'agent-team/boulder.json', dest: 'agent-team/boulder.json' }
];

function installFiles(force = false) {
  const home = getHome();
  const ocDir = join(home, '.config', 'opencode');

  const installed = [];
  const skipped = [];

  // 安装 agent .md 文件
  const agentDir = join(ocDir, 'agents');
  mkdirSync(agentDir, { recursive: true });

  for (const file of AGENT_FILES) {
    const dest = join(agentDir, file);
    const srcPath = join(__dirname, '..', 'agents', file);

    if (!existsSync(srcPath)) {
      skipped.push(`agents/${file} (source not found)`);
      continue;
    }

    if (!existsSync(dest) || force) {
      copyFileSync(srcPath, dest);
      installed.push(`agents/${file}`);
    } else {
      skipped.push(`agents/${file} (already exists)`);
    }
  }

  // 安装模板文件
  const tplDir = join(ocDir, 'templates');
  mkdirSync(tplDir, { recursive: true });

  for (const file of TEMPLATE_FILES) {
    const dest = join(tplDir, file);
    const srcPath = join(__dirname, '..', 'templates', file);

    if (!existsSync(srcPath)) {
      skipped.push(`templates/${file} (source not found)`);
      continue;
    }

    if (!existsSync(dest) || force) {
      copyFileSync(srcPath, dest);
      installed.push(`templates/${file}`);
    } else {
      skipped.push(`templates/${file} (already exists)`);
    }
  }

  // 安装配置文件
  for (const { src, dest } of CONFIG_FILES) {
    const destPath = join(ocDir, dest);
    const srcPath = join(__dirname, '..', src);
    const destDir = dirname(destPath);

    mkdirSync(destDir, { recursive: true });

    if (!existsSync(srcPath)) {
      skipped.push(`${src} (source not found)`);
      continue;
    }

    if (!existsSync(destPath) || force) {
      copyFileSync(srcPath, destPath);
      installed.push(dest);
    } else {
      skipped.push(`${dest} (already exists)`);
    }
  }

  return { installed, skipped };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 插件主函数（符合 OpenCode 插件规范）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export const AgentTeamPlugin = async ({ project, client, $, directory, worktree }) => {
  // 检查版本，决定是否需要安装/更新
  const installedVersion = getInstalledVersion();
  const needsInstall = !installedVersion;
  const needsUpdate = installedVersion && installedVersion !== PACKAGE_VERSION;

  if (needsInstall) {
    // 首次安装
    const result = installFiles(false);
    setInstalledVersion(PACKAGE_VERSION);
    if (result.installed.length > 0) {
      console.log(`[agent-team] Installed v${PACKAGE_VERSION}: ${result.installed.join(', ')}`);
    }
  } else if (needsUpdate) {
    // 版本更新：覆盖所有文件
    const result = installFiles(true);
    setInstalledVersion(PACKAGE_VERSION);
    console.log(`[agent-team] Updated v${installedVersion} -> v${PACKAGE_VERSION}: ${result.installed.join(', ')}`);
  }

  // 返回钩子对象（符合规范）
  return {
    'session.idle': async (input, output) => {
      // 可以在这里添加会话结束时的逻辑
    },

    'tool.execute.before': async (input, output) => {
      // 可以在这里添加工具执行前的逻辑
    },

    'tool.execute.after': async (input, output) => {
      // 可以在这里添加工具执行后的逻辑
    }
  };
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 元数据导出
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export const name = 'opencode-agent-team';
export const version = PACKAGE_VERSION;
export const description = 'OpenCode Agent Team - 协调策划师/开发者/审查员/测试员四个子agent';
