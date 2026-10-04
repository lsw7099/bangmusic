// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserSummaryCWProxy {
  UserSummary id(String id);

  UserSummary username(String username);

  UserSummary displayName(String? displayName);

  UserSummary role(UserSummaryRoleEnum role);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  UserSummary call({
    String id,
    String username,
    String? displayName,
    UserSummaryRoleEnum role,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUserSummary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUserSummary.copyWith.fieldName(...)`
class _$UserSummaryCWProxyImpl implements _$UserSummaryCWProxy {
  const _$UserSummaryCWProxyImpl(this._value);

  final UserSummary _value;

  @override
  UserSummary id(String id) => this(id: id);

  @override
  UserSummary username(String username) => this(username: username);

  @override
  UserSummary displayName(String? displayName) =>
      this(displayName: displayName);

  @override
  UserSummary role(UserSummaryRoleEnum role) => this(role: role);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserSummary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserSummary(...).copyWith(id: 12, name: "My name")
  /// ````
  UserSummary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return UserSummary(
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
          : role as UserSummaryRoleEnum,
    );
  }
}

extension $UserSummaryCopyWith on UserSummary {
  /// Returns a callable class that can be used as follows: `instanceOfUserSummary.copyWith(...)` or like so:`instanceOfUserSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserSummaryCWProxy get copyWith => _$UserSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSummary _$UserSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserSummary', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'username', 'role']);
      final val = UserSummary(
        id: $checkedConvert('id', (v) => v as String),
        username: $checkedConvert('username', (v) => v as String),
        displayName: $checkedConvert('display_name', (v) => v as String?),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(
            _$UserSummaryRoleEnumEnumMap,
            v,
            unknownValue: UserSummaryRoleEnum.unknownDefaultOpenApi,
          ),
        ),
      );
      return val;
    }, fieldKeyMap: const {'displayName': 'display_name'});

Map<String, dynamic> _$UserSummaryToJson(UserSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': ?instance.displayName,
      'role': _$UserSummaryRoleEnumEnumMap[instance.role]!,
    };

const _$UserSummaryRoleEnumEnumMap = {
  UserSummaryRoleEnum.admin: 'admin',
  UserSummaryRoleEnum.member: 'member',
  UserSummaryRoleEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
