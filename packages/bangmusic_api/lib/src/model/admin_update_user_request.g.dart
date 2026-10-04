// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_update_user_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUpdateUserRequestCWProxy {
  AdminUpdateUserRequest displayName(String? displayName);

  AdminUpdateUserRequest role(AdminUpdateUserRequestRoleEnum? role);

  AdminUpdateUserRequest status(AdminUpdateUserRequestStatusEnum? status);

  AdminUpdateUserRequest libraryIds(List<String>? libraryIds);

  AdminUpdateUserRequest newPassword(String? newPassword);

  AdminUpdateUserRequest revokeSessions(bool? revokeSessions);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminUpdateUserRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminUpdateUserRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminUpdateUserRequest call({
    String? displayName,
    AdminUpdateUserRequestRoleEnum? role,
    AdminUpdateUserRequestStatusEnum? status,
    List<String>? libraryIds,
    String? newPassword,
    bool? revokeSessions,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminUpdateUserRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminUpdateUserRequest.copyWith.fieldName(...)`
class _$AdminUpdateUserRequestCWProxyImpl
    implements _$AdminUpdateUserRequestCWProxy {
  const _$AdminUpdateUserRequestCWProxyImpl(this._value);

  final AdminUpdateUserRequest _value;

  @override
  AdminUpdateUserRequest displayName(String? displayName) =>
      this(displayName: displayName);

  @override
  AdminUpdateUserRequest role(AdminUpdateUserRequestRoleEnum? role) =>
      this(role: role);

  @override
  AdminUpdateUserRequest status(AdminUpdateUserRequestStatusEnum? status) =>
      this(status: status);

  @override
  AdminUpdateUserRequest libraryIds(List<String>? libraryIds) =>
      this(libraryIds: libraryIds);

  @override
  AdminUpdateUserRequest newPassword(String? newPassword) =>
      this(newPassword: newPassword);

  @override
  AdminUpdateUserRequest revokeSessions(bool? revokeSessions) =>
      this(revokeSessions: revokeSessions);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminUpdateUserRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminUpdateUserRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminUpdateUserRequest call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? libraryIds = const $CopyWithPlaceholder(),
    Object? newPassword = const $CopyWithPlaceholder(),
    Object? revokeSessions = const $CopyWithPlaceholder(),
  }) {
    return AdminUpdateUserRequest(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as AdminUpdateUserRequestRoleEnum?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AdminUpdateUserRequestStatusEnum?,
      libraryIds: libraryIds == const $CopyWithPlaceholder()
          ? _value.libraryIds
          // ignore: cast_nullable_to_non_nullable
          : libraryIds as List<String>?,
      newPassword: newPassword == const $CopyWithPlaceholder()
          ? _value.newPassword
          // ignore: cast_nullable_to_non_nullable
          : newPassword as String?,
      revokeSessions: revokeSessions == const $CopyWithPlaceholder()
          ? _value.revokeSessions
          // ignore: cast_nullable_to_non_nullable
          : revokeSessions as bool?,
    );
  }
}

extension $AdminUpdateUserRequestCopyWith on AdminUpdateUserRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAdminUpdateUserRequest.copyWith(...)` or like so:`instanceOfAdminUpdateUserRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUpdateUserRequestCWProxy get copyWith =>
      _$AdminUpdateUserRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUpdateUserRequest _$AdminUpdateUserRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminUpdateUserRequest',
  json,
  ($checkedConvert) {
    final val = AdminUpdateUserRequest(
      displayName: $checkedConvert('display_name', (v) => v as String?),
      role: $checkedConvert(
        'role',
        (v) => $enumDecodeNullable(
          _$AdminUpdateUserRequestRoleEnumEnumMap,
          v,
          unknownValue: AdminUpdateUserRequestRoleEnum.unknownDefaultOpenApi,
        ),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecodeNullable(
          _$AdminUpdateUserRequestStatusEnumEnumMap,
          v,
          unknownValue: AdminUpdateUserRequestStatusEnum.unknownDefaultOpenApi,
        ),
      ),
      libraryIds: $checkedConvert(
        'library_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      newPassword: $checkedConvert('new_password', (v) => v as String?),
      revokeSessions: $checkedConvert('revoke_sessions', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'libraryIds': 'library_ids',
    'newPassword': 'new_password',
    'revokeSessions': 'revoke_sessions',
  },
);

Map<String, dynamic> _$AdminUpdateUserRequestToJson(
  AdminUpdateUserRequest instance,
) => <String, dynamic>{
  'display_name': ?instance.displayName,
  'role': ?_$AdminUpdateUserRequestRoleEnumEnumMap[instance.role],
  'status': ?_$AdminUpdateUserRequestStatusEnumEnumMap[instance.status],
  'library_ids': ?instance.libraryIds,
  'new_password': ?instance.newPassword,
  'revoke_sessions': ?instance.revokeSessions,
};

const _$AdminUpdateUserRequestRoleEnumEnumMap = {
  AdminUpdateUserRequestRoleEnum.admin: 'admin',
  AdminUpdateUserRequestRoleEnum.member: 'member',
  AdminUpdateUserRequestRoleEnum.unknownDefaultOpenApi:
      'unknown_default_open_api',
};

const _$AdminUpdateUserRequestStatusEnumEnumMap = {
  AdminUpdateUserRequestStatusEnum.active: 'active',
  AdminUpdateUserRequestStatusEnum.disabled: 'disabled',
  AdminUpdateUserRequestStatusEnum.unknownDefaultOpenApi:
      'unknown_default_open_api',
};
