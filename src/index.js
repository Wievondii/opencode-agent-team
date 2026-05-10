/**
 * OpenCode Agent Team Plugin
 * 
 * 协调策划师/开发者/审查员/测试员四个子agent
 * 通过Task + task_id实现持久化开发团队
 */

const fs = require('fs');
const path = require('path');

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

// 初始化boulder.json结构
const defaultBoulder = {
  "version": "1.0.0",
  "active_plan": null,
  "current_round": 0,
  "started_at": null,
  "last_activity": null,
  "status": "idle",
  "agents": {
    "planner": { "status": "idle", "session_id": null, "task_id": null },
    "developer": { "status": "idle", "session_id": null, "task_id": null, "modules": [] },
    "reviewer": { "status": "idle", "session_id": null, "task_id": null },
    "tester": { "status": "idle", "session_id": null, "task_id": null }
  },
  "task_ids": {},
  "tasks": {
    "total": 0,
    "completed": 0,
    "in_progress": 0,
    "pending": 0
  },
  "errors": [],
  "learnings": []
};

module.exports = {
  name: 'opencode-agent-team',
  version: '1.0.0',
  
  // 导出agent配置
  agents: {
    pm: {
      name: 'pm',
      description: agents.pm.match(/description:\s*(.*?)\n/)?.[1] || 'OpenCode Agent团队的项目经理',
      prompt: agents.pm,
      mode: 'primary',
      temperature: 0.2
    },
    planner: {
      name: 'planner',
      description: agents.planner.match(/description:\s*(.*?)\n/)?.[1] || 'OpenCode Agent团队的策划师',
      prompt: agents.planner,
      mode: 'subagent',
      temperature: 0.2
    },
    developer: {
      name: 'developer',
      description: agents.developer.match(/description:\s*(.*?)\n/)?.[1] || 'OpenCode Agent团队的开发者',
      prompt: agents.developer,
      mode: 'subagent',
      temperature: 0.3
    },
    reviewer: {
      name: 'reviewer',
      description: agents.reviewer.match(/description:\s*(.*?)\n/)?.[1] || 'OpenCode Agent团队的代码审查员',
      prompt: agents.reviewer,
      mode: 'subagent',
      temperature: 0.2
    },
    tester: {
      name: 'tester',
      description: agents.tester.match(/description:\s*(.*?)\n/)?.[1] || 'OpenCode Agent团队的测试员',
      prompt: agents.tester,
      mode: 'subagent',
      temperature: 0.2
    }
  },

  // 导出模板
  templates: templates,

  // 导出默认boulder结构
  boulder: defaultBoulder,

  // 插件描述
  description: 'OpenCode Agent Team - 协调策划师/开发者/审查员/测试员四个子agent，通过Task + task_id实现持久化开发团队',
  
  // 提供初始化boulder.json的方法
  initBoulder(projectName) {
    return {
      ...defaultBoulder,
      active_plan: projectName,
      current_round: 1,
      started_at: new Date().toISOString(),
      last_activity: new Date().toISOString(),
      status: 'in_progress'
    };
  },

  // 提供读取agent的方法
  getAgent(name) {
    return agents[name] || null;
  },

  // 提供读取模板的方法
  getTemplate(name) {
    return templates[name] || null;
  }
};
