// 기기 로컬 설정 (04장 S10: 재생·가사·화면). 서버와 무관하며 프로필을 바꿔도 유지된다.
// 다운로드 설정은 DownloadSettings(엔진이 직접 읽는다)에 있다.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  /// 투명도 줄이기 (04장 §3.4): 유리 대신 불투명 면, 흐림 없음
  bool reduceTransparency = false;

  /// 스트리밍 음질: Wi-Fi / 셀룰러 (original, aac_256, aac_128)
  String streamQualityWifi = 'original';
  String streamQualityCellular = 'aac_128';

  /// 셀룰러에서 스트리밍 허용 (끄면 받은 곡만 재생)
  bool allowCellularStreaming = true;

  /// 가사 기본 표시 줄 (원문은 항상) — 몰입 화면 칩의 선택을 기억한다
  bool lyricsPronunciation = true;
  bool lyricsTranslation = true;

  /// 가사 글자 크기 보정 (시스템 글자 크기에 곱한다)
  double lyricsScale = 1.0;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values.asNameMap()[p.getString('ui.theme')] ?? ThemeMode.system;
    reduceTransparency = p.getBool('ui.reduce_transparency') ?? false;
    streamQualityWifi = p.getString('play.quality_wifi') ?? 'original';
    streamQualityCellular = p.getString('play.quality_cellular') ?? 'aac_128';
    allowCellularStreaming = p.getBool('play.allow_cellular') ?? true;
    lyricsPronunciation = p.getBool('lyrics.pron') ?? true;
    lyricsTranslation = p.getBool('lyrics.trans') ?? true;
    lyricsScale = p.getDouble('lyrics.scale') ?? 1.0;
    notifyListeners();
  }

  Future<void> update({
    ThemeMode? themeMode,
    bool? reduceTransparency,
    String? streamQualityWifi,
    String? streamQualityCellular,
    bool? allowCellularStreaming,
    bool? lyricsPronunciation,
    bool? lyricsTranslation,
    double? lyricsScale,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (themeMode != null) await p.setString('ui.theme', (this.themeMode = themeMode).name);
    if (reduceTransparency != null) await p.setBool('ui.reduce_transparency', this.reduceTransparency = reduceTransparency);
    if (streamQualityWifi != null) await p.setString('play.quality_wifi', this.streamQualityWifi = streamQualityWifi);
    if (streamQualityCellular != null) await p.setString('play.quality_cellular', this.streamQualityCellular = streamQualityCellular);
    if (allowCellularStreaming != null) await p.setBool('play.allow_cellular', this.allowCellularStreaming = allowCellularStreaming);
    if (lyricsPronunciation != null) await p.setBool('lyrics.pron', this.lyricsPronunciation = lyricsPronunciation);
    if (lyricsTranslation != null) await p.setBool('lyrics.trans', this.lyricsTranslation = lyricsTranslation);
    if (lyricsScale != null) await p.setDouble('lyrics.scale', this.lyricsScale = lyricsScale);
    notifyListeners();
  }
}

/// 음질 이름 (설정·꼬리표 공용)
String qualityLabel(String q) => switch (q) {
      'original' => '원본 (가능하면 그대로)',
      'aac_256' => 'AAC 256kbps',
      'aac_128' => 'AAC 128kbps (데이터 절약)',
      _ => q,
    };
