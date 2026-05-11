/**
 * OpenCode Agent Team Plugin
 *
 * 协调策划师/开发者/审查员/测试员四个子agent
 * 通过Task + task_id实现持久化开发团队
 */

import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 插件主函数（符合 OpenCode 插件规范）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/**
 * OpenCode Agent Team 插件
 *
 * 接收插件上下文参数，返回钩子对象
 * Agent 定义在 ~/.config/opencode/agents/*.md 中自动加载
 */
export const AgentTeamPlugin = async ({ project, client, $, directory, worktree }) => {
  return {
    // 会话空闲时的钩子
    'session.idle': async (input, output) => {
      // 可以在这里添加会话结束时的逻辑
    },

    // 工具执行前的钩子
    'tool.execute.before': async (input, output) => {
      // 可以在这里添加工具执行前的逻辑
    },

    // 工具执行后的钩子
    'tool.execute.after': async (input, output) => {
      // 可以在这里添加工具执行后的逻辑
    }
  };
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 元数据导出
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export const name = 'opencode-agent-team';
export const version = '1.0.0';
export const description = 'OpenCode Agent Team - 协调策划师/开发者/审查员/测试员四个子agent';
