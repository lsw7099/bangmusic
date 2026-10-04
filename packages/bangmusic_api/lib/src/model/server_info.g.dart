// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServerInfoCWProxy {
  ServerInfo serverId(String serverId);

  ServerInfo name(String name);

  ServerInfo product(ServerInfoProductEnum product);

  ServerInfo version(String version);

  ServerInfo api(ServerInfoApi api);

  ServerInfo minClientApiMinor(int minClientApiMinor);

  ServerInfo features(List<String> features);

  ServerInfo transcodeProfiles(List<String>? transcodeProfiles);

  ServerInfo limits(Map<String, int> limits);

  ServerInfo setupRequired(bool setupRequired);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServerInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServerInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  ServerInfo call({
    String serverId,
    String name,
    ServerInfoProductEnum product,
    String version,
    ServerInfoApi api,
    int minClientApiMinor,
    List<String> features,
    List<String>? transcodeProfiles,
    Map<String, int> limits,
    bool setupRequired,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfServerInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfServerInfo.copyWith.fieldName(...)`
class _$ServerInfoCWProxyImpl implements _$ServerInfoCWProxy {
  const _$ServerInfoCWProxyImpl(this._value);

  final ServerInfo _value;

  @override
  ServerInfo serverId(String serverId) => this(serverId: serverId);

  @override
  ServerInfo name(String name) => this(name: name);

  @override
  ServerInfo product(ServerInfoProductEnum product) => this(product: product);

  @override
  ServerInfo version(String version) => this(version: version);

  @override
  ServerInfo api(ServerInfoApi api) => this(api: api);

  @override
  ServerInfo minClientApiMinor(int minClientApiMinor) =>
      this(minClientApiMinor: minClientApiMinor);

  @override
  ServerInfo features(List<String> features) => this(features: features);

  @override
  ServerInfo transcodeProfiles(List<String>? transcodeProfiles) =>
      this(transcodeProfiles: transcodeProfiles);

  @override
  ServerInfo limits(Map<String, int> limits) => this(limits: limits);

  @override
  ServerInfo setupRequired(bool setupRequired) =>
      this(setupRequired: setupRequired);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ServerInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ServerInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  ServerInfo call({
    Object? serverId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? product = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? api = const $CopyWithPlaceholder(),
    Object? minClientApiMinor = const $CopyWithPlaceholder(),
    Object? features = const $CopyWithPlaceholder(),
    Object? transcodeProfiles = const $CopyWithPlaceholder(),
    Object? limits = const $CopyWithPlaceholder(),
    Object? setupRequired = const $CopyWithPlaceholder(),
  }) {
    return ServerInfo(
      serverId: serverId == const $CopyWithPlaceholder()
          ? _value.serverId
          // ignore: cast_nullable_to_non_nullable
          : serverId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      product: product == const $CopyWithPlaceholder()
          ? _value.product
          // ignore: cast_nullable_to_non_nullable
          : product as ServerInfoProductEnum,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      api: api == const $CopyWithPlaceholder()
          ? _value.api
          // ignore: cast_nullable_to_non_nullable
          : api as ServerInfoApi,
      minClientApiMinor: minClientApiMinor == const $CopyWithPlaceholder()
          ? _value.minClientApiMinor
          // ignore: cast_nullable_to_non_nullable
          : minClientApiMinor as int,
      features: features == const $CopyWithPlaceholder()
          ? _value.features
          // ignore: cast_nullable_to_non_nullable
          : features as List<String>,
      transcodeProfiles: transcodeProfiles == const $CopyWithPlaceholder()
          ? _value.transcodeProfiles
          // ignore: cast_nullable_to_non_nullable
          : transcodeProfiles as List<String>?,
      limits: limits == const $CopyWithPlaceholder()
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, int>,
      setupRequired: setupRequired == const $CopyWithPlaceholder()
          ? _value.setupRequired
          // ignore: cast_nullable_to_non_nullable
          : setupRequired as bool,
    );
  }
}

extension $ServerInfoCopyWith on ServerInfo {
  /// Returns a callable class that can be used as follows: `instanceOfServerInfo.copyWith(...)` or like so:`instanceOfServerInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServerInfoCWProxy get copyWith => _$ServerInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerInfo _$ServerInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ServerInfo',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'server_id',
        'name',
        'product',
        'version',
        'api',
        'min_client_api_minor',
        'features',
        'limits',
        'setup_required',
      ],
    );
    final val = ServerInfo(
      serverId: $checkedConvert('server_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      product: $checkedConvert(
        'product',
        (v) => $enumDecode(
          _$ServerInfoProductEnumEnumMap,
          v,
          unknownValue: ServerInfoProductEnum.unknownDefaultOpenApi,
        ),
      ),
      version: $checkedConvert('version', (v) => v as String),
      api: $checkedConvert(
        'api',
        (v) => ServerInfoApi.fromJson(v as Map<String, dynamic>),
      ),
      minClientApiMinor: $checkedConvert(
        'min_client_api_minor',
        (v) => (v as num).toInt(),
      ),
      features: $checkedConvert(
        'features',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      transcodeProfiles: $checkedConvert(
        'transcode_profiles',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      limits: $checkedConvert('limits', (v) => Map<String, int>.from(v as Map)),
      setupRequired: $checkedConvert('setup_required', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'serverId': 'server_id',
    'minClientApiMinor': 'min_client_api_minor',
    'transcodeProfiles': 'transcode_profiles',
    'setupRequired': 'setup_required',
  },
);

Map<String, dynamic> _$ServerInfoToJson(ServerInfo instance) =>
    <String, dynamic>{
      'server_id': instance.serverId,
      'name': instance.name,
      'product': _$ServerInfoProductEnumEnumMap[instance.product]!,
      'version': instance.version,
      'api': instance.api.toJson(),
      'min_client_api_minor': instance.minClientApiMinor,
      'features': instance.features,
      'transcode_profiles': ?instance.transcodeProfiles,
      'limits': instance.limits,
      'setup_required': instance.setupRequired,
    };

const _$ServerInfoProductEnumEnumMap = {
  ServerInfoProductEnum.bangmusicServer: 'bangmusic-server',
  ServerInfoProductEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
