// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SessionCWProxy {
  Session id(String id);

  Session deviceName(String deviceName);

  Session platform(String platform);

  Session appVersion(String? appVersion);

  Session createdAt(DateTime createdAt);

  Session lastSeenAt(DateTime lastSeenAt);

  Session current(bool current);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Session(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Session(...).copyWith(id: 12, name: "My name")
  /// ````
  Session call({
    String id,
    String deviceName,
    String platform,
    String? appVersion,
    DateTime createdAt,
    DateTime lastSeenAt,
    bool current,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSession.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSession.copyWith.fieldName(...)`
class _$SessionCWProxyImpl implements _$SessionCWProxy {
  const _$SessionCWProxyImpl(this._value);

  final Session _value;

  @override
  Session id(String id) => this(id: id);

  @override
  Session deviceName(String deviceName) => this(deviceName: deviceName);

  @override
  Session platform(String platform) => this(platform: platform);

  @override
  Session appVersion(String? appVersion) => this(appVersion: appVersion);

  @override
  Session createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  Session lastSeenAt(DateTime lastSeenAt) => this(lastSeenAt: lastSeenAt);

  @override
  Session current(bool current) => this(current: current);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Session(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Session(...).copyWith(id: 12, name: "My name")
  /// ````
  Session call({
    Object? id = const $CopyWithPlaceholder(),
    Object? deviceName = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? current = const $CopyWithPlaceholder(),
  }) {
    return Session(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      deviceName: deviceName == const $CopyWithPlaceholder()
          ? _value.deviceName
          // ignore: cast_nullable_to_non_nullable
          : deviceName as String,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String,
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      lastSeenAt: lastSeenAt == const $CopyWithPlaceholder()
          ? _value.lastSeenAt
          // ignore: cast_nullable_to_non_nullable
          : lastSeenAt as DateTime,
      current: current == const $CopyWithPlaceholder()
          ? _value.current
          // ignore: cast_nullable_to_non_nullable
          : current as bool,
    );
  }
}

extension $SessionCopyWith on Session {
  /// Returns a callable class that can be used as follows: `instanceOfSession.copyWith(...)` or like so:`instanceOfSession.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SessionCWProxy get copyWith => _$SessionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Session',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'device_name',
        'platform',
        'created_at',
        'last_seen_at',
        'current',
      ],
    );
    final val = Session(
      id: $checkedConvert('id', (v) => v as String),
      deviceName: $checkedConvert('device_name', (v) => v as String),
      platform: $checkedConvert('platform', (v) => v as String),
      appVersion: $checkedConvert('app_version', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      lastSeenAt: $checkedConvert(
        'last_seen_at',
        (v) => DateTime.parse(v as String),
      ),
      current: $checkedConvert('current', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'deviceName': 'device_name',
    'appVersion': 'app_version',
    'createdAt': 'created_at',
    'lastSeenAt': 'last_seen_at',
  },
);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'id': instance.id,
  'device_name': instance.deviceName,
  'platform': instance.platform,
  'app_version': ?instance.appVersion,
  'created_at': instance.createdAt.toIso8601String(),
  'last_seen_at': instance.lastSeenAt.toIso8601String(),
  'current': instance.current,
};
