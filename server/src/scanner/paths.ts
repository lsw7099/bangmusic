// 경로 해석기 (01장 §3.2). 파일 경로를 다루는 코드는 이 파일로 제한한다.
// 1. 입력은 (라이브러리, DB에서 읽은 상대 경로)뿐이다. HTTP 요청 문자열은 입력이 될 수 없다.
// 2. realpath 결과가 라이브러리 루트의 realpath 하위가 아니면 거부한다(심볼릭 링크 탈출 차단).
// 3. 일반 파일이 아니면 거부한다.
// 4. 연 디스크립터를 fstat 해 크기·mtime이 DB와 다르면 "원본 변경"으로 처리한다(호출자가 비교).
import { constants, promises as fsp, readdirSync, realpathSync, statSync } from 'node:fs';
import { isAbsolute, join, relative, sep } from 'node:path';

export interface LibraryRow {
  id: string;
  name: string;
  root_path: string;
  root_real: string;
  status: 'online' | 'unavailable';
  last_scan_at: number | null;
  pending_review: number;
}

export const MARKER = '.bangmusic-library';

/** 저장소 자체에 닿을 수 없음 (마운트 해제, I/O 오류, 루트 바뀜) → 503 storage_unavailable */
export class StorageUnavailable extends Error {}
/** 파일만 없음 → 404 media_missing */
export class FileMissing extends Error {}
/** 루트 밖을 가리킴, 일반 파일 아님 → 거부 (응답에는 경로를 넣지 않는다) */
export class PathRejected extends Error {}

const STORAGE_CODES = new Set(['EIO', 'ENOTCONN', 'ESTALE', 'ENODEV', 'ENXIO', 'EHOSTDOWN', 'ETIMEDOUT']);

/** 라이브러리 루트를 확인한다. 등록 시 고정한 realpath와 다르면(SEC-04) 사용 불가. */
export function checkRoot(lib: LibraryRow): string {
  let real: string;
  try {
    real = realpathSync.native(lib.root_path);
    if (!statSync(real).isDirectory()) throw new Error('not a directory');
  } catch (e) {
    throw new StorageUnavailable(`라이브러리 루트에 접근할 수 없음: ${lib.id} (${(e as NodeJS.ErrnoException).code ?? (e as Error).message})`);
  }
  if (real !== lib.root_real) throw new StorageUnavailable(`라이브러리 루트의 실제 경로가 등록 시와 다름: ${lib.id}`);
  return real;
}

/** 루트가 비었다(표식도 없음) = 마운트가 빠져 빈 마운트 지점만 남은 상태로 본다. 스캔 판정과 같은 규칙 (01장 §4.4) */
export function rootLooksEmpty(root: string): boolean {
  try {
    return !readdirSync(root).some((n) => n === MARKER || !n.startsWith('.'));
  } catch {
    return true;
  }
}

/** 파일이 없을 때: 루트가 비었으면 파일 하나가 아니라 저장소 전체 문제(503)다. FN-07 실서버에서 첫 요청이 404로 나간 것을 고침 */
function missing(root: string, lib: LibraryRow, relPath: string): Error {
  return rootLooksEmpty(root) ? new StorageUnavailable(`라이브러리 루트가 비어 있음(마운트 해제?): ${lib.id}`) : new FileMissing(`파일 없음: ${lib.id}/${relPath}`);
}

export function isInside(root: string, candidate: string): boolean {
  const rel = relative(root, candidate);
  return rel !== '' && !rel.startsWith('..') && !isAbsolute(rel);
}

/** DB의 상대 경로('/' 구분)를 실제 경로로. 루트 밖이면 PathRejected. */
export async function resolveFile(lib: LibraryRow, relPath: string): Promise<string> {
  const root = checkRoot(lib);
  if (relPath.includes('\0')) throw new PathRejected('NUL');
  const joined = join(root, ...relPath.split('/'));
  if (!isInside(root, joined)) throw new PathRejected(`루트 밖 상대 경로: ${lib.id}`);
  let real: string;
  try {
    real = await fsp.realpath(joined);
  } catch (e) {
    const code = (e as NodeJS.ErrnoException).code ?? '';
    if (code === 'ENOENT' || code === 'ENOTDIR') throw missing(root, lib, relPath);
    if (STORAGE_CODES.has(code)) throw new StorageUnavailable(`저장소 오류 ${code}: ${lib.id}`);
    throw e;
  }
  if (!isInside(root, real)) throw new PathRejected(`루트 밖을 가리키는 링크: ${lib.id}/${relPath}`);
  return real;
}

export interface OpenedFile {
  handle: fsp.FileHandle;
  size: number;
  mtimeNs: string;
}

/** 해석 + 열기 + fstat. 일반 파일만. */
export async function openFile(lib: LibraryRow, relPath: string): Promise<OpenedFile> {
  const real = await resolveFile(lib, relPath);
  const root = lib.root_real;
  let handle: fsp.FileHandle;
  try {
    handle = await fsp.open(real, constants.O_RDONLY);
  } catch (e) {
    const code = (e as NodeJS.ErrnoException).code ?? '';
    if (code === 'ENOENT') throw missing(root, lib, relPath);
    if (STORAGE_CODES.has(code)) throw new StorageUnavailable(`저장소 오류 ${code}: ${lib.id}`);
    throw e;
  }
  const st = await handle.stat({ bigint: true });
  if (!st.isFile()) {
    await handle.close();
    throw new PathRejected(`일반 파일 아님: ${lib.id}/${relPath}`);
  }
  return { handle, size: Number(st.size), mtimeNs: st.mtimeNs.toString() };
}

export function toRel(root: string, abs: string): string {
  return relative(root, abs).split(sep).join('/');
}
