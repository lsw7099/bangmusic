// openapi.yaml → Dart API 클라이언트 패키지(packages/bangmusic_api).
// 생성기: openapi-generator `dart-dio` + json_serializable. 앱(app/)은 이 패키지를 path 의존성으로 쓴다.
// 수작업 모델을 두지 않는다(01장 §3.3). 생성 결과는 직접 고치지 않는다.
//
// 1단계(Java 필요): 소스 생성
// 2단계(Dart 필요): build_runner로 *.g.dart 생성. Dart/Flutter가 없으면 건너뛰고 알린다.
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const outDir = resolve(root, 'packages/bangmusic_api');
const cli = resolve(root, 'node_modules/@openapitools/openapi-generator-cli/main.js');

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { stdio: 'inherit', cwd: root, ...opts });
  if (r.error) throw r.error;
  if (r.status !== 0) process.exit(r.status ?? 1);
}

// 이전 생성물을 지워 삭제된 모델이 남지 않게 한다.
rmSync(outDir, { recursive: true, force: true });

run(process.execPath, [
  cli,
  'generate',
  '-g', 'dart-dio',
  '-i', 'docs/design/openapi.yaml',
  '-o', 'packages/bangmusic_api',
  '--additional-properties',
  [
    'pubName=bangmusic_api',
    // CLI 래퍼가 인자를 공백으로 다시 나누므로 값에 공백을 넣지 않는다.
    'pubDescription=BangMusic_API_client_generated_from_openapi.yaml',
    'serializationLibrary=json_serializable',
    'dateLibrary=core',
    'nullableFields=true',
    // 계약 공통 규칙: 앱은 모르는 enum 값을 무시해야 한다(/v1에 enum 값이 추가될 수 있다).
    // 이 옵션이 없으면 새 서버가 보낸 새 값에서 역직렬화가 실패한다.
    'enumUnknownDefaultCase=true',
  ].join(','),
  '--global-property', 'apiTests=false,modelTests=false,apiDocs=false,modelDocs=false',
]);

// 생성기가 쓰는 SDK 하한(3.5)은 최신 json_serializable이 내는 null-aware elements 문법(3.8+)보다 낮다.
const pubspecPath = resolve(outDir, 'pubspec.yaml');
const pubspec = readFileSync(pubspecPath, 'utf8');
const patched = pubspec.replace(/^(\s*sdk:\s*).*$/m, "$1'^3.8.0'");
if (patched === pubspec) throw new Error('pubspec.yaml에서 sdk 제약을 찾지 못했다');
writeFileSync(pubspecPath, patched);

const which = spawnSync(process.platform === 'win32' ? 'where' : 'which', ['dart'], { encoding: 'utf8' });
if (which.status !== 0) {
  console.warn('\n[gen:dart] dart 명령을 찾지 못해 build_runner 단계를 건너뛰었다.');
  console.warn('[gen:dart] Flutter 설치 후 다시 실행해야 *.g.dart가 생성된다.');
  process.exit(0);
}

const shell = process.platform === 'win32';
run('dart', ['pub', 'get'], { cwd: outDir, shell });
run('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs'], { cwd: outDir, shell });
if (!existsSync(resolve(outDir, 'lib'))) throw new Error('생성 결과에 lib/가 없다');
