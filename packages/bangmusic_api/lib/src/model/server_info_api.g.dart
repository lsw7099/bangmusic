// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_info_api.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServerInfoApiCWProxy {
  ServerInfoApi major(int major);

  ServerInfoApi minor(int minor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServerInfoApi(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServerInfoApi(...).copyWith(id: 12, name: "My name")
  /// ````
  ServerInfoApi call({int major, int minor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfServerInfoApi.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfServerInfoApi.copyWith.fieldName(...)`
class _$ServerInfoApiCWProxyImpl implements _$ServerInfoApiCWProxy {
  const _$ServerInfoApiCWProxyImpl(this._value);

  final ServerInfoApi _value;

  @override
  ServerInfoApi major(int major) => this(major: major);

  @override
  ServerInfoApi minor(int minor) => this(minor: minor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServerInfoApi(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServerInfoApi(...).copyWith(id: 12, name: "My name")
  /// ````
  ServerInfoApi call({
    Object? major = const $CopyWithPlaceholder(),
    Object? minor = const $CopyWithPlaceholder(),
  }) {
    return ServerInfoApi(
      major: major == const $CopyWithPlaceholder()
          ? _value.major
          // ignore: cast_nullable_to_non_nullable
          : major as int,
      minor: minor == const $CopyWithPlaceholder()
          ? _value.minor
          // ignore: cast_nullable_to_non_nullable
          : minor as int,
    );
  }
}

extension $ServerInfoApiCopyWith on ServerInfoApi {
  /// Returns a callable class that can be used as follows: `instanceOfServerInfoApi.copyWith(...)` or like so:`instanceOfServerInfoApi.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServerInfoApiCWProxy get copyWith => _$ServerInfoApiCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerInfoApi _$ServerInfoApiFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServerInfoApi', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['major', 'minor']);
      final val = ServerInfoApi(
        major: $checkedConvert('major', (v) => (v as num).toInt()),
        minor: $checkedConvert('minor', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ServerInfoApiToJson(ServerInfoApi instance) =>
    <String, dynamic>{'major': instance.major, 'minor': instance.minor};
