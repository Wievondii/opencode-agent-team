#!/usr/bin/env node
// agent-team/scripts/check-budget.mjs
// 查询 boulder.json 当前预算消耗状况。
// 用法：node check-budget.mjs [<kind>]
//   kind 省略时返回所有预算；指定时只返回该项。
import { existsSync, readFileSync } from 'node:fs';
import { getBoulderPath } from './lib/paths.mjs';

const kind = process.argv[2];
const boulderPath = getBoulderPath();
if (!existsSync(boulderPath)) {
  console.error('boulder.json 不存在');
  process.exit(1);
}

const boulder = JSON.parse(readFileSync(boulderPath, 'utf-8'));
const budgets = boulder.budgets ?? {};

function summary(b) {
  return {
    used: b.used,
    max: b.max,
    remaining: b.max - b.used,
    exhausted: b.used >= b.max,
  };
}

if (kind) {
  if (!budgets[kind]) {
    console.error('未知 kind：' + kind);
    process.exit(2);
  }
  console.log(JSON.stringify(summary(budgets[kind]), null, 2));
} else {
  const out = {};
  for (const [k, v] of Object.entries(budgets)) {
    out[k] = summary(v);
  }
  console.log(JSON.stringify(out, null, 2));
}
