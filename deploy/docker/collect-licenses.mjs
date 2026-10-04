// node_modules의 운영 의존성 라이선스를 모은다: <out>/<이름>@<버전>/LICENSE*, <out>/SUMMARY.tsv
// 허용 목록 밖(GPL·AGPL 등, 05장 §8.5)이면 경고를 남긴다 — 빌드를 멈출지는 사람이 판단.
import { readdirSync, readFileSync, existsSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const [root, out] = process.argv.slice(2);
const allowed = /^(MIT|ISC|BSD-2-Clause|BSD-3-Clause|Apache-2\.0|0BSD|BlueOak-1\.0\.0|CC0-1\.0|Unlicense|Python-2\.0)$/;
const rows = [];
const warn = [];

function visit(dir) {
  for (const name of readdirSync(dir)) {
    if (name.startsWith('.')) continue;
    const p = join(dir, name);
    if (name.startsWith('@')) { visit(p); continue; }
    const pj = join(p, 'package.json');
    if (!existsSync(pj)) continue;
    const pkg = JSON.parse(readFileSync(pj, 'utf8'));
    const lic = typeof pkg.license === 'string' ? pkg.license : (pkg.license?.type ?? 'UNKNOWN');
    const dest = join(out, `${pkg.name.replace('/', '__')}@${pkg.version}`);
    mkdirSync(dest, { recursive: true });
    const files = readdirSync(p).filter((f) => /^(licen[cs]e|copying|notice)/i.test(f));
    for (const f of files) copyFileSync(join(p, f), join(dest, f));
    rows.push([pkg.name, pkg.version, lic, files.length ? files.join(',') : '(파일 없음)'].join('\t'));
    if (!lic.split(/ OR |[()]/).map((s) => s.trim()).filter(Boolean).some((l) => allowed.test(l))) warn.push(`${pkg.name}@${pkg.version} ${lic}`);
    if (existsSync(join(p, 'node_modules'))) visit(join(p, 'node_modules'));
  }
}
visit(root);
rows.sort();
writeFileSync(join(out, 'SUMMARY.tsv'), 'name\tversion\tlicense\tfiles\n' + rows.join('\n') + '\n');
console.log(`라이선스 ${rows.length}개 수집`);
if (warn.length) console.log('허용 목록 밖(검토 필요):\n  ' + warn.join('\n  '));
