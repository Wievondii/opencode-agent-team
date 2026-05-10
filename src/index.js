/**
 * OpenCode Agent Team Plugin
 * 
 * 协调策划师/开发者/审查员/测试员四个子agent
 * 通过Task + task_id实现持久化开发团队
 */

const fs = require('fs');
const path = require('path');

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// #1 修复: boulder.json 作为 Single Source of Truth
// #2 修复: 不再手写 defaultBoulder，直接从文件读取
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const defaultBoulder = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../agent-team/boulder.json'), 'utf8')
);

// 读取agent定义文件
const agents = {
  pm: fs.readFileSync(path.join(__dirname, '../agents/pm.md'), 'utf8'),
  planner: fs.readFileSync(path.join(__dirname, '../agents/planner.md'), 'utf8'),
  developer: fs.readFileSync(path.join(__dirname, '../agents/developer.md'), 'utf8'),
  reviewer: fs.readFileSync(path.join(__dirname, '../agents/reviewer.md'), 'utf8'),
  tester: fs.readFileSync(path.join(__dirname, '../agents/tester.md'), 'utf8')
};

// 读取模板文件
const templates = {
  'agent-team-log.md': fs.readFileSync(path.join(__dirname, '../templates/agent-team-log.md'), 'utf8')
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// #3 修复: description 硬编码，不再用正则解析 frontmatter
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const agentDescriptions = {
  pm: 'OpenCode Agent团队的项目经理（PM）。负责管理迭代开发流程，协调策划师/开发者/审查员/测试员四个子agent，维护公共通信文件，与用户沟通需求',
  planner: 'OpenCode Agent团队的策划师。负责分析需求、制定详细的技术方案和实施计划',
  developer: 'OpenCode Agent团队的开发者。负责根据策划师的计划编写代码、修复测试员发现的bug',
  reviewer: 'OpenCode Agent团队的代码审查员。负责审查代码质量、安全性、规范遵循，审查通过后执行git add + git commit',
  tester: 'OpenCode Agent团队的测试员。负责功能测试、Bug分类、回归验证，绝不修改代码只报告'
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Agent 配置导出
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const agentConfigs = {
  pm: {
    name: 'pm',
    description: agentDescriptions.pm,
    prompt: agents.pm,
    mode: 'subagent',
    // #6 修复: PM 工具白名单——只允许 Read/Write/Task
    tools: {
      write: true,
      read: true,
      task: true,
      edit: false,
      bash: false,
      browser: false,
      glob: false,
      grep: false
    },
    temperature: 0.2
  },
  planner: {
    name: 'planner',
    description: agentDescriptions.planner,
    prompt: agents.planner,
    mode: 'subagent',
    temperature: 0.2
  },
  developer: {
    name: 'developer',
    description: agentDescriptions.developer,
    prompt: agents.developer,
    mode: 'subagent',
    temperature: 0.3
  },
  reviewer: {
    name: 'reviewer',
    description: agentDescriptions.reviewer,
    prompt: agents.reviewer,
    mode: 'subagent',
    temperature: 0.2
  },
  tester: {
    name: 'tester',
    description: agentDescriptions.tester,
    prompt: agents.tester,
    mode: 'subagent',
    temperature: 0.2
  }
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// #7 修复: Agent 超时/心跳工具
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const TIMEOUT_CONFIG = {
  /** Developer 任务最大等待时间（毫秒） */
  developerTimeoutMs: 10 * 60 * 1000,
  /** 心跳检查间隔（毫秒） */
  heartbeatIntervalMs: 2 * 60 * 1000,
  /** 最大修复循环次数 */
  maxFixCycles: 3,
  /** 共享日志最大行数（超过则强制归档） */
  maxSharedLogLines: 500
};

/**
 * #7 检查 task_id 是否可能已过期
 * 返回 { valid: boolean, reason?: string }
 */
function checkTaskIdFresh(taskId, startedAt) {
  if (!startedAt) return { valid: false, reason: 'no startedAt' };
  const elapsed = Date.now() - new Date(startedAt).getTime();
  if (elapsed > TIMEOUT_CONFIG.developerTimeoutMs) {
    return { valid: false, reason: `timeout: ${Math.round(elapsed/1000)}s > ${TIMEOUT_CONFIG.developerTimeoutMs/1000}s` };
  }
  return { valid: true };
}

/**
 * #10 修复: 检查共享日志大小，超过阈值返回归档建议
 */
function checkSharedLogSize(logPath) {
  try {
    const content = fs.readFileSync(logPath, 'utf8');
    const lines = content.split('\n').length;
    if (lines > TIMEOUT_CONFIG.maxSharedLogLines) {
      return { needsArchive: true, lines };
    }
    return { needsArchive: false, lines };
  } catch {
    return { needsArchive: false, lines: 0 };
  }
}

module.exports = {
  name: 'opencode-agent-team',
  version: '1.0.0',
  
  // 导出agent配置
  agents: agentConfigs,

  // 导出模板
  templates: templates,

  // 导出默认boulder结构
  boulder: defaultBoulder,

  // 插件描述
  description: 'OpenCode Agent Team - 协调策划师/开发者/审查员/测试员四个子agent，通过Task + task_id实现持久化开发团队',
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // #1 修复: initBoulder 深拷贝，防止状态污染
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  initBoulder(projectName) {
    const boulder = JSON.parse(JSON.stringify(defaultBoulder));
    boulder.active_plan = projectName;
    boulder.current_round = 1;
    boulder.started_at = new Date().toISOString();
    boulder.last_activity = new Date().toISOString();
    boulder.status = 'in_progress';
    return boulder;
  },

  // #7 导出超时配置和检查函数
  timeout: TIMEOUT_CONFIG,
  checkTaskIdFresh: checkTaskIdFresh,
  
  // #10 导出日志大小检查
  checkSharedLogSize: checkSharedLogSize,

  // 提供读取agent的方法
  getAgent(name) {
    return agents[name] || null;
  },

  // 提供读取模板的方法
  getTemplate(name) {
    return templates[name] || null;
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // #9 修复: install() 自动部署文件到 ~/.config/opencode/
  // PM 引用 ~/.config/opencode/templates/comm-log.md
  //          ~/.config/opencode/agent-team/boulder.json
  // install() 确保这些文件存在
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  install() {
    const home = process.env.USERPROFILE || process.env.HOME || '~';
    const opencodeDir = path.join(home, '.config', 'opencode');
    const claudeDir = path.join(home, '.claude');
    
    // 目标路径
    const targets = {
      commands: {
        dir: path.join(claudeDir, 'commands'),
        files: [
          { name: 'agent-team.md', source: 'agent-team.md' }
        ]
      },
      templates: {
        dir: path.join(opencodeDir, 'templates'),
        files: [
          { name: 'comm-log.md', source: 'agent-team-log.md' },
          { name: 'dev-log.md', source: 'agent-team-log.md' },
          { name: 'review-log.md', source: 'agent-team-log.md' },
          { name: 'test-log.md', source: 'agent-team-log.md' }
        ]
      },
      agentTeam: {
        dir: path.join(opencodeDir, 'agent-team'),
        files: [
          { name: 'boulder.json', source: 'boulder.json' }
        ],
        subdirs: ['errors', 'rounds', 'notepads', 'tasks']
      }
    };

    const installed = [];
    const skipped = [];

    try {
      // 部署 Claude Code command
      const cmdDir = targets.commands.dir;
      fs.mkdirSync(cmdDir, { recursive: true });
      const cmdDest = path.join(cmdDir, 'agent-team.md');
      if (!fs.existsSync(cmdDest)) {
        fs.copyFileSync(
          path.join(__dirname, '..', 'commands', 'agent-team.md'),
          cmdDest
        );
        installed.push('commands/agent-team.md');
      } else {
        skipped.push('commands/agent-team.md (already exists)');
      }

      // 部署模板
      const tplDir = targets.templates.dir;
      fs.mkdirSync(tplDir, { recursive: true });
      for (const f of targets.templates.files) {
        const dest = path.join(tplDir, f.name);
        if (!fs.existsSync(dest)) {
          fs.copyFileSync(
            path.join(__dirname, '..', 'templates', f.source),
            dest
          );
          installed.push(`templates/${f.name}`);
        } else {
          skipped.push(`templates/${f.name} (already exists)`);
        }
      }

      // 部署 agent-team 目录和文件
      const atDir = targets.agentTeam.dir;
      fs.mkdirSync(atDir, { recursive: true });
      
      // 创建子目录
      for (const sd of targets.agentTeam.subdirs) {
        fs.mkdirSync(path.join(atDir, sd), { recursive: true });
      }

      // 复制 boulder.json（仅在目标不存在时）
      const boulderDest = path.join(atDir, 'boulder.json');
      if (!fs.existsSync(boulderDest)) {
        fs.copyFileSync(
          path.join(__dirname, '..', 'agent-team', 'boulder.json'),
          boulderDest
        );
        installed.push('agent-team/boulder.json');
      } else {
        skipped.push('agent-team/boulder.json (already exists)');
      }

      console.log(`[opencode-agent-team] install: ${installed.length} files deployed, ${skipped.length} skipped`);
      return { installed, skipped };
    } catch (e) {
      console.error('[opencode-agent-team] install failed:', e.message);
      throw e;
    }
  }
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// #14 基础单元测试（node -e 快速验证用）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function selfTest() {
  const p = require('../src/index.js');
  const results = [];
  
  // 测试 initBoulder 深拷贝
  const b1 = p.initBoulder('test1');
  const b2 = p.initBoulder('test2');
  b1.agents.planner.status = 'modified';
  if (b2.agents.planner.status !== 'modified') {
    results.push('[PASS] initBoulder deep clone');
  } else {
    results.push('[FAIL] initBoulder shallow copy detected');
  }
  
  // 测试结构一致性
  if (p.boulder.task_ids !== undefined) {
    results.push('[PASS] boulder has task_ids');
  } else {
    results.push('[FAIL] boulder missing task_ids');
  }
  
  // 测试 agent 导出
  const names = Object.keys(p.agents);
  if (names.length === 5) {
    results.push('[PASS] 5 agents exported');
  } else {
    results.push(`[FAIL] expected 5 agents, got ${names.length}`);
  }
  
  // 测试 checkTaskIdFresh
  const fresh = p.checkTaskIdFresh('abc', new Date().toISOString());
  if (fresh.valid) {
    results.push('[PASS] checkTaskIdFresh returns valid for recent');
  } else {
    results.push('[FAIL] checkTaskIdFresh failed');
  }
  
  const stale = p.checkTaskIdFresh('abc', new Date(Date.now() - 99999999).toISOString());
  if (!stale.valid) {
    results.push('[PASS] checkTaskIdFresh detects stale');
  } else {
    results.push('[FAIL] checkTaskIdFresh missed stale');
  }
  
  console.log(results.join('\n'));
  const passed = results.filter(r => r.startsWith('[PASS]')).length;
  console.log(`\n${passed}/${results.length} tests passed`);
}

// 直接运行时执行自测
if (require.main === module) {
  selfTest();
}
