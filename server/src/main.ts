#!/usr/bin/env node
// bangmusic-server 명령.
//   serve                              HTTP 서버
//   admin create <사용자이름>          첫 관리자 생성. 비밀번호는 대화형 입력(TTY) 또는 표준 입력 한 줄.
//                                      명령행 인자로 받지 않는다 (05장 §9.2).
//   admin password <사용자이름>        비밀번호 재설정(관리자·일반 모두). 입력 방식은 위와 같고, 대화형이면 두 번 묻는다.
//                                      그 사용자의 모든 세션을 끝낸다(API의 비밀번호 재설정과 같다).
//   library add <이름> <경로>          라이브러리 등록 (경로는 서버 내부 값, API 비공개)
//   library list
//   scan [<library_id>] [--force]      즉시 스캔 (--force: 대량 누락 보류를 무시하고 적용)
//   backup                             스냅샷 만들기 (01장 §5.2)
//   backup list
//   restore <스냅샷>                   복원 (서버가 멈춘 상태에서, 01장 §5.3)
//   maintenance on|off                 점검 모드 (서버 정보 외 503 maintenance)
//   healthcheck                        로컬 서버 응답 확인 (컨테이너 healthcheck)
import { existsSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createInterface } from 'node:readline';
import { addLibrary, createUser, updateUser } from './admin.ts';
import { normUsername } from './auth/sessions.ts';
import { createBackup, invalidateAccessTokens, listBackups, restoreBackup } from './backup.ts';
import { loadConfig } from './config.ts';
import { dbPath, openCtx, type Ctx } from './ctx.ts';
import { buildApp } from './http/app.ts';
import { recoverCache, registerTranscodeJob } from './media/transcode.ts';
import { registerScanJob, scanLibrary } from './scanner/scan.ts';

function readPassword(prompt: string): Promise<string> {
  return new Promise((resolve) => {
    if (!process.stdin.isTTY) {
      // 파이프 입력: 첫 줄
      let buf = '';
      process.stdin.setEncoding('utf8');
      process.stdin.on('data', (d) => { buf += d; });
      process.stdin.on('end', () => resolve(buf.split(/\r?\n/)[0] ?? ''));
      return;
    }
    const rl = createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    const out = rl as unknown as { _writeToOutput: (s: string) => void; output: NodeJS.WriteStream };
    process.stdout.write(prompt);
    out._writeToOutput = () => { /* 입력을 화면에 표시하지 않는다 */ };
    rl.question('', (answer) => {
      rl.close();
      process.stdout.write('\n');
      resolve(answer);
    });
  });
}

function registerBackupJob(ctx: Ctx) {
  ctx.jobs.register('backup', async (job) => {
    const dir = createBackup(ctx.store, ctx.config, job.ref_id ?? 'daily');
    ctx.log.info({ dir }, '백업 완료');
  });
}

/** 매일 BACKUP_HOUR_UTC 시에 한 번 (01장 §5.2). 오늘 이미 있으면 건너뛴다. */
function scheduleDailyBackup(ctx: Ctx): NodeJS.Timeout | null {
  if (ctx.config.backupHourUtc < 0) return null;
  const tick = () => {
    const now = new Date();
    if (now.getUTCHours() !== ctx.config.backupHourUtc) return;
    const today = now.toISOString().slice(0, 10).replace(/-/g, '');
    if (listBackups(ctx.config).some((b) => b.startsWith(today) && b.endsWith('-daily'))) return;
    ctx.jobs.enqueue('backup', 'daily');
  };
  const t = setInterval(tick, 10 * 60 * 1000);
  t.unref();
  return t;
}

export function startServer(ctx: Ctx) {
  registerScanJob(ctx);
  registerTranscodeJob(ctx);
  registerBackupJob(ctx);
  ctx.jobs.recover();
  recoverCache(ctx);
  ctx.jobs.kick();
  const app = buildApp(ctx);
  const timer = scheduleDailyBackup(ctx);
  app.addHook('onClose', async () => {
    if (timer) clearInterval(timer);
  });
  return app;
}

async function main(argv: string[]) {
  const [cmd, sub, ...rest] = argv;
  const config = loadConfig();
  if (cmd === 'healthcheck') {
    const res = await fetch(`http://127.0.0.1:${config.port}/v1/server`).catch(() => null);
    process.exit(res && res.ok ? 0 : 1);
  }
  if (cmd === 'restore') {
    // DB를 열기 전에 교체해야 하므로 openCtx보다 먼저
    if (!sub) throw new Error('사용법: restore <스냅샷 폴더 또는 이름>');
    const r = restoreBackup(config, dbPath(config), sub);
    const ctx = openCtx(config); // 필요한 마이그레이션 적용
    registerTranscodeJob(ctx);
    recoverCache(ctx); // 캐시 파일이 없는 변환 렌디션 정리
    invalidateAccessTokens(ctx.store); // 리프레시는 유지 → 앱은 자동 갱신으로 복귀
    ctx.store.close();
    console.log(`복원 완료. 이전 DB 보관: ${r.preRestore ?? '(없음)'}`);
    return;
  }
  if (cmd === 'maintenance') {
    const flag = join(config.dataDir, 'MAINTENANCE');
    if (sub === 'on') writeFileSync(flag, new Date().toISOString() + '\n');
    else if (sub === 'off') rmSync(flag, { force: true });
    else throw new Error('사용법: maintenance on|off');
    console.log(`점검 모드: ${existsSync(flag) ? '켜짐' : '꺼짐'}`);
    return;
  }
  const ctx = openCtx(config);
  switch (cmd) {
    case 'serve': {
      const app = startServer(ctx);
      await app.listen({ host: config.host, port: config.port });
      const pidFile = join(config.dataDir, 'server.pid');
      writeFileSync(pidFile, String(process.pid));
      const stop = async () => {
        await app.close();
        await ctx.jobs.stop();
        ctx.store.close();
        rmSync(pidFile, { force: true });
        process.exit(0);
      };
      process.on('SIGTERM', stop);
      process.on('SIGINT', stop);
      return;
    }
    case 'admin': {
      if (sub === 'password' && rest[0]) {
        const row = ctx.store.get<{ id: string; username: string }>('SELECT id, username FROM users WHERE username = ? AND deleted_at IS NULL', normUsername(rest[0]));
        if (!row) throw new Error(`사용자 없음: ${rest[0]}`);
        const pw = await readPassword('새 비밀번호(10자 이상): ');
        if (process.stdin.isTTY && (await readPassword('한 번 더: ')) !== pw) throw new Error('두 번 입력한 비밀번호가 다릅니다. 바꾸지 않았습니다.');
        if (pw.length < 10) throw new Error('비밀번호는 10자 이상이어야 합니다. 바꾸지 않았습니다.');
        updateUser(ctx, row.id, { new_password: pw });
        console.log(`비밀번호 재설정: ${row.username} (모든 세션을 끝냈습니다. 앱에서 새 비밀번호로 로그인하세요)`);
        break;
      }
      if (sub !== 'create' || !rest[0]) throw new Error('사용법: admin create <사용자이름> | admin password <사용자이름>');
      const pw = await readPassword('비밀번호(10자 이상): ');
      const u = createUser(ctx, { username: rest[0], password: pw, role: 'admin' });
      console.log(`관리자 생성: ${u.username} (${u.id})`);
      break;
    }
    case 'library': {
      if (sub === 'add' && rest[0] && rest[1]) {
        const lib = addLibrary(ctx, rest[0], rest[1]);
        console.log(`라이브러리 등록: ${lib.name} (${lib.id})`);
      } else if (sub === 'list') {
        for (const l of ctx.store.all<{ id: string; name: string; status: string }>('SELECT id, name, status FROM libraries ORDER BY name')) {
          console.log(`${l.id}\t${l.status}\t${l.name}`);
        }
      } else {
        throw new Error('사용법: library add <이름> <경로> | library list');
      }
      break;
    }
    case 'scan': {
      const force = argv.includes('--force');
      const ids = sub && !sub.startsWith('--') ? [sub] : ctx.store.all<{ id: string }>('SELECT id FROM libraries').map((r) => r.id);
      for (const id of ids) console.log(id, JSON.stringify(await scanLibrary(ctx, id, { force })));
      break;
    }
    case 'backup': {
      if (sub === 'list') for (const b of listBackups(config)) console.log(b);
      else console.log(`백업: ${createBackup(ctx.store, config, 'manual')}`);
      break;
    }
    default:
      throw new Error('명령: serve | admin create|password | library add|list | scan | backup [list] | restore | maintenance on|off | healthcheck');
  }
  ctx.store.close();
}

const isEntry = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop()!);
if (isEntry) {
  main(process.argv.slice(2)).catch((e) => {
    console.error((e as Error).message);
    process.exit(1);
  });
}
