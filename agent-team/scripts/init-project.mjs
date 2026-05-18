#!/usr/bin/env node
// agent-team/scripts/init-project.mjs
// 在当前项目目录创建 .opencode/ 目录骨架（含 rounds/round-1, notepads, dev-workspace 模板）。
// 用法：node init-project.mjs <project-root> <project-name>
import { existsSync, mkdirSync, copyFileSync, readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const __dirname = dirname(fileURLToPath(import.meta.url));
// 模板源在 ~/.config/opencode/templates/
const templatesDir = join(homedir(), '.config', 'opencode', 'templates');

const projectRoot = process.argv[2] ?? process.cwd();
const projectName = process.argv[3] ?? 'unknown-project';

const opencodeDir = join(projectRoot, '.opencode');
const roundsDir = join(opencodeDir, 'rounds');
const round1Dir = join(roundsDir, 'round-1');
const notepadsDir = join(opencodeDir, 'notepads');
const sharedFileChangesDir = join(opencodeDir, 'shared-file-changes');

for (const d of [opencodeDir, roundsDir, round1Dir, notepadsDir, sharedFileChangesDir]) {
  if (!existsSync(d)) mkdirSync(d, { recursive: true });
}

function copyTemplate(srcRel, dst, replacements = {}) {
  const src = join(templatesDir, srcRel);
  if (!existsSync(src)) {
    console.error('[init-project] 模板不存在：' + src);
    return false;
  }
  let content = readFileSync(src, 'utf-8');
  for (const [k, v] of Object.entries(replacements)) {
    content = content.replaceAll(`{${k}}`, v);
  }
  writeFileSync(dst, content);
  return true;
}

const ts = new Date().toISOString();

// 项目级 index.md
copyTemplate('agent-team-log-index.md', join(opencodeDir, 'index.md'), {
  project_name: projectName,
  timestamp: ts,
});

// round-1 子文件
copyTemplate('round-plan.md', join(round1Dir, 'plan.md'), { round: '1', timestamp: ts });
copyTemplate('round-review.md', join(round1Dir, 'review.md'), { round: '1', timestamp: ts });
copyTemplate('round-test.md', join(round1Dir, 'test.md'), { round: '1', timestamp: ts });
copyTemplate('round-integration.md', join(round1Dir, 'integration.md'), { round: '1', timestamp: ts });

// notepads
const notepadFiles = ['decisions.md', 'learnings.md', 'issues.md', 'verification.md', 'problems.md'];
for (const f of notepadFiles) {
  copyTemplate(`notepads/${f}`, join(notepadsDir, f), { project_name: projectName, timestamp: ts });
}

// shared-file-changes 占位
writeFileSync(join(sharedFileChangesDir, 'README.md'),
`# 共享文件变更协调

非集成负责人对 shared_files 的修改请求都汇集到这里。
集成负责人在所有模块开发完成后，统一合并并修改实际文件。

按轮次组织：每轮一个 round-N.md。
`);

console.log(JSON.stringify({ ok: true, opencode_dir: opencodeDir }, null, 2));
