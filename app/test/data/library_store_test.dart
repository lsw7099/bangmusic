// 로컬 라이브러리 저장소 (03장 §5.2, §5.4 중복 방지, §5.6 오프라인 탐색, FN-22 대기 변경) — 호스트의 SQLite로 실행 (L0)
import 'dart:io';

import 'package:bangmusic/data/library_store.dart';
import 'package:bangmusic/domain/download_state.dart';
import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui/fakes.dart' as f;

Track t(String id, String title, {String? albumId, int no = 1}) => Track.fromJson(f.track(id, title, albumId: albumId, album: 'ガラスの夜', no: no));

void main() {
  late Directory dir;
  late LibraryStore s;
  var n = 0;
  String newId() => 'dl_${++n}';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bm_store');
    s = await LibraryStore.openForTest(dir);
  });
  tearDown(() async {
    await s.close();
    await dir.delete(recursive: true);
  });

  Future<Download> complete(Download d, {String mv = 'v1'}) async {
    final done = d.copyWith(state: DlState.completed, renditionId: 'ren_${d.trackId}', mediaVersion: mv, ext: 'flac', bytesTotal: 100, fileName: 'x/${d.id}.flac');
    await s.saveDownload(done);
    return done;
  }

  test('같은 곡·음질은 다운로드 하나를 공유하고 마지막 요청자가 떠날 때만 풀린다 (§5.4)', () async {
    final a = await s.request('trk_1', 'original', RequestKind.album, 'alb_1', newId: newId);
    final b = await s.request('trk_1', 'original', RequestKind.playlist, 'pl_1', newId: newId);
    expect(a.created, isTrue);
    expect(b.created, isFalse);
    expect(b.download.id, a.download.id);
    expect((await s.downloads()).length, 1);
    expect(await s.release(RequestKind.album, 'alb_1'), isEmpty, reason: '플레이리스트가 아직 요구한다');
    final orphaned = await s.release(RequestKind.playlist, 'pl_1');
    expect(orphaned.single.id, a.download.id);
    final other = await s.request('trk_1', 'aac_128', RequestKind.track, 'trk_1', newId: newId);
    expect(other.created, isTrue, reason: '음질이 다르면 다른 파일');
  });

  test('행 저장·복원이 상태 기계의 모든 필드를 보존', () async {
    final r = await s.request('trk_1', 'original', RequestKind.track, 'trk_1', newId: newId);
    final d = r.download.copyWith(
      state: DlState.waitingSpace, renditionId: 'ren_1', mediaVersion: 'mv', bytesTotal: 10, bytesDone: 4, sha256: 'ab', etag: '"e"',
      ext: 'flac', errorCode: 'network', attempts: 2, integrityRetried: true, notBefore: DateTime.utc(2026, 10, 3, 1), stale: true,
      locked: true, verified: Verified.sizeOnly, fileName: 'a/b.flac',
    );
    await s.saveDownload(d);
    expect((await s.download(d.id)).toString(), d.toString());
    final back = (await s.download(d.id))!;
    expect([back.state, back.renditionId, back.mediaVersion, back.bytesTotal, back.bytesDone, back.sha256, back.etag, back.ext, back.errorCode, back.attempts,
      back.integrityRetried, back.notBefore, back.stale, back.locked, back.verified, back.fileName],
        [d.state, d.renditionId, d.mediaVersion, d.bytesTotal, d.bytesDone, d.sha256, d.etag, d.ext, d.errorCode, d.attempts,
      d.integrityRetried, d.notBefore, d.stale, d.locked, d.verified, d.fileName]);
  });

  test('재생 대상은 completed·잠기지 않은 행만, 새 버전 완료본을 우선 (§5.1, §5.4)', () async {
    final r = await s.request('trk_1', 'original', RequestKind.track, 'trk_1', newId: newId);
    expect(await s.playableFor('trk_1'), isNull, reason: 'queued');
    await s.saveDownload(r.download.copyWith(state: DlState.verifying, fileName: 'x'));
    expect(await s.playableFor('trk_1'), isNull, reason: '검증 중');
    final old = await complete(r.download);
    await s.saveDownload(old.copyWith(stale: true));
    final fresh = await s.requestNewVersion(old, newId: newId);
    expect(await s.requestersOf(fresh.id), [(kind: 'track', refId: 'trk_1')], reason: '요청자 승계');
    expect((await s.playableFor('trk_1'))!.id, old.id, reason: '새 버전이 끝나기 전에는 옛 파일');
    await complete(fresh, mv: 'v2');
    expect((await s.playableFor('trk_1'))!.id, fresh.id);
    await s.saveDownload(fresh.copyWith(state: DlState.completed, locked: true, fileName: 'x'));
    await s.saveDownload(old.copyWith(locked: true));
    expect(await s.playableFor('trk_1'), isNull, reason: '잠김');
  });

  test('오프라인 탐색: 받은 곡이 있는 앨범만, 곡 순서, 정규화 검색 (§5.6)', () async {
    await s.putAlbum(AlbumDetail.fromJson({...f.album('alb_1', 'ガラスの夜'), 'tracks': [f.track('trk_2', 'ﾖﾙｼｶ', albumId: 'alb_1', album: 'ガラスの夜', no: 2), f.track('trk_1', '光', albumId: 'alb_1', album: 'ガラスの夜', no: 1)]}));
    await s.putAlbum(AlbumDetail.fromJson({...f.album('alb_2', '안 받은 앨범'), 'tracks': [f.track('trk_9', '다른 곡', albumId: 'alb_2')]}));
    expect(await s.downloadedAlbums(), isEmpty);
    await complete((await s.request('trk_2', 'original', RequestKind.track, 'trk_2', newId: newId)).download);
    expect((await s.downloadedAlbums()).map((a) => a.id), ['alb_1']);
    expect((await s.albumTracks('alb_1')).map((t) => t.id), ['trk_1', 'trk_2'], reason: '디스크·트랙 번호 순');
    expect((await s.searchTracks('よるしか')).map((t) => t.id), ['trk_2'], reason: '반각 가타카나 ↔ 히라가나');
    expect((await s.searchTracks('がらす')).map((t) => t.id), ['trk_2'], reason: '앨범 이름으로도, 받은 곡만');
    expect((await s.searchTracks('がらす', onlyPlayable: false)).length, 2);
    expect((await s.searchAlbums('ガラス')).map((a) => a.id), ['alb_1']);
    expect(await s.searchTracks('   '), isEmpty);
  });

  test('플레이리스트 순서 보존, 같은 곡 두 번', () async {
    final p = Playlist.fromJson(f.playlist('pl_1', '드라이브', count: 3, version: 4));
    PlaylistItem item(String id, String trk) => PlaylistItem.fromJson({'item_id': id, 'available': true, 'track': f.track(trk, trk), 'added_at': null});
    await s.putPlaylist(p, [item('i3', 'trk_b'), item('i1', 'trk_a'), item('i2', 'trk_b')]);
    expect((await s.playlistTracks('pl_1')).map((e) => '${e.itemId}:${e.track.id}'), ['i3:trk_b', 'i1:trk_a', 'i2:trk_b']);
    await s.putPlaylist(p, [item('i1', 'trk_a')]);
    expect((await s.playlistTracks('pl_1')).length, 1, reason: '다시 받으면 교체');
    expect((await s.playlist('pl_1'))!.version, 4);
  });

  test('대기 중인 재생 기록: 같은 event_id는 한 번만, 보낸 것만 지운다 (FN-22)', () async {
    PlayEvent ev(String id) => PlayEvent.fromJson({'event_id': id, 'track_id': 'trk_1', 'started_at': '2026-10-03T00:00:00Z', 'played_ms': 1, 'completed': false, 'source': 'offline'});
    await s.addPlayEvent(ev('e1'));
    await s.addPlayEvent(ev('e1'));
    await s.addPlayEvent(ev('e2'));
    expect((await s.pendingPlayEvents()).map((e) => e.eventId), ['e1', 'e2']);
    await s.removePlayEvents(['e1']);
    expect((await s.pendingPlayEvents()).map((e) => e.eventId), ['e2']);
  });

  test('대기 중인 플레이리스트 편집은 순서대로, 키 보존', () async {
    await s.addPendingOp('pl_1', [{'op': 'add', 'track_ids': ['trk_1']}], 'k1');
    await s.addPendingOp('pl_1', [{'op': 'remove', 'item_ids': ['i1']}], 'k2');
    final ops = await s.pendingOps();
    expect(ops.map((o) => o.key), ['k1', 'k2']);
    expect(ops.first.ops.single['op'], 'add');
    await s.removeOp(ops.first.seq);
    expect((await s.pendingOps()).single.key, 'k2');
  });

  test('저장 한도 계산은 완료본만', () async {
    await complete((await s.request('trk_1', 'original', RequestKind.track, 'trk_1', newId: newId)).download);
    final r = await s.request('trk_2', 'original', RequestKind.track, 'trk_2', newId: newId);
    await s.saveDownload(r.download.copyWith(state: DlState.downloading, bytesTotal: 999));
    expect(await s.usedBytes(), 100);
  });

  test('고정 묶음(앨범 전체 다운로드)', () async {
    await s.pinGroup(RequestKind.album, 'alb_1', 'original');
    expect(await s.isPinned(RequestKind.album, 'alb_1'), isTrue);
    expect((await s.groups()).single.refId, 'alb_1');
    await s.unpinGroup(RequestKind.album, 'alb_1');
    expect(await s.groups(), isEmpty);
  });
}
