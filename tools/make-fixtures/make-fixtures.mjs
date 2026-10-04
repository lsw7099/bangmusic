#!/usr/bin/env node
// 개발·테스트용 합성 음원 세트 생성기 (05장 §10.2).
// 실제 음원은 저장소·CI·데모 서버에 넣지 않는다. 이 스크립트가 FFmpeg로 매번 만든다.
//
// 사용: node tools/make-fixtures/make-fixtures.mjs [--out fixtures] [--quick] [--clean]
//   --quick  60분 음원을 건너뛴다 (CI의 빠른 확인용)
//   --clean  출력 폴더를 지우고 다시 만든다
// FFmpeg 경로는 PATH 또는 환경 변수 FFMPEG, FFPROBE로 지정한다.
//
// 결과: <out>/lib1, <out>/lib2, <out>/manifest.json
// manifest.json에는 파일별 용도, 기대 메타데이터, 음높이 계단 매개변수, SHA-256이 있다.
// 테스트는 manifest만 보고 기대값을 얻는다(파일 이름에서 추측하지 않는다).

import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  copyFileSync, existsSync, mkdirSync, readFileSync, renameSync, rmSync,
  statSync, symlinkSync, truncateSync, writeFileSync,
} from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const args = process.argv.slice(2);
const opt = (name) => args.includes(name);
const outArg = args.indexOf('--out');
const OUT = resolve(repoRoot, outArg >= 0 ? args[outArg + 1] : 'fixtures');
const QUICK = opt('--quick');
const FFMPEG = process.env.FFMPEG || 'ffmpeg';
const FFPROBE = process.env.FFPROBE || 'ffprobe';

const manifest = { generated_by: 'tools/make-fixtures', ffmpeg: null, files: [], skipped: [] };

// ── 공통 ────────────────────────────────────────────────────────────

function ff(argv, what) {
  const r = spawnSync(FFMPEG, ['-hide_banner', '-loglevel', 'error', '-nostdin', '-y', ...argv], {
    encoding: 'utf8',
  });
  if (r.error) throw new Error(`${what}: FFmpeg 실행 실패 (${r.error.code}). PATH 또는 FFMPEG 환경 변수를 확인`);
  if (r.status !== 0) throw new Error(`${what}: FFmpeg 오류\n${r.stderr}`);
}

function ffmpegVersion() {
  const r = spawnSync(FFMPEG, ['-version'], { encoding: 'utf8' });
  if (r.error || r.status !== 0) {
    console.error('FFmpeg를 찾지 못했다. 설치 후 PATH에 넣거나 FFMPEG=<경로>로 지정한다.');
    process.exit(2);
  }
  return r.stdout.split('\n')[0].trim();
}

function sha256(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}

function rel(p) {
  return relative(OUT, p).split(sep).join('/');
}

function record(file, meta) {
  const st = statSync(file);
  manifest.files.push({ path: rel(file), size: st.size, sha256: sha256(file), ...meta });
}

function skip(what, reason) {
  console.warn(`  건너뜀: ${what} — ${reason}`);
  manifest.skipped.push({ what, reason });
}

// ── 신호 ────────────────────────────────────────────────────────────

// 음높이 계단: step_s초마다 step_hz씩 올라간다. 탐색 후 재생된 구간의 주파수로 위치를 판정한다.
// 긴 음원에서도 최고 주파수가 8kHz를 넘지 않게 step_hz를 줄인다.
function staircase(durationS, stepS = 10) {
  const steps = Math.ceil(durationS / stepS);
  const baseHz = 220;
  const stepHz = Math.max(1, Math.min(110, Math.floor((8000 - baseHz) / steps)));
  return {
    signal: { kind: 'staircase', base_hz: baseHz, step_hz: stepHz, step_s: stepS },
    expr: `0.5*sin(2*PI*(${baseHz}+${stepHz}*floor(t/${stepS}))*t)`,
  };
}

// 실기기 청취 확인용: 10초 구간 n(0부터)마다 "삑"이 n+1번 울린다.
function beeps(stepS = 10) {
  const n = `(floor(t/${stepS})+1)`;
  const u = `mod(t,${stepS})`;
  const on = `lt(floor(${u}/0.3),${n})*lt(mod(${u},0.3),0.15)*lt(${u},${stepS - 0.5})`;
  return {
    signal: { kind: 'beeps', step_s: stepS, beep_hz: 880 },
    expr: `0.5*sin(2*PI*880*t)*${on}`,
  };
}

const CODECS = {
  'mp3-cbr': { ext: 'mp3', args: ['-c:a', 'libmp3lame', '-b:a', '192k'], cover: true },
  'mp3-vbr': { ext: 'mp3', args: ['-c:a', 'libmp3lame', '-q:a', '4'], cover: true },
  'flac-16': { ext: 'flac', args: ['-c:a', 'flac', '-sample_fmt', 's16'], cover: true },
  'flac-24': { ext: 'flac', args: ['-c:a', 'flac', '-sample_fmt', 's32', '-bits_per_raw_sample', '24'], cover: true },
  'm4a-aac': { ext: 'm4a', args: ['-c:a', 'aac', '-b:a', '256k'], cover: true },
  'm4a-alac': { ext: 'm4a', args: ['-c:a', 'alac'], cover: true },
  'ogg-vorbis': { ext: 'ogg', args: ['-c:a', 'libvorbis', '-q:a', '5'], cover: false },
  opus: { ext: 'opus', args: ['-c:a', 'libopus', '-b:a', '128k'], cover: false, rate: 48000 },
  wav: { ext: 'wav', args: ['-c:a', 'pcm_s16le'], cover: false },
};

// 형식별 정렬 태그 키. FFmpeg의 컨테이너별 태그 대응표를 따른다.
function sortTagArgs(codec, sort) {
  if (!sort) return [];
  const fmt = CODECS[codec].ext;
  const keys =
    fmt === 'm4a' ? { title: 'sort_name', artist: 'sort_artist', album: 'sort_album' }
    : fmt === 'mp3' ? { title: 'title-sort', artist: 'artist-sort', album: 'album-sort' }
    : fmt === 'wav' ? null
    : { title: 'TITLESORT', artist: 'ARTISTSORT', album: 'ALBUMSORT' };
  if (!keys) return [];
  return Object.entries(sort).flatMap(([k, v]) => ['-metadata', `${keys[k]}=${v}`]);
}

/**
 * 음원 1개 생성.
 * @param {object} o
 * @param {string} o.file     출력 경로(확장자 포함)
 * @param {string} o.codec    CODECS 키
 * @param {number} o.duration 초
 * @param {object} [o.tags]   { title, artist, album, album_artist, track, disc, date, genre }
 * @param {object} [o.sort]   { title, artist, album }
 * @param {string} [o.cover]  내장할 이미지 경로
 * @param {object} [o.signal] staircase()/beeps() 결과
 */
function makeAudio(o) {
  const c = CODECS[o.codec];
  const sig = o.signal ?? staircase(o.duration);
  const rate = c.rate ?? 44100;
  mkdirSync(dirname(o.file), { recursive: true });
  // 긴 경로·특수문자 이름은 FFmpeg에 넘기지 않고 임시 이름으로 만든 뒤 옮긴다.
  const tmp = join(OUT, `.tmp-${process.pid}.${c.ext}`);
  const argv = ['-f', 'lavfi', '-i', `aevalsrc='${sig.expr}':s=${rate}:d=${o.duration}`];
  const withCover = o.cover && c.cover;
  if (withCover) argv.push('-i', o.cover, '-map', '0:a', '-map', '1:v', '-c:v', 'mjpeg', '-disposition:v', 'attached_pic');
  argv.push(...c.args, '-ac', '2');
  if (c.ext === 'mp3') argv.push('-id3v2_version', '3');
  for (const [k, v] of Object.entries(o.tags ?? {})) argv.push('-metadata', `${k}=${v}`);
  argv.push(...sortTagArgs(o.codec, o.sort));
  if (!o.tags) argv.push('-map_metadata', '-1');
  argv.push(tmp);
  ff(argv, rel(o.file));
  renameSync(tmp, o.file);
  record(o.file, {
    kind: 'audio',
    codec: o.codec,
    duration_ms: o.duration * 1000,
    sample_rate: rate,
    tags: o.tags ?? null,
    sort: o.sort ?? null,
    embedded_cover: Boolean(withCover),
    signal: sig.signal,
    purpose: o.purpose ?? [],
  });
}

// 단색 배경 + 번호(testsrc 카운터) 표지. 번호로 어떤 표지가 쓰였는지 눈으로 구분한다.
function makeCover(file, { color, number, size = 600 }) {
  mkdirSync(dirname(file), { recursive: true });
  const box = Math.round(size * 0.4);
  ff([
    '-f', 'lavfi', '-i', `color=c=${color}:s=${size}x${size}:d=1`,
    '-f', 'lavfi', '-i', `testsrc=s=${box}x${box}:r=1:d=${number + 1}`,
    '-filter_complex', `[1:v]select=eq(n\\,${number})[n];[0:v][n]overlay=(W-w)/2:(H-h)/2`,
    '-frames:v', '1', '-q:v', '3', file,
  ], rel(file));
}

// ── 가사 ────────────────────────────────────────────────────────────

const ts = (s) => `[${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}.00]`;

function lrcLines(durationS, line) {
  const out = [];
  for (let s = 0; s < durationS; s += 10) out.push(`${ts(s)}${line(s / 10)}`);
  return out.join('\n') + '\n';
}

function writeText(file, text, purpose, extra = {}) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, text);
  record(file, { kind: 'sidecar', purpose, ...extra });
}

// ── 세트 ────────────────────────────────────────────────────────────

function buildFormats(lib) {
  // 형식 묶음: 같은 30초 신호를 형식별로. 원본 제공/변환 판정과 기기 재생 확인용.
  const dir = join(lib, '형식 모음 (Formats)');
  const cover = join(OUT, '.covers', 'formats.jpg');
  makeCover(cover, { color: '0x2f6fb0', number: 1 });
  let track = 1;
  for (const codec of Object.keys(CODECS)) {
    makeAudio({
      file: join(dir, `${String(track).padStart(2, '0')}-${codec}.${CODECS[codec].ext}`),
      codec,
      duration: 30,
      cover,
      tags: { title: `형식 ${codec}`, artist: '합성 악단', album: '형식 모음', album_artist: '합성 악단', track: String(track), date: '2026' },
      purpose: ['format'],
    });
    track++;
  }
}

function buildLengths(lib) {
  const dir = join(lib, '길이 모음 (Lengths)');
  const lengths = [
    { s: 1, codec: 'mp3-cbr', name: '01-one-second.mp3' },
    { s: 30, codec: 'mp3-cbr', name: '02-thirty-seconds.mp3' },
    { s: 300, codec: 'flac-16', name: '03-five-minutes.flac' },
    { s: 3600, codec: 'm4a-aac', name: '04-sixty-minutes.m4a' },
  ];
  for (const [i, l] of lengths.entries()) {
    if (QUICK && l.s >= 3600) { skip(`${l.name}`, '--quick'); continue; }
    makeAudio({
      file: join(dir, l.name),
      codec: l.codec,
      duration: l.s,
      tags: { title: `길이 ${l.s}초`, artist: '합성 악단', album: '길이 모음', track: String(i + 1) },
      purpose: ['length', ...(l.s >= 3600 ? ['ticket_expiry', 'long_seek'] : []), ...(l.s <= 1 ? ['short_transition'] : [])],
    });
  }
  // 실기기 청취용 "삑" 음원 (5분)
  makeAudio({
    file: join(dir, '05-beeps.m4a'),
    codec: 'm4a-aac',
    duration: 300,
    signal: beeps(),
    tags: { title: '삑 세기 (청취 확인용)', artist: '합성 악단', album: '길이 모음', track: '5' },
    purpose: ['listening_seek_check'],
  });
}

function buildMetadataAndLyrics(lib) {
  // 문서 예시 그대로의 일본어 앨범 + 가사 3종
  const dir = join(lib, '合成アルバム');
  const cover = join(dir, 'cover.jpg');
  makeCover(cover, { color: '0xb0402f', number: 2 });
  record(cover, { kind: 'folder_cover', purpose: ['folder_cover'] });

  const songs = [
    { file: '01-hikari.flac', title: '光の中へ', sort: 'ひかりのなかへ' },
    { file: '02-katakana.flac', title: 'ﾊﾝｶｸ ｶﾀｶﾅ と ＺＥＮＫＡＫＵ', sort: 'はんかくかたかなとぜんかく' },
    { file: '03-yoake.flac', title: '夜明けのうた', sort: 'よあけのうた' },
    { file: '04-no-sort.flac', title: '静かな夜', sort: null },
  ];
  for (const [i, s] of songs.entries()) {
    makeAudio({
      file: join(dir, s.file),
      codec: 'flac-16',
      duration: 60,
      tags: { title: s.title, artist: 'テスト楽団', album: '合成アルバム', album_artist: 'テスト楽団', track: String(i + 1), date: '2026', genre: 'J-Pop' },
      sort: s.sort ? { title: s.sort, artist: 'てすとがくだん', album: 'ごうせいあるばむ' } : null,
      purpose: ['metadata_ja', s.sort ? 'sort_tag' : 'no_sort_tag'],
    });
  }

  // 03-yoake: 동기 원문 + 한글 발음 + 한국어 번역
  const base = join(dir, '03-yoake');
  writeText(`${base}.lrc`,
    '[ti:夜明けのうた]\n[ar:テスト楽団]\n' + lrcLines(60, (k) => `夜明けの${k + 1}番目のことば`),
    ['lyrics_synced']);
  writeText(`${base}.ko-pron.lrc`, lrcLines(60, (k) => `요아케노 ${k + 1}반메노 코토바`), ['lyrics_pron']);
  writeText(`${base}.ko.lrc`, lrcLines(60, (k) => `새벽의 ${k + 1}번째 말`), ['lyrics_translation']);
  // 01-hikari: 비동기 가사(.txt)
  writeText(join(dir, '01-hikari.txt'), '光の中へ\n歩いていこう\n\n(동기 정보 없는 가사)\n', ['lyrics_unsynced']);
  // 02-katakana: 깨진 LRC (잘못된 시간, 닫히지 않은 괄호, 역순, 빈 줄, BOM, 잘못된 UTF-8 바이트)
  const broken = Buffer.concat([
    Buffer.from('﻿[ti:깨진 가사]\n[00:05.00]정상 줄\n[00:99.99]범위 밖 초\n[1:2:3]형식 오류\n[00:10.00\n닫히지 않은 괄호 다음 줄\n[00:03.00]역순 시간\n\n\n[00:20.00][00:25.00]한 줄에 시간 두 개\n'),
    Buffer.from([0xff, 0xfe, 0xc0, 0x0a]),
    Buffer.from('[00:30.00]잘못된 바이트 뒤 줄\n'),
  ]);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, '02-katakana.lrc'), broken);
  record(join(dir, '02-katakana.lrc'), { kind: 'sidecar', purpose: ['lyrics_broken'] });

  // 한글·이모지·태그 없음
  const kdir = join(lib, '한글 앨범');
  const kcover = join(OUT, '.covers', 'korean.jpg');
  makeCover(kcover, { color: '0x2fb05a', number: 3 });
  makeAudio({
    file: join(kdir, '01-새벽.mp3'), codec: 'mp3-cbr', duration: 30, cover: kcover,
    tags: { title: '새벽 공기', artist: '합성 악단', album: '한글 앨범', track: '1' },
    sort: { title: 'ㅅㅐㅂㅕㄱ', artist: 'ㅎㅏㅂㅅㅓㅇ', album: 'ㅎㅏㄴㄱㅡㄹ' },
    purpose: ['metadata_ko', 'embedded_cover'],
  });
  makeAudio({
    file: join(kdir, '02-emoji.m4a'), codec: 'm4a-aac', duration: 30, cover: kcover,
    tags: { title: '🎵 별빛 ✨ Starlight', artist: '합성 악단 🎻', album: '한글 앨범', track: '2' },
    purpose: ['metadata_emoji'],
  });
  makeAudio({
    file: join(lib, '태그 없음', 'untagged-track.mp3'), codec: 'mp3-cbr', duration: 30,
    purpose: ['no_tags', 'no_cover'],
  });

  // 아주 큰 표지 (폴더 cover.jpg, 6000×6000)
  const bdir = join(lib, '큰 표지 앨범');
  const big = join(bdir, 'cover.jpg');
  makeCover(big, { color: '0x7a2fb0', number: 4, size: 6000 });
  record(big, { kind: 'folder_cover', purpose: ['huge_cover'] });
  makeAudio({
    file: join(bdir, '01-big-cover.mp3'), codec: 'mp3-cbr', duration: 30,
    tags: { title: '큰 표지', artist: '합성 악단', album: '큰 표지 앨범', track: '1' },
    purpose: ['huge_cover'],
  });
}

function buildBadFiles(lib) {
  const dir = join(lib, '이상 파일');
  mkdirSync(dir, { recursive: true });

  const zero = join(dir, 'zero-bytes.mp3');
  writeFileSync(zero, '');
  record(zero, { kind: 'bad', purpose: ['zero_bytes'], expect: 'scan_error' });

  const full = join(dir, '.tmp-full.flac');
  makeAudio({ file: full, codec: 'flac-16', duration: 30, tags: { title: '잘림 원본' } });
  manifest.files.pop(); // 임시 파일은 manifest에서 뺀다
  const cut = join(dir, 'truncated.flac');
  copyFileSync(full, cut);
  truncateSync(cut, Math.floor(statSync(full).size / 2));
  rmSync(full);
  record(cut, { kind: 'bad', purpose: ['truncated'], expect: 'scan_partial_or_error' });

  makeAudio({
    file: join(dir, 'mp3-named-flac.flac'), codec: 'mp3-cbr', duration: 30,
    tags: { title: '확장자 불일치 (실제 MP3)', artist: '합성 악단' },
    purpose: ['extension_mismatch'],
  });

  // 내용이 같은 중복 파일 (다른 폴더, 다른 이름)
  makeAudio({
    file: join(dir, 'duplicate-a.mp3'), codec: 'mp3-cbr', duration: 30,
    tags: { title: '중복', artist: '합성 악단' }, purpose: ['duplicate_content'],
  });
  const dupB = join(dir, '중복 사본', 'duplicate-b.mp3');
  mkdirSync(dirname(dupB), { recursive: true });
  copyFileSync(join(dir, 'duplicate-a.mp3'), dupB);
  record(dupB, { kind: 'audio', purpose: ['duplicate_content'], duplicate_of: rel(join(dir, 'duplicate-a.mp3')) });
}

function buildPaths(lib) {
  const dir = join(lib, '경로 시험');
  const src = { codec: 'mp3-cbr', duration: 5 };

  makeAudio({
    ...src, file: join(dir, `공백  두칸 & 특수 #1 ; (괄호) [대괄호] {중괄호} 'quote' %20 +plus.mp3`),
    tags: { title: '특수문자 경로', artist: '합성 악단' }, purpose: ['special_chars_path'],
  });

  // 파일 이름 한도에 가깝게: Linux(ext4 등)는 UTF-8 255바이트, Windows(NTFS)는 UTF-16 255자.
  // 한글은 UTF-8로 3바이트이므로 바이트 기준으로 맞춘다 (250바이트).
  const longName = `${'아주긴이름'.repeat(14)}-${'x'.repeat(35)}.mp3`;
  if (Buffer.byteLength(longName) > 255) throw new Error('긴 이름 음원이 파일 이름 한도를 넘는다');
  makeAudio({ ...src, file: join(dir, longName), tags: { title: '긴 파일 이름', artist: '합성 악단' }, purpose: ['long_name'] });

  // 대소문자만 다른 이름: 대소문자를 구분하지 않는 파일시스템(Windows/macOS 기본)에서는 만들 수 없다.
  const probeA = join(dir, '.case-probe');
  const probeB = join(dir, '.CASE-PROBE');
  writeFileSync(probeA, 'a');
  const caseInsensitive = existsSync(probeB);
  rmSync(probeA);
  if (caseInsensitive) {
    skip('대소문자만 다른 이름', '대소문자를 구분하지 않는 파일시스템 (Linux CI에서 생성됨)');
  } else {
    makeAudio({ ...src, file: join(dir, 'Case.mp3'), tags: { title: 'Case 대문자' }, purpose: ['case_only_diff'] });
    makeAudio({ ...src, file: join(dir, 'case.mp3'), tags: { title: 'case 소문자' }, purpose: ['case_only_diff'] });
  }

  // 루트 밖을 가리키는 심볼릭 링크 (SEC-02). 대상은 라이브러리 밖의 outside/ 폴더.
  const outside = join(OUT, 'outside', 'secret.mp3');
  makeAudio({ ...src, file: outside, tags: { title: '루트 밖 파일 (등록되면 안 됨)' }, purpose: ['outside_root_target'] });
  const link = join(dir, 'escape-link.mp3');
  try {
    symlinkSync(outside, link, 'file');
    manifest.files.push({ path: rel(link), kind: 'symlink', target: rel(outside), purpose: ['symlink_escape'], expect: 'excluded_with_warning' });
  } catch (e) {
    skip('루트 밖 심볼릭 링크', `${e.code}: 권한 없음(Windows는 개발자 모드 필요). Linux CI에서 생성됨`);
  }
}

function buildLib2(lib) {
  // 권한 분리 확인용 두 번째 라이브러리
  const dir = join(lib, '두번째 라이브러리 앨범');
  const cover = join(OUT, '.covers', 'lib2.jpg');
  makeCover(cover, { color: '0xb09a2f', number: 5 });
  for (let i = 1; i <= 3; i++) {
    makeAudio({
      file: join(dir, `0${i}-lib2.m4a`), codec: 'm4a-aac', duration: 30, cover,
      tags: { title: `라이브러리2 곡 ${i}`, artist: '두번째 악단', album: '두번째 라이브러리 앨범', track: String(i) },
      purpose: ['library_acl'],
    });
  }
}

// ── 실행 ────────────────────────────────────────────────────────────

function verifyWithProbe() {
  // 생성 결과가 실제로 읽히는지 ffprobe로 확인한다(이상 파일 제외).
  const r = spawnSync(FFPROBE, ['-version'], { encoding: 'utf8' });
  if (r.error || r.status !== 0) { skip('ffprobe 확인', 'ffprobe 없음'); return; }
  let bad = 0;
  for (const f of manifest.files) {
    if (f.kind !== 'audio' || !f.codec) continue;
    const p = spawnSync(FFPROBE, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', join(OUT, f.path)], { encoding: 'utf8' });
    const d = Number.parseFloat(p.stdout);
    if (p.status !== 0 || !Number.isFinite(d) || Math.abs(d * 1000 - f.duration_ms) > 1000) {
      console.error(`  ffprobe 불일치: ${f.path} (${p.stdout.trim() || p.stderr.trim()})`);
      bad++;
    }
  }
  if (bad) throw new Error(`ffprobe 확인 실패 ${bad}건`);
}

function main() {
  manifest.ffmpeg = ffmpegVersion();
  if (opt('--clean')) rmSync(OUT, { recursive: true, force: true });
  if (existsSync(join(OUT, 'manifest.json'))) {
    console.error(`${rel(join(OUT, 'manifest.json'))}이 이미 있다. 다시 만들려면 --clean`);
    process.exit(1);
  }
  mkdirSync(OUT, { recursive: true });
  const lib1 = join(OUT, 'lib1');
  const lib2 = join(OUT, 'lib2');
  const steps = [
    ['형식', () => buildFormats(lib1)],
    ['길이', () => buildLengths(lib1)],
    ['메타데이터·가사·표지', () => buildMetadataAndLyrics(lib1)],
    ['이상 파일', () => buildBadFiles(lib1)],
    ['경로', () => buildPaths(lib1)],
    ['라이브러리 2', () => buildLib2(lib2)],
  ];
  for (const [name, fn] of steps) {
    console.log(`- ${name}`);
    fn();
  }
  verifyWithProbe();
  rmSync(join(OUT, '.covers'), { recursive: true, force: true });
  manifest.files.sort((a, b) => a.path.localeCompare(b.path));
  writeFileSync(join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
  console.log(`완료: 파일 ${manifest.files.length}개, 건너뜀 ${manifest.skipped.length}건 → ${OUT}`);
}

main();
