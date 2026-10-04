// 앱 상태 전달. 외부 상태 관리 패키지 없이 InheritedNotifier 하나로 충분하다.
import 'package:flutter/widgets.dart';

import 'app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  /// 변경 시 다시 그린다
  AppState watchApp() => AppScope.of(this);

  /// 한 번 읽기 (콜백 안에서)
  AppState readApp() => AppScope.of(this, listen: false);
}
