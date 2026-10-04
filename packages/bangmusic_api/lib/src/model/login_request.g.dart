// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LoginRequestCWProxy {
  LoginRequest username(String username);

  LoginRequest password(String password);

  LoginRequest device(DeviceInfo device);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginRequest call({String username, String password, DeviceInfo device});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLoginRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLoginRequest.copyWith.fieldName(...)`
class _$LoginRequestCWProxyImpl implements _$LoginRequestCWProxy {
  const _$LoginRequestCWProxyImpl(this._value);

  final LoginRequest _value;

  @override
  LoginRequest username(String username) => this(username: username);

  @override
  LoginRequest password(String password) => this(password: password);

  @override
  LoginRequest device(DeviceInfo device) => this(device: device);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LoginRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LoginRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  LoginRequest call({
    Object? username = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? device = const $CopyWithPlaceholder(),
  }) {
    return LoginRequest(
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
      device: device == const $CopyWithPlaceholder()
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as DeviceInfo,
    );
  }
}

extension $LoginRequestCopyWith on LoginRequest {
  /// Returns a callable class that can be used as follows: `instanceOfLoginRequest.copyWith(...)` or like so:`instanceOfLoginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LoginRequestCWProxy get copyWith => _$LoginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['username', 'password', 'device']);
      final val = LoginRequest(
        username: $checkedConvert('username', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
        device: $checkedConvert(
          'device',
          (v) => DeviceInfo.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'device': instance.device.toJson(),
    };
