// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_token_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RefreshTokenRequestCWProxy {
  RefreshTokenRequest refreshToken(String refreshToken);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RefreshTokenRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RefreshTokenRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RefreshTokenRequest call({String refreshToken});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRefreshTokenRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRefreshTokenRequest.copyWith.fieldName(...)`
class _$RefreshTokenRequestCWProxyImpl implements _$RefreshTokenRequestCWProxy {
  const _$RefreshTokenRequestCWProxyImpl(this._value);

  final RefreshTokenRequest _value;

  @override
  RefreshTokenRequest refreshToken(String refreshToken) =>
      this(refreshToken: refreshToken);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RefreshTokenRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RefreshTokenRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RefreshTokenRequest call({
    Object? refreshToken = const $CopyWithPlaceholder(),
  }) {
    return RefreshTokenRequest(
      refreshToken: refreshToken == const $CopyWithPlaceholder()
          ? _value.refreshToken
          // ignore: cast_nullable_to_non_nullable
          : refreshToken as String,
    );
  }
}

extension $RefreshTokenRequestCopyWith on RefreshTokenRequest {
  /// Returns a callable class that can be used as follows: `instanceOfRefreshTokenRequest.copyWith(...)` or like so:`instanceOfRefreshTokenRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RefreshTokenRequestCWProxy get copyWith =>
      _$RefreshTokenRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RefreshTokenRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['refresh_token']);
      final val = RefreshTokenRequest(
        refreshToken: $checkedConvert('refresh_token', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'refreshToken': 'refresh_token'});

Map<String, dynamic> _$RefreshTokenRequestToJson(
  RefreshTokenRequest instance,
) => <String, dynamic>{'refresh_token': instance.refreshToken};
