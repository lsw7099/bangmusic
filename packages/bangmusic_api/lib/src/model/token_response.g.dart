// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TokenResponseCWProxy {
  TokenResponse sessionId(String sessionId);

  TokenResponse accessToken(String accessToken);

  TokenResponse accessExpiresAt(DateTime accessExpiresAt);

  TokenResponse refreshToken(String refreshToken);

  TokenResponse refreshExpiresAt(DateTime refreshExpiresAt);

  TokenResponse user(UserSummary user);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TokenResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TokenResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  TokenResponse call({
    String sessionId,
    String accessToken,
    DateTime accessExpiresAt,
    String refreshToken,
    DateTime refreshExpiresAt,
    UserSummary user,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTokenResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTokenResponse.copyWith.fieldName(...)`
class _$TokenResponseCWProxyImpl implements _$TokenResponseCWProxy {
  const _$TokenResponseCWProxyImpl(this._value);

  final TokenResponse _value;

  @override
  TokenResponse sessionId(String sessionId) => this(sessionId: sessionId);

  @override
  TokenResponse accessToken(String accessToken) =>
      this(accessToken: accessToken);

  @override
  TokenResponse accessExpiresAt(DateTime accessExpiresAt) =>
      this(accessExpiresAt: accessExpiresAt);

  @override
  TokenResponse refreshToken(String refreshToken) =>
      this(refreshToken: refreshToken);

  @override
  TokenResponse refreshExpiresAt(DateTime refreshExpiresAt) =>
      this(refreshExpiresAt: refreshExpiresAt);

  @override
  TokenResponse user(UserSummary user) => this(user: user);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TokenResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TokenResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  TokenResponse call({
    Object? sessionId = const $CopyWithPlaceholder(),
    Object? accessToken = const $CopyWithPlaceholder(),
    Object? accessExpiresAt = const $CopyWithPlaceholder(),
    Object? refreshToken = const $CopyWithPlaceholder(),
    Object? refreshExpiresAt = const $CopyWithPlaceholder(),
    Object? user = const $CopyWithPlaceholder(),
  }) {
    return TokenResponse(
      sessionId: sessionId == const $CopyWithPlaceholder()
          ? _value.sessionId
          // ignore: cast_nullable_to_non_nullable
          : sessionId as String,
      accessToken: accessToken == const $CopyWithPlaceholder()
          ? _value.accessToken
          // ignore: cast_nullable_to_non_nullable
          : accessToken as String,
      accessExpiresAt: accessExpiresAt == const $CopyWithPlaceholder()
          ? _value.accessExpiresAt
          // ignore: cast_nullable_to_non_nullable
          : accessExpiresAt as DateTime,
      refreshToken: refreshToken == const $CopyWithPlaceholder()
          ? _value.refreshToken
          // ignore: cast_nullable_to_non_nullable
          : refreshToken as String,
      refreshExpiresAt: refreshExpiresAt == const $CopyWithPlaceholder()
          ? _value.refreshExpiresAt
          // ignore: cast_nullable_to_non_nullable
          : refreshExpiresAt as DateTime,
      user: user == const $CopyWithPlaceholder()
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as UserSummary,
    );
  }
}

extension $TokenResponseCopyWith on TokenResponse {
  /// Returns a callable class that can be used as follows: `instanceOfTokenResponse.copyWith(...)` or like so:`instanceOfTokenResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TokenResponseCWProxy get copyWith => _$TokenResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TokenResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'session_id',
            'access_token',
            'access_expires_at',
            'refresh_token',
            'refresh_expires_at',
            'user',
          ],
        );
        final val = TokenResponse(
          sessionId: $checkedConvert('session_id', (v) => v as String),
          accessToken: $checkedConvert('access_token', (v) => v as String),
          accessExpiresAt: $checkedConvert(
            'access_expires_at',
            (v) => DateTime.parse(v as String),
          ),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          refreshExpiresAt: $checkedConvert(
            'refresh_expires_at',
            (v) => DateTime.parse(v as String),
          ),
          user: $checkedConvert(
            'user',
            (v) => UserSummary.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'sessionId': 'session_id',
        'accessToken': 'access_token',
        'accessExpiresAt': 'access_expires_at',
        'refreshToken': 'refresh_token',
        'refreshExpiresAt': 'refresh_expires_at',
      },
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'access_token': instance.accessToken,
      'access_expires_at': instance.accessExpiresAt.toIso8601String(),
      'refresh_token': instance.refreshToken,
      'refresh_expires_at': instance.refreshExpiresAt.toIso8601String(),
      'user': instance.user.toJson(),
    };
