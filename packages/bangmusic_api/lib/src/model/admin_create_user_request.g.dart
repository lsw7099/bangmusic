// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_create_user_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCreateUserRequestCWProxy {
  AdminCreateUserRequest username(String username);

  AdminCreateUserRequest displayName(String? displayName);

  AdminCreateUserRequest password(String password);

  AdminCreateUserRequest role(AdminCreateUserRequestRoleEnum role);

  AdminCreateUserRequest libraryIds(List<String>? libraryIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCreateUserRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCreateUserRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCreateUserRequest call({
    String username,
    String? displayName,
    String password,
    AdminCreateUserRequestRoleEnum role,
    List<String>? libraryIds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminCreateUserRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminCreateUserRequest.copyWith.fieldName(...)`
class _$AdminCreateUserRequestCWProxyImpl
    implements _$AdminCreateUserRequestCWProxy {
  const _$AdminCreateUserRequestCWProxyImpl(this._value);

  final AdminCreateUserRequest _value;

  @override
  AdminCreateUserRequest username(String username) => this(username: username);

  @override
  AdminCreateUserRequest displayName(String? displayName) =>
      this(displayName: displayName);

  @override
  AdminCreateUserRequest password(String password) => this(password: password);

  @override
  AdminCreateUserRequest role(AdminCreateUserRequestRoleEnum role) =>
      this(role: role);

  @override
  AdminCreateUserRequest libraryIds(List<String>? libraryIds) =>
      this(libraryIds: libraryIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminCreateUserRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminCreateUserRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminCreateUserRequest call({
    Object? username = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? password = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? libraryIds = const $CopyWithPlaceholder(),
  }) {
    return AdminCreateUserRequest(
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as AdminCreateUserRequestRoleEnum,
      libraryIds: libraryIds == const $CopyWithPlaceholder()
          ? _value.libraryIds
          // ignore: cast_nullable_to_non_nullable
          : libraryIds as List<String>?,
    );
  }
}

extension $AdminCreateUserRequestCopyWith on AdminCreateUserRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAdminCreateUserRequest.copyWith(...)` or like so:`instanceOfAdminCreateUserRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCreateUserRequestCWProxy get copyWith =>
      _$AdminCreateUserRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCreateUserRequest _$AdminCreateUserRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminCreateUserRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['username', 'password', 'role']);
    final val = AdminCreateUserRequest(
      username: $checkedConvert('username', (v) => v as String),
      displayName: $checkedConvert('display_name', (v) => v as String?),
      password: $checkedConvert('password', (v) => v as String),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(
          _$AdminCreateUserRequestRoleEnumEnumMap,
          v,
          unknownValue: AdminCreateUserRequestRoleEnum.unknownDefaultOpenApi,
        ),
      ),
      libraryIds: $checkedConvert(
        'library_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'libraryIds': 'library_ids',
  },
);

Map<String, dynamic> _$AdminCreateUserRequestToJson(
  AdminCreateUserRequest instance,
) => <String, dynamic>{
  'username': instance.username,
  'display_name': ?instance.displayName,
  'password': instance.password,
  'role': _$AdminCreateUserRequestRoleEnumEnumMap[instance.role]!,
  'library_ids': ?instance.libraryIds,
};

const _$AdminCreateUserRequestRoleEnumEnumMap = {
  AdminCreateUserRequestRoleEnum.admin: 'admin',
  AdminCreateUserRequestRoleEnum.member: 'member',
  AdminCreateUserRequestRoleEnum.unknownDefaultOpenApi:
      'unknown_default_open_api',
};
