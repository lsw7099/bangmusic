package io.github.lsw7099.bangmusic

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.os.StatFs
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// audio_service가 미디어 세션과 화면을 같은 엔진으로 연결하려면 AudioServiceActivity를 써야 한다
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 다운로드 시작 전 여유 공간 확인 (03장 §5.7). 패키지를 더 들이지 않으려고 StatFs를 직접 부른다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bangmusic/storage").setMethodCallHandler { call, result ->
            when (call.method) {
                "freeBytes" -> {
                    val path = call.argument<String>("path") ?: filesDir.path
                    try {
                        result.success(StatFs(path).availableBytes)
                    } catch (e: IllegalArgumentException) {
                        result.success(null)
                    }
                }
                // 백그라운드 재생 진단 (04장 S10): 배터리 최적화 예외 여부, 앱 배터리 설정 열기
                "batteryOptimizationIgnored" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "openAppSettings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
