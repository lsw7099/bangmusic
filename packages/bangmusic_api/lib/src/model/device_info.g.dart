// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceInfoCWProxy {
  DeviceInfo name(String name);

  DeviceInfo platform(DeviceInfoPlatformEnum platform);

  DeviceInfo appVersion(String appVersion);

  DeviceInfo installationId(String installationId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeviceInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeviceInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  DeviceInfo call({
    String name,
    DeviceInfoPlatformEnum platform,
    String appVersion,
    String installationId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeviceInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeviceInfo.copyWith.fieldName(...)`
class _$DeviceInfoCWProxyImpl implements _$DeviceInfoCWProxy {
  const _$DeviceInfoCWProxyImpl(this._value);

  final DeviceInfo _value;

  @override
  DeviceInfo name(String name) => this(name: name);

  @override
  DeviceInfo platform(DeviceInfoPlatformEnum platform) =>
      this(platform: platform);

  @override
  DeviceInfo appVersion(String appVersion) => this(appVersion: appVersion);

  @override
  DeviceInfo installationId(String installationId) =>
      this(installationId: installationId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeviceInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeviceInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  DeviceInfo call({
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? installationId = const $CopyWithPlaceholder(),
  }) {
    return DeviceInfo(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as DeviceInfoPlatformEnum,
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String,
      installationId: installationId == const $CopyWithPlaceholder()
          ? _value.installationId
          // ignore: cast_nullable_to_non_nullable
          : installationId as String,
    );
  }
}

extension $DeviceInfoCopyWith on DeviceInfo {
  /// Returns a callable class that can be used as follows: `instanceOfDeviceInfo.copyWith(...)` or like so:`instanceOfDeviceInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceInfoCWProxy get copyWith => _$DeviceInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'DeviceInfo',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'name',
        'platform',
        'app_version',
        'installation_id',
      ],
    );
    final val = DeviceInfo(
      name: $checkedConvert('name', (v) => v as String),
      platform: $checkedConvert(
        'platform',
        (v) => $enumDecode(
          _$DeviceInfoPlatformEnumEnumMap,
          v,
          unknownValue: DeviceInfoPlatformEnum.unknownDefaultOpenApi,
        ),
      ),
      appVersion: $checkedConvert('app_version', (v) => v as String),
      installationId: $checkedConvert('installation_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'appVersion': 'app_version',
    'installationId': 'installation_id',
  },
);

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'platform': _$DeviceInfoPlatformEnumEnumMap[instance.platform]!,
      'app_version': instance.appVersion,
      'installation_id': instance.installationId,
    };

const _$DeviceInfoPlatformEnumEnumMap = {
  DeviceInfoPlatformEnum.android: 'android',
  DeviceInfoPlatformEnum.ios: 'ios',
  DeviceInfoPlatformEnum.other: 'other',
  DeviceInfoPlatformEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
