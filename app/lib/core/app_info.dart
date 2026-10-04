// 제품명·버전 상수는 한 곳에 둔다(05장 §8.7: 이름이 바뀌면 여기만 고친다). 제품명 BangMusic(상표 조사는 하지 않음).
import 'package:flutter/foundation.dart';

class AppInfo {
  static const productName = 'BangMusic';

  /// Play 콘솔의 1회 구매(비소모성) 상품 ID (05장 §8.1). 스토어에 만든 뒤에는 바꿀 수 없다
  static const unlockProductId = 'bangmusic_unlock';
  static const appVersion = '0.1.0';
  static const platform = 'android';

  /// 앱이 아는 최신 API minor / 이보다 낮은 서버와는 동작하지 않는다 (02장 §2.2)
  static const apiMinorBuilt = 0;
  static const apiMinorRequired = 0;

  /// 릴리스 빌드는 HTTPS만 허용한다(05장 §9.3). 디버그 빌드에서만 http:// 시험 서버를 허용.
  static bool get allowCleartext => kDebugMode;

  static String get clientHeader => '$platform/$appVersion api=1.$apiMinorBuilt';
}
