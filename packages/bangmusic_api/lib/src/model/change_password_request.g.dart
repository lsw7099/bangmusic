// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_password_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChangePasswordRequestCWProxy {
  ChangePasswordRequest currentPassword(String currentPassword);

  ChangePasswordRequest newPassword(String newPassword);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangePasswordRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangePasswordRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangePasswordRequest call({String currentPassword, String newPassword});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChangePasswordRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChangePasswordRequest.copyWith.fieldName(...)`
class _$ChangePasswordRequestCWProxyImpl
    implements _$ChangePasswordRequestCWProxy {
  const _$ChangePasswordRequestCWProxyImpl(this._value);

  final ChangePasswordRequest _value;

  @override
  ChangePasswordRequest currentPassword(String currentPassword) =>
      this(currentPassword: currentPassword);

  @override
  ChangePasswordRequest newPassword(String newPassword) =>
      this(newPassword: newPassword);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangePasswordRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangePasswordRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangePasswordRequest call({
    Object? currentPassword = const $CopyWithPlaceholder(),
    Object? newPassword = const $CopyWithPlaceholder(),
  }) {
    return ChangePasswordRequest(
      currentPassword: currentPassword == const $CopyWithPlaceholder()
          ? _value.currentPassword
          // ignore: cast_nullable_to_non_nullable
          : currentPassword as String,
      newPassword: newPassword == const $CopyWithPlaceholder()
          ? _value.newPassword
          // ignore: cast_nullable_to_non_nullable
          : newPassword as String,
    );
  }
}

extension $ChangePasswordRequestCopyWith on ChangePasswordRequest {
  /// Returns a callable class that can be used as follows: `instanceOfChangePasswordRequest.copyWith(...)` or like so:`instanceOfChangePasswordRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChangePasswordRequestCWProxy get copyWith =>
      _$ChangePasswordRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangePasswordRequest _$ChangePasswordRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ChangePasswordRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['current_password', 'new_password']);
    final val = ChangePasswordRequest(
      currentPassword: $checkedConvert('current_password', (v) => v as String),
      newPassword: $checkedConvert('new_password', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'currentPassword': 'current_password',
    'newPassword': 'new_password',
  },
);

Map<String, dynamic> _$ChangePasswordRequestToJson(
  ChangePasswordRequest instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'new_password': instance.newPassword,
};
