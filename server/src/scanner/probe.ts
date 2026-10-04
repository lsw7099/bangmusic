// ffprobe/ffmpeg 호출. 인자 배열로 직접 실행하고(셸 미사용), 시간 제한을 둔다 (03장 §4.6).
import { spawn } from 'node:child_process';
import { setPriority } from 'node:os';
import { createHash } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { extname } from 'node:path';

export interface RunResult {
  code: number | null;
  stdout: Buffer;
  stderr: string;
  timedOut: boolean;
}

export function run(cmd: string, args: string[], opts: { timeoutMs?: number; input?: Buffer; maxOut?: number; lowPriority?: boolean } = {}): Promise<RunResult> {
  return new Promise((resolveRun, reject) => {
    const child = spawn(cmd, args, { stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
    if (opts.lowPriority && child.pid) {
      try { setPriority(child.pid, 10); } catch { /* 권한·플랫폼에 따라 실패할 수 있다 */ }
    }
    const out: Buffer[] = [];
    let outLen = 0;
    let err = '';
    let timedOut = false;
    const max = opts.maxOut ?? 64 * 1024 * 1024;
    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGKILL');
    }, opts.timeoutMs ?? 30_000);
    child.stdout.on('data', (d: Buffer) => {
      outLen += d.length;
      if (outLen > max) child.kill('SIGKILL');
      else out.push(d);
    });
    child.stderr.on('data', (d: Buffer) => {
      if (err.length < 8192) err += d.toString();
    });
    child.on('error', (e) => {
      clearTimeout(timer);
      reject(e);
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      resolveRun({ code, stdout: Buffer.concat(out), stderr: err, timedOut });
    });
    child.stdin.on('error', () => { /* 프로세스가 먼저 끝난 경우 */ });
    child.stdin.end(opts.input);
  });
}

export interface ProbeTags {
  title?: string;
  artist?: string;
  album?: string;
  album_artist?: string;
  track?: string;
  disc?: string;
  date?: string;
  genre?: string;
  title_sort?: string;
  artist_sort?: string;
  album_sort?: string;
  lyrics?: string;
}

export interface ProbeResult {
  container: string;
  codec: string;
  mime: string;
  durationMs: number;
  bitrate: number | null;
  sampleRate: number | null;
  channels: number | null;
  bitDepth: number | null;
  tags: ProbeTags;
  hasEmbeddedCover: boolean;
}

export class ProbeError extends Error {}

const TAG_KEYS: Record<string, keyof ProbeTags> = {
  title: 'title', artist: 'artist', album: 'album', album_artist: 'album_artist', albumartist: 'album_artist',
  'album artist': 'album_artist', track: 'track', tracknumber: 'track', disc: 'disc', discnumber: 'disc',
  date: 'date', year: 'date', genre: 'genre',
  titlesort: 'title_sort', 'title-sort': 'title_sort', sort_name: 'title_sort', tsot: 'title_sort',
  artistsort: 'artist_sort', 'artist-sort': 'artist_sort', sort_artist: 'artist_sort', tsop: 'artist_sort',
  albumsort: 'album_sort', 'album-sort': 'album_sort', sort_album: 'album_sort', tsoa: 'album_sort',
  lyrics: 'lyrics', unsyncedlyrics: 'lyrics', 'unsynced lyrics': 'lyrics', uslt: 'lyrics',
};

function container(formatName: string, ext: string): string {
  const f = formatName.split(',');
  if (f.includes('mp4') || f.includes('m4a') || f.includes('mov')) return 'm4a';
  if (f[0] === 'ogg') return 'ogg';
  if (f[0] === 'wav') return 'wav';
  if (f[0] === 'aiff') return 'aiff';
  if (f[0] === 'flac') return 'flac';
  if (f[0] === 'mp3') return 'mp3';
  return f[0] || ext;
}

export function mimeFor(container: string, codec: string): string {
  switch (container) {
    case 'flac': return 'audio/flac';
    case 'mp3': return 'audio/mpeg';
    case 'm4a': return 'audio/mp4';
    case 'ogg': return codec === 'opus' ? 'audio/ogg; codecs=opus' : 'audio/ogg';
    case 'wav': return 'audio/wav';
    case 'aiff': return 'audio/aiff';
    default: return 'application/octet-stream';
  }
}

const intOrNull = (v: unknown): number | null => {
  const n = Number.parseInt(String(v ?? ''), 10);
  return Number.isFinite(n) && n > 0 ? n : null;
};

export async function probe(ffprobe: string, file: string): Promise<ProbeResult> {
  const r = await run(ffprobe, ['-v', 'error', '-print_format', 'json', '-show_format', '-show_streams', '-i', file], { timeoutMs: 30_000 });
  if (r.timedOut) throw new ProbeError('ffprobe 시간 초과');
  if (r.code !== 0) throw new ProbeError(`ffprobe 실패: ${r.stderr.trim().slice(0, 200)}`);
  let j: { format?: Record<string, unknown> & { tags?: Record<string, string> }; streams?: Array<Record<string, unknown> & { tags?: Record<string, string>; disposition?: Record<string, number> }> };
  try {
    j = JSON.parse(r.stdout.toString('utf8'));
  } catch {
    throw new ProbeError('ffprobe 출력 해석 실패');
  }
  const streams = j.streams ?? [];
  const audio = streams.find((s) => s.codec_type === 'audio');
  if (!audio || !j.format) throw new ProbeError('오디오 스트림 없음');
  const durationS = Number(j.format.duration ?? audio.duration);
  if (!Number.isFinite(durationS) || durationS <= 0) throw new ProbeError('길이를 알 수 없음');

  // 파일 전체 태그(MP3 ID3, FLAC Vorbis comment, MP4 ilst)가 먼저, 스트림 태그(Ogg·Opus는 여기에만 있음)는 빈 항목만 채운다.
  // 스트림 태그를 먼저 보면, 태그를 고칠 때 옛 FFmpeg(6.1)가 스트림 쪽에 남긴 옛 제목이 이겼다(CI에서 발견).
  const tags: ProbeTags = {};
  for (const src of [j.format.tags ?? {}, audio.tags ?? {}]) {
    for (const [k, v] of Object.entries(src)) {
      const key = TAG_KEYS[k.toLowerCase()] ?? (/^lyrics-/i.test(k) ? 'lyrics' : undefined);
      if (key && typeof v === 'string' && v.trim() && tags[key] === undefined) tags[key] = v.trim();
    }
  }
  const codec = String(audio.codec_name ?? 'unknown');
  const cont = container(String(j.format.format_name ?? ''), extname(file).slice(1).toLowerCase());
  const bitDepth = intOrNull(audio.bits_per_raw_sample) ?? intOrNull(audio.bits_per_sample);
  return {
    container: cont,
    codec,
    mime: mimeFor(cont, codec),
    durationMs: Math.round(durationS * 1000),
    bitrate: intOrNull(j.format.bit_rate) ?? intOrNull(audio.bit_rate),
    sampleRate: intOrNull(audio.sample_rate),
    channels: intOrNull(audio.channels),
    bitDepth: ['mp3', 'aac', 'opus', 'vorbis'].includes(codec) ? null : bitDepth,
    tags,
    hasEmbeddedCover: streams.some((s) => s.codec_type === 'video' && s.disposition?.attached_pic === 1),
  };
}

/** 태그를 제외한 오디오 패킷의 해시 (01장 §4.3 audio_fingerprint). 태그만 고친 뒤 이동한 파일을 찾는 데 쓴다. */
export async function audioFingerprint(ffmpeg: string, file: string): Promise<string | null> {
  const r = await run(ffmpeg, ['-nostdin', '-v', 'error', '-protocol_whitelist', 'file,pipe', '-i', file, '-map', '0:a:0', '-c', 'copy', '-f', 'hash', '-hash', 'sha256', '-'], { timeoutMs: 120_000 });
  const m = /SHA256=([0-9a-f]{64})/.exec(r.stdout.toString());
  return r.code === 0 && m ? m[1]! : null;
}

export function fileSha256(file: string): Promise<string> {
  return new Promise((ok, fail) => {
    const h = createHash('sha256');
    createReadStream(file)
      .on('data', (d) => h.update(d))
      .on('error', fail)
      .on('end', () => ok(h.digest('hex')));
  });
}
