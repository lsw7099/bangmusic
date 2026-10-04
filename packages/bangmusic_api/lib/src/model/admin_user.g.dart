// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminUserCWProxy {
  AdminUser id(String id);

  AdminUser username(String username);

  AdminUser displayName(String? displayName);

  AdminUser role(AdminUserRoleEnum role);

  AdminUser status(AdminUserStatusEnum status);

  AdminUser libraryIds(List<String> libraryIds);

  AdminUser createdAt(DateTime createdAt);

  AdminUser sessionCount(int? sessionCount);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminUser(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminUser(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminUser call({
    String id,
    String username,
    String? displayName,
    AdminUserRoleEnum role,
    AdminUserStatusEnum status,
    List<String> libraryIds,
    DateTime createdAt,
    int? sessionCount,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminUser.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminUser.copyWith.fieldName(...)`
class _$AdminUserCWProxyImpl implements _$AdminUserCWProxy {
  const _$AdminUserCWProxyImpl(this._value);

  final AdminUser _value;

  @override
  AdminUser id(String id) => this(id: id);

  @override
  AdminUser username(String username) => this(username: username);

  @override
  AdminUser displayName(String? displayName) => this(displayName: displayName);

  @override
  AdminUser role(AdminUserRoleEnum role) => this(role: role);

  @override
  AdminUser status(AdminUserStatusEnum status) => this(status: status);

  @override
  AdminUser libraryIds(List<String> libraryIds) => this(libraryIds: libraryIds);

  @override
  AdminUser createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  AdminUser sessionCount(int? sessionCount) => this(sessionCount: sessionCount);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminUser(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminUser(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminUser call({
    Object? id = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? libraryIds = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? sessionCount = const $CopyWithPlaceholder(),
  }) {
    return AdminUser(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as AdminUserRoleEnum,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AdminUserStatusEnum,
      libraryIds: libraryIds == const $CopyWithPlaceholder()
          ? _value.libraryIds
          // ignore: cast_nullable_to_non_nullable
          : libraryIds as List<String>,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      sessionCount: sessionCount == const $CopyWithPlaceholder()
          ? _value.sessionCount
          // ignore: cast_nullable_to_non_nullable
          : sessionCount as int?,
    );
  }
}

extension $AdminUserCopyWith on AdminUser {
  /// Returns a callable class that can be used as follows: `instanceOfAdminUser.copyWith(...)` or like so:`instanceOfAdminUser.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminUserCWProxy get copyWith => _$AdminUserCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminUser',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'username',
        'role',
        'status',
        'library_ids',
        'created_at',
      ],
    );
    final val = AdminUser(
      id: $checkedConvert('id', (v) => v as String),
      username: $checkedConvert('username', (v) => v as String),
      displayName: $checkedConvert('display_name', (v) => v as String?),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(
          _$AdminUserRoleEnumEnumMap,
          v,
          unknownValue: AdminUserRoleEnum.unknownDefaultOpenApi,
        ),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(
          _$AdminUserStatusEnumEnumMap,
          v,
          unknownValue: AdminUserStatusEnum.unknownDefaultOpenApi,
        ),
      ),
      libraryIds: $checkedConvert(
        'library_ids',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      sessionCount: $checkedConvert(
        'session_count',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'displayName': 'display_name',
    'libraryIds': 'library_ids',
    'createdAt': 'created_at',
    'sessionCount': 'session_count',
  },
);

Map<String, dynamic> _$AdminUserToJson(AdminUser instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'display_name': ?instance.displayName,
  'role': _$AdminUserRoleEnumEnumMap[instance.role]!,
  'status': _$AdminUserStatusEnumEnumMap[instance.status]!,
  'library_ids': instance.libraryIds,
  'created_at': instance.createdAt.toIso8601String(),
  'session_count': ?instance.sessionCount,
};

const _$AdminUserRoleEnumEnumMap = {
  AdminUserRoleEnum.admin: 'admin',
  AdminUserRoleEnum.member: 'member',
  AdminUserRoleEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$AdminUserStatusEnumEnumMap = {
  AdminUserStatusEnum.active: 'active',
  AdminUserStatusEnum.disabled: 'disabled',
  AdminUserStatusEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
