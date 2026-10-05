// 공통 컴포넌트 (04장 §4): 표지, TrackRow, EmptyState, ErrorState, SkeletonList, StatusBanner.
import 'dart:async';
import 'dart:io';

import 'package:bangmusic_api/bangmusic_api.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../app_state.dart';
import '../glass.dart';
import '../screens/connect_screen.dart';
import 'relogin_sheet.dart';
import '../scope.dart';
import '../tokens.dart';

/// 표지. 파일 캐시를 거쳐 그린다(Authorization 헤더로 받음). 없으면 자리표시자.
class Artwork extends StatefulWidget {
  const Artwork(this.artworkId, {super.key, this.size = 48, this.radius = Radii.sm, this.label});
  final String? artworkId;
  final double size;
  final double radius;
  final String? label; // 자리표시자 이니셜용

  @override
  State<Artwork> createState() => _ArtworkState();
}

class _ArtworkState extends State<Artwork> {
  Future<File?>? _file;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(Artwork old) {
    super.didUpdateWidget(old);
    if (old.artworkId != widget.artworkId) _load();
  }

  void _load() {
    final px = widget.size * MediaQuery.devicePixelRatioOf(context);
    final size = px <= 96 ? 96 : px <= 256 ? 256 : px <= 512 ? 512 : 1024;
    _file = context.readApp().player.cachedArtwork(widget.artworkId, size);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final placeholder = Container(
      width: widget.size, height: widget.size, color: c.surfaceAlt, alignment: Alignment.center,
      child: widget.label != null && widget.label!.isNotEmpty
          ? Text(widget.label!.characters.first, style: TextStyle(fontSize: widget.size / 3, color: c.textMuted, fontWeight: FontWeight.w700))
          : Icon(Icons.album, color: c.textMuted, size: widget.size / 2.2),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.size, height: widget.size,
        child: FutureBuilder<File?>(
          future: _file,
          builder: (_, s) => s.data == null ? placeholder : Image.file(s.data!, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => placeholder),
        ),
      ),
    );
  }
}

String formatMs(int ms) {
  final s = ms ~/ 1000;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final ss = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

String spokenDuration(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 60}분 ${s % 60}초';
}

String artistNames(Track t) => t.artists.map((a) => a.name).join(', ');

/// 곡 한 줄 (04장 §4 TrackRow). 스크린리더에서 한 항목으로 읽힌다.
class TrackRow extends StatelessWidget {
  const TrackRow({super.key, required this.track, required this.onTap, this.leadingNumber, this.playing = false, this.available = true, this.onMore, this.badge, this.statusLabel});
  final Track track;
  final VoidCallback onTap;
  final int? leadingNumber;
  final bool playing;
  final bool available;
  final VoidCallback? onMore;

  /// 제목 줄 끝의 작은 표시 (다운로드 상태 등)
  final Widget? badge;

  /// 스크린리더용 상태 (예: "다운로드됨"). 행 전체를 한 문장으로 읽으므로 표시 위젯 대신 여기에 넣는다
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = !available || track.state == TrackStateEnum.missing;
    final titleStyle = (playing ? context.text.titleMedium : context.text.bodyLarge)?.copyWith(color: disabled ? c.textDisabled : playing ? c.accent : c.text);
    final big = context.textScale >= 1.3;
    return Semantics(
      button: true,
      label: '${track.title}, ${artistNames(track)}, ${spokenDuration(track.durationMs)}${disabled ? ', 재생할 수 없음' : ''}${playing ? ', 재생 중' : ''}${statusLabel == null ? '' : ', $statusLabel'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
          child: Row(children: [
            if (leadingNumber != null)
              SizedBox(width: 32, child: Text('$leadingNumber', style: context.text.bodySmall?.copyWith(color: c.textMuted))),
            if (leadingNumber == null) Artwork(track.artworkId, size: 48, label: track.title),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(track.title, maxLines: big ? 2 : 1, overflow: TextOverflow.ellipsis, style: titleStyle),
                Text(artistNames(track), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall?.copyWith(color: disabled ? c.textDisabled : c.textMuted)),
              ]),
            ),
            ?badge,
            if (playing) Padding(padding: const EdgeInsets.only(left: Space.sm), child: Icon(Icons.graphic_eq, color: c.accent, size: 20)),
            if (disabled) Padding(padding: const EdgeInsets.only(left: Space.sm), child: Icon(Icons.block, color: c.textDisabled, size: 20)),
            if (onMore != null) IconButton(onPressed: onMore, icon: const Icon(Icons.more_vert), tooltip: '더 보기'),
          ]),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.message, this.icon = Icons.library_music_outlined, this.action, this.actionLabel});
  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: context.colors.textMuted),
            const SizedBox(height: Space.lg),
            Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[const SizedBox(height: Space.sm), Text(message!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.textMuted))],
            if (action != null) ...[const SizedBox(height: Space.lg), FilledButton(onPressed: action, child: Text(actionLabel ?? '다시 시도'))],
          ]),
        ),
      );
}

/// 오류 표시: 제목·설명·다시 시도·"자세히"(오류 코드와 request_id) (04장 §4 ErrorState)
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    final (title, msg) = describeError(e);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: context.colors.danger),
          const SizedBox(height: Space.md),
          Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: Space.sm),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: context.colors.textMuted)),
          const SizedBox(height: Space.lg),
          Wrap(spacing: Space.sm, children: [
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            if (e.code != null || e.requestId != null)
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(title: const Text('자세히'), content: SelectableText('코드: ${e.code ?? '-'}\n상태: ${e.status ?? '-'}\n요청 ID: ${e.requestId ?? '-'}')),
                ),
                child: const Text('자세히'),
              ),
          ]),
        ]),
      ),
    );
  }
}

(String, String) describeError(ApiException e) => switch (e.kind) {
      ApiErrorKind.unreachable || ApiErrorKind.timeout => ('서버에 연결할 수 없습니다', '네트워크와 서버 주소, VPN 연결을 확인하세요.'),
      ApiErrorKind.certificate => ('보안 인증서를 확인할 수 없습니다', '서버의 HTTPS 인증서를 확인하세요.'),
      ApiErrorKind.notBangmusic => ('BangMusic 서버가 아닙니다', '주소를 다시 확인하세요.'),
      ApiErrorKind.localNetworkDenied => ('집 안 네트워크의 서버에 연결하려면 권한이 필요합니다', '앱 설정 → 권한에서 "주변 기기"(로컬 네트워크)를 허용하세요.'),
      ApiErrorKind.serverMismatch => ('이 주소의 서버가 이전과 다릅니다', '로그인 정보를 보내지 않았습니다. 받아 둔 음악은 계속 들을 수 있습니다.'),
      _ => switch (e.code) {
          'not_found' => ('찾을 수 없습니다', '삭제되었거나 접근할 수 없습니다.'),
          'maintenance' => ('서버 점검 중입니다', '잠시 후 자동으로 다시 시도합니다.'),
          'setup_required' => ('서버 설정이 끝나지 않았습니다', '서버에서 관리자 계정을 먼저 만드세요.'),
          'client_too_old' => ('앱 업데이트가 필요합니다', '이 서버에 연결하려면 앱을 업데이트하세요.'),
          'rate_limited' => ('요청이 너무 많습니다', '${e.retryAfter ?? 60}초 뒤에 다시 시도하세요.'),
          'refresh_expired' || 'access_expired' => ('다시 로그인이 필요합니다', '받아 둔 음악은 다운로드 탭에서 계속 들을 수 있습니다.'),
          'session_revoked' || 'account_disabled' => ('접근이 취소되었습니다', '서버 관리자에게 문의하세요.'),
          _ => ('불러오지 못했습니다', '잠시 후 다시 시도하세요.'),
        },
    };

/// 300ms 넘게 걸릴 때만 보이는 자리표시자 (깜빡임 방지, 04장 §4 SkeletonList)
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key});
  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> {
  bool _show = false;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 300), () => mounted ? setState(() => _show = true) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final c = context.colors.surfaceAlt;
    return Semantics(
      label: '불러오는 중',
      child: Column(children: [
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(Radii.sm))),
              const SizedBox(width: Space.md),
              Expanded(child: Container(height: 14, color: c)),
            ]),
          ),
      ]),
    );
  }
}

/// 상태 배너 (04장 §4 StatusBanner, §5). 아이콘 + 문구를 함께 쓴다(색만으로 전달하지 않음).
/// 화면 위쪽에 뜬 유리 알약(§3.4). 글자는 유리 위 본문색 — 뒤에 무엇이 비쳐도 대비 유지.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key});

  /// 지금 배너가 보이는지 (셸이 아래 화면의 위 여백을 정할 때)
  static bool visible(BuildContext context) => _info(context) != null;

  static (IconData, String, String?, VoidCallback?)? _info(BuildContext context) {
    final app = context.watchApp();
    // 세션 만료가 우선, 그다음 오프라인 (03장 §6.8: 기기 오프라인과 서버 무응답을 다른 문구로)
    return switch ((app.session, app.connection)) {
      // 서버가 바뀌었으면 가장 먼저 — 다시 로그인을 권하면 다른 서버에 비밀번호를 넣게 된다
      _ when app.serverChanged => (Icons.gpp_maybe, '이 주소의 서버가 이전과 다릅니다. 로그인 정보를 보내지 않았습니다 · 받은 음악만 재생', '새 서버로 등록',
          () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ConnectScreen(initialAddress: app.profile?.baseUrl, asRoute: true)))),
      // 로그인은 시트로 띄워 현재 화면을 잃지 않는다 (04장 §5)
      (SessionStatus.expired, _) => (Icons.lock_clock, '다시 로그인이 필요합니다. 받은 음악은 계속 들을 수 있습니다', '로그인', () => showReloginSheet(context)),
      _ when app.serverNotice == 'client_too_old' => (Icons.system_update, '이 서버에 연결하려면 앱을 업데이트해야 합니다', null, null),
      _ when app.serverNotice == 'maintenance' => (Icons.construction, '서버 점검 중입니다 · 끝나면 자동으로 다시 연결합니다', null, null),
      (_, Connection.deviceOffline) => (Icons.cloud_off, '오프라인 · 받은 음악만 재생할 수 있습니다', null, null),
      (_, Connection.serverUnreachable) => (Icons.dns_outlined, '서버에 연결할 수 없습니다 · 받은 음악만 재생할 수 있습니다', '다시 시도', () => app.syncNow()),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final b = _info(context);
    if (b == null) return const SizedBox.shrink();
    final g = context.glass;
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(GlassTokens.float, top + Space.sm, GlassTokens.float, Space.xs),
      child: Glass(
        radius: Radii.lg,
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.sm, Space.sm),
        child: Row(children: [
          Icon(b.$1, color: g.onGlass),
          const SizedBox(width: Space.md),
          Expanded(child: Text(b.$2, style: TextStyle(color: g.onGlass))),
          // 동작 버튼: 본문색 + 굵게 + 밑줄 (강조색 글자는 배경에 따라 대비 미달 — 04장 §3.1)
          if (b.$3 != null)
            TextButton(
              onPressed: b.$4,
              style: TextButton.styleFrom(foregroundColor: g.onGlass, textStyle: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
              child: Text(b.$3!),
            ),
        ]),
      ),
    );
  }
}
