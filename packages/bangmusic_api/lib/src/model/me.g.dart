// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeCWProxy {
  Me id(String id);

  Me username(String username);

  Me displayName(String? displayName);

  Me role(MeRoleEnum role);

  Me libraries(List<MeAllOfLibraries> libraries);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Me(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Me(...).copyWith(id: 12, name: "My name")
  /// ````
  Me call({
    String id,
    String username,
    String? displayName,
    MeRoleEnum role,
    List<MeAllOfLibraries> libraries,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMe.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMe.copyWith.fieldName(...)`
class _$MeCWProxyImpl implements _$MeCWProxy {
  const _$MeCWProxyImpl(this._value);

  final Me _value;

  @override
  Me id(String id) => this(id: id);

  @override
  Me username(String username) => this(username: username);

  @override
  Me displayName(String? displayName) => this(displayName: displayName);

  @override
  Me role(MeRoleEnum role) => this(role: role);

  @override
  Me libraries(List<MeAllOfLibraries> libraries) => this(libraries: libraries);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Me(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Me(...).copyWith(id: 12, name: "My name")
  /// ````
  Me call({
    Object? id = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? libraries = const $CopyWithPlaceholder(),
  }) {
    return Me(
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
          : role as MeRoleEnum,
      libraries: libraries == const $CopyWithPlaceholder()
          ? _value.libraries
          // ignore: cast_nullable_to_non_nullable
          : libraries as List<MeAllOfLibraries>,
    );
  }
}

extension $MeCopyWith on Me {
  /// Returns a callable class that can be used as follows: `instanceOfMe.copyWith(...)` or like so:`instanceOfMe.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeCWProxy get copyWith => _$MeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Me _$MeFromJson(Map<String, dynamic> json) => $checkedCreate('Me', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['id', 'username', 'role', 'libraries']);
  final val = Me(
    id: $checkedConvert('id', (v) => v as String),
    username: $checkedConvert('username', (v) => v as String),
    displayName: $checkedConvert('display_name', (v) => v as String?),
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(
        _$MeRoleEnumEnumMap,
        v,
        unknownValue: MeRoleEnum.unknownDefaultOpenApi,
      ),
    ),
    libraries: $checkedConvert(
      'libraries',
      (v) => (v as List<dynamic>)
          .map((e) => MeAllOfLibraries.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'displayName': 'display_name'});

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'display_name': ?instance.displayName,
  'role': _$MeRoleEnumEnumMap[instance.role]!,
  'libraries': instance.libraries.map((e) => e.toJson()).toList(),
};

const _$MeRoleEnumEnumMap = {
  MeRoleEnum.admin: 'admin',
  MeRoleEnum.member: 'member',
  MeRoleEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
