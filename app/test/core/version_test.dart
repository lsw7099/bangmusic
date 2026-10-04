// 릴리스 규칙(docs/release.md): 앱 버전은 pubspec.yaml과 AppInfo가 같아야 한다 (서버에 보내는 BangMusic-Client 헤더·화면 표시)
import 'dart:io';

import 'package:bangmusic/core/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec.yaml 버전 = AppInfo.appVersion', () {
    final m = RegExp(r'^version:\s*([0-9.]+)\+(\d+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(m, isNotNull);
    expect(m!.group(1), AppInfo.appVersion);
  });
}
