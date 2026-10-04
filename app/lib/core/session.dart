// 서버 프로필과 토큰 (01장 §6, 02장 §1). 프로필 키는 서버가 준 server_id.
// 토큰은 보안 저장소에만, 서버 주소·사용자 이름 같은 비밀 아닌 값은 일반 저장소(JSON)에 둔다.
import 'dart:convert';

import '../platform/secure_store.dart';

class ServerProfile {
  const ServerProfile({required this.serverId, required this.baseUrl, required this.serverName, required this.userId, required this.username, this.displayName, required this.installationId});
  final String serverId;
  final String baseUrl;
  final String serverName;
  final String userId;
  final String username;
  final String? displayName;

  /// 앱 설치마다 무작위 (하드웨어 ID를 쓰지 않는다, 02장 §8)
  final String installationId;

  Map<String, Object?> toJson() => {
        'server_id': serverId, 'base_url': baseUrl, 'server_name': serverName, 'user_id': userId,
        'username': username, 'display_name': displayName, 'installation_id': installationId,
      };

  static ServerProfile fromJson(Map<String, Object?> j) => ServerProfile(
        serverId: j['server_id']! as String,
        baseUrl: j['base_url']! as String,
        serverName: j['server_name']! as String,
        userId: j['user_id']! as String,
        username: j['username']! as String,
        displayName: j['display_name'] as String?,
        installationId: j['installation_id']! as String,
      );
}

class Tokens {
  const Tokens(this.access, this.accessExpiresAt, this.refresh);
  final String access;
  final DateTime accessExpiresAt;
  final String refresh;

  String encode() => jsonEncode({'a': access, 'ae': accessExpiresAt.toIso8601String(), 'r': refresh});
  static Tokens? decode(String? s) {
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, Object?>;
      return Tokens(j['a']! as String, DateTime.parse(j['ae']! as String), j['r']! as String);
    } catch (_) {
      return null;
    }
  }
}

/// 세션 상태 (04장 §5 공통 상태). 네트워크 오류는 세션 만료가 아니다(02장 §1.2).
enum SessionStatus { active, expired, revoked, none }

class TokenVault {
  TokenVault(this._store);
  final SecureStore _store;

  String _key(String serverId) => 'tokens.$serverId';
  Future<Tokens?> load(String serverId) async => Tokens.decode(await _store.read(_key(serverId)));
  Future<void> save(String serverId, Tokens t) => _store.write(_key(serverId), t.encode());
  Future<void> clear(String serverId) => _store.delete(_key(serverId));
}
