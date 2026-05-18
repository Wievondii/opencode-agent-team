#!/usr/bin/env node
// agent-team/scripts/check-task-id-fresh.mjs
// 简单的 task_id 健康检查：通过 boulder.json + 心跳时间戳判断是否过期。
// 注：真正的 task_id 唤醒由 PM 调用 OpenCode Task 工具完成；本脚本只做心跳超时判断。
import { existsSync, readFileSync } from 'node:fs';
import { getBoulderPath } from './lib/paths.mjs';

const role = process.argv[2]; // planner | developer | reviewer | tester
const module = process.argv[3]; // for developer/tester
const ttlMin = parseInt(process.argv[4] ?? '15', 10);

const boulderPath = getBoulderPath();
if (!existsSync(boulderPath)) {
  console.log(JSON.stringify({ fresh: false, reason: 'boulder.json 不存在' }));
  process.exit(1);
}

const boulder = JSON.parse(readFileSync(boulderPath, 'utf-8'));

function checkAgent(agent) {
  if (!agent || !agent.task_id) {
    return { fresh: false, reason: 'task_id 不存在' };
  }
  if (agent.status === 'expired' || agent.status === 'failed') {
    return { fresh: false, reason: 'agent 状态为 ' + agent.status };
  }
  if (!agent.last_heartbeat) {
    return { fresh: false, reason: '缺少 last_heartbeat' };
  }
  const last = new Date(agent.last_heartbeat).getTime();
  const ageMin = (Date.now() - last) / 60_000;
  if (ageMin > ttlMin) {
    return { fresh: false, reason: `心跳超时 ${ageMin.toFixed(1)} 分钟（阈值 ${ttlMin}）` };
  }
  return { fresh: true, task_id: agent.task_id, age_min: ageMin };
}

let agent;
switch (role) {
  case 'planner':
    agent = boulder.agents?.planner;
    break;
  case 'developer':
    agent = boulder.agents?.developers?.[module];
    break;
  case 'reviewer':
    agent = boulder.agents?.reviewers?.find?.(r => r.scope?.includes(module)) ?? boulder.agents?.reviewers?.at?.(-1);
    break;
  case 'tester':
    agent = boulder.agents?.testers?.find?.(t => t.module === module);
    break;
  default:
    console.log(JSON.stringify({ fresh: false, reason: 'unknown role' }));
    process.exit(2);
}

const r = checkAgent(agent);
console.log(JSON.stringify(r));
process.exit(r.fresh ? 0 : 1);
