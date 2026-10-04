#!/usr/bin/env node
// 개발 환경 점검 (05장 §10.1). 설치는 하지 않고 있는지·버전만 확인한다.
// 사용: node tools/doctor.mjs   (필수 항목이 없으면 종료 코드 1)
import { spawnSync } from 'node:child_process';

const isWin = process.platform === 'win32';

function probe(cmd, args) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', shell: isWin, timeout: 60_000 });
  if (r.error || r.status !== 0) return null;
  return `${r.stdout}\n${r.stderr}`.trim().split(/\r?\n/).find((l) => l.trim()) ?? '';
}

const nodeMajor = Number(process.versions.node.split('.')[0]);
const checks = [
  { name: 'Node.js LTS', need: '서버 개발', required: true,
    result: () => (nodeMajor % 2 === 0 && nodeMajor >= 24 ? `v${process.versions.node}` : null),
    hint: 'Node 24 이상 짝수(LTS) 버전' },
  { name: 'FFmpeg', need: '합성 음원, 변환', required: true, result: () => probe('ffmpeg', ['-version']),
    hint: isWin ? 'winget install Gyan.FFmpeg' : 'apt install ffmpeg' },
  { name: 'ffprobe', need: '스캐너 태그 추출', required: true, result: () => probe('ffprobe', ['-version']),
    hint: 'FFmpeg에 포함' },
  { name: 'SQLite CLI', need: 'DB 확인(선택)', required: false, result: () => probe('sqlite3', ['--version']),
    hint: isWin ? 'winget install SQLite.SQLite' : 'apt install sqlite3' },
  { name: 'Docker', need: '서버 이미지 빌드', required: true, result: () => probe('docker', ['--version']),
    hint: isWin ? 'Docker Desktop(WSL2) 또는 Linux VM' : 'Docker Engine' },
  { name: 'Java (JDK)', need: 'Android 빌드, Dart 클라이언트 생성', required: true, result: () => probe('java', ['-version']),
    hint: 'JDK 17 이상' },
  { name: 'Flutter', need: '앱 개발', required: true, result: () => probe('flutter', ['--version']),
    hint: 'Flutter SDK 설치 후 flutter doctor' },
  { name: 'adb', need: '실기기 설치', required: true, result: () => probe('adb', ['version']),
    hint: 'Android SDK platform-tools를 PATH에 추가' },
];

let missing = 0;
for (const c of checks) {
  const v = c.result();
  const mark = v ? '✓' : c.required ? '✗' : '–';
  if (!v && c.required) missing++;
  console.log(`${mark} ${c.name.padEnd(12)} ${v ? v.slice(0, 70) : `없음 → ${c.hint}`}   (${c.need})`);
}
console.log(missing ? `\n필수 항목 ${missing}개 없음` : '\n필수 항목 모두 있음');
process.exit(missing ? 1 : 0);
