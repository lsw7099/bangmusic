// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistCWProxy {
  Playlist id(String id);

  Playlist name(String name);

  Playlist description(String? description);

  Playlist artworkId(String? artworkId);

  Playlist mosaicArtworkIds(List<String>? mosaicArtworkIds);

  Playlist version(int version);

  Playlist itemCount(int itemCount);

  Playlist durationMs(int durationMs);

  Playlist createdAt(DateTime? createdAt);

  Playlist updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Playlist(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Playlist(...).copyWith(id: 12, name: "My name")
  /// ````
  Playlist call({
    String id,
    String name,
    String? description,
    String? artworkId,
    List<String>? mosaicArtworkIds,
    int version,
    int itemCount,
    int durationMs,
    DateTime? createdAt,
    DateTime updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylist.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylist.copyWith.fieldName(...)`
class _$PlaylistCWProxyImpl implements _$PlaylistCWProxy {
  const _$PlaylistCWProxyImpl(this._value);

  final Playlist _value;

  @override
  Playlist id(String id) => this(id: id);

  @override
  Playlist name(String name) => this(name: name);

  @override
  Playlist description(String? description) => this(description: description);

  @override
  Playlist artworkId(String? artworkId) => this(artworkId: artworkId);

  @override
  Playlist mosaicArtworkIds(List<String>? mosaicArtworkIds) =>
      this(mosaicArtworkIds: mosaicArtworkIds);

  @override
  Playlist version(int version) => this(version: version);

  @override
  Playlist itemCount(int itemCount) => this(itemCount: itemCount);

  @override
  Playlist durationMs(int durationMs) => this(durationMs: durationMs);

  @override
  Playlist createdAt(DateTime? createdAt) => this(createdAt: createdAt);

  @override
  Playlist updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Playlist(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Playlist(...).copyWith(id: 12, name: "My name")
  /// ````
  Playlist call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? artworkId = const $CopyWithPlaceholder(),
    Object? mosaicArtworkIds = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? itemCount = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Playlist(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      artworkId: artworkId == const $CopyWithPlaceholder()
          ? _value.artworkId
          // ignore: cast_nullable_to_non_nullable
          : artworkId as String?,
      mosaicArtworkIds: mosaicArtworkIds == const $CopyWithPlaceholder()
          ? _value.mosaicArtworkIds
          // ignore: cast_nullable_to_non_nullable
          : mosaicArtworkIds as List<String>?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      itemCount: itemCount == const $CopyWithPlaceholder()
          ? _value.itemCount
          // ignore: cast_nullable_to_non_nullable
          : itemCount as int,
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $PlaylistCopyWith on Playlist {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylist.copyWith(...)` or like so:`instanceOfPlaylist.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistCWProxy get copyWith => _$PlaylistCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Playlist',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'version',
        'item_count',
        'duration_ms',
        'updated_at',
      ],
    );
    final val = Playlist(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String?),
      artworkId: $checkedConvert('artwork_id', (v) => v as String?),
      mosaicArtworkIds: $checkedConvert(
        'mosaic_artwork_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      version: $checkedConvert('version', (v) => (v as num).toInt()),
      itemCount: $checkedConvert('item_count', (v) => (v as num).toInt()),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num).toInt()),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'artworkId': 'artwork_id',
    'mosaicArtworkIds': 'mosaic_artwork_ids',
    'itemCount': 'item_count',
    'durationMs': 'duration_ms',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': ?instance.description,
  'artwork_id': ?instance.artworkId,
  'mosaic_artwork_ids': ?instance.mosaicArtworkIds,
  'version': instance.version,
  'item_count': instance.itemCount,
  'duration_ms': instance.durationMs,
  'created_at': ?instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
