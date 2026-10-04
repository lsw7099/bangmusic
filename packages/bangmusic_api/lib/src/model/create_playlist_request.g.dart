// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_playlist_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatePlaylistRequestCWProxy {
  CreatePlaylistRequest name(String name);

  CreatePlaylistRequest description(String? description);

  CreatePlaylistRequest trackIds(List<String>? trackIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreatePlaylistRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreatePlaylistRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreatePlaylistRequest call({
    String name,
    String? description,
    List<String>? trackIds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreatePlaylistRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreatePlaylistRequest.copyWith.fieldName(...)`
class _$CreatePlaylistRequestCWProxyImpl
    implements _$CreatePlaylistRequestCWProxy {
  const _$CreatePlaylistRequestCWProxyImpl(this._value);

  final CreatePlaylistRequest _value;

  @override
  CreatePlaylistRequest name(String name) => this(name: name);

  @override
  CreatePlaylistRequest description(String? description) =>
      this(description: description);

  @override
  CreatePlaylistRequest trackIds(List<String>? trackIds) =>
      this(trackIds: trackIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreatePlaylistRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreatePlaylistRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreatePlaylistRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? trackIds = const $CopyWithPlaceholder(),
  }) {
    return CreatePlaylistRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      trackIds: trackIds == const $CopyWithPlaceholder()
          ? _value.trackIds
          // ignore: cast_nullable_to_non_nullable
          : trackIds as List<String>?,
    );
  }
}

extension $CreatePlaylistRequestCopyWith on CreatePlaylistRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreatePlaylistRequest.copyWith(...)` or like so:`instanceOfCreatePlaylistRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatePlaylistRequestCWProxy get copyWith =>
      _$CreatePlaylistRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePlaylistRequest _$CreatePlaylistRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreatePlaylistRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name']);
  final val = CreatePlaylistRequest(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String?),
    trackIds: $checkedConvert(
      'track_ids',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'trackIds': 'track_ids'});

Map<String, dynamic> _$CreatePlaylistRequestToJson(
  CreatePlaylistRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': ?instance.description,
  'track_ids': ?instance.trackIds,
};
