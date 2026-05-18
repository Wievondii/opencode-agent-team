#!/usr/bin/env node
// agent-team/scripts/archive-round.mjs
// 轮次结束时归档：
// 1. 把 .opencode/rounds/round-N/* 拷贝到 ~/.config/opencode/agent-team/rounds/round-N/
// 2. 提取本轮 learnings 追加到 .opencode/notepads/learnings.md
// 3. 写 round_completed 事件
import { existsSync, mkdirSync, readdirSync, copyFileSync, readFileSync, appendFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { getProjectOpencodeDir, getGlobalAgentTeamDir } from './lib/paths.mjs';

const projectRoot = process.argv[2] ?? process.cwd();
const round = parseInt(process.argv[3] ?? '0', 10);
if (!round) {
  console.error('用法：node archive-round.mjs <project-root> <round>');
  process.exit(2);
}

const opencodeDir = getProjectOpencodeDir(projectRoot);
const roundDir = join(opencodeDir, 'rounds', `round-${round}`);
const globalRoundsDir = join(getGlobalAgentTeamDir(), 'rounds', `round-${round}`);

if (!existsSync(roundDir)) {
  console.error('round 目录不存在：' + roundDir);
  process.exit(1);
}

if (!existsSync(globalRoundsDir)) {
  mkdirSync(globalRoundsDir, { recursive: true });
}

function copyRecursive(src, dst) {
  if (!existsSync(dst)) mkdirSync(dst, { recursive: true });
  for (const entry of readdirSync(src)) {
    const s = join(src, entry);
    const d = join(dst, entry);
    if (statSync(s).isDirectory()) {
      copyRecursive(s, d);
    } else {
      copyFileSync(s, d);
    }
  }
}

copyRecursive(roundDir, globalRoundsDir);

// 写 round_completed 事件
const append = process.platform === 'win32' ? 'node.exe' : 'node';
spawnSync(append, [
  join(getGlobalAgentTeamDir(), 'scripts', 'append-event.mjs'),
  JSON.stringify({ event: 'round_completed', round }),
], { stdio: 'inherit' });

console.log(JSON.stringify({ ok: true, archived_to: globalRoundsDir }));
