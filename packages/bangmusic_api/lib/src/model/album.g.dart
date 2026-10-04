// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AlbumCWProxy {
  Album id(String id);

  Album title(String title);

  Album albumArtist(ArtistRef? albumArtist);

  Album year(int? year);

  Album artworkId(String? artworkId);

  Album trackCount(int trackCount);

  Album durationMs(int? durationMs);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Album(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Album(...).copyWith(id: 12, name: "My name")
  /// ````
  Album call({
    String id,
    String title,
    ArtistRef? albumArtist,
    int? year,
    String? artworkId,
    int trackCount,
    int? durationMs,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAlbum.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAlbum.copyWith.fieldName(...)`
class _$AlbumCWProxyImpl implements _$AlbumCWProxy {
  const _$AlbumCWProxyImpl(this._value);

  final Album _value;

  @override
  Album id(String id) => this(id: id);

  @override
  Album title(String title) => this(title: title);

  @override
  Album albumArtist(ArtistRef? albumArtist) => this(albumArtist: albumArtist);

  @override
  Album year(int? year) => this(year: year);

  @override
  Album artworkId(String? artworkId) => this(artworkId: artworkId);

  @override
  Album trackCount(int trackCount) => this(trackCount: trackCount);

  @override
  Album durationMs(int? durationMs) => this(durationMs: durationMs);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Album(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Album(...).copyWith(id: 12, name: "My name")
  /// ````
  Album call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? albumArtist = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
    Object? artworkId = const $CopyWithPlaceholder(),
    Object? trackCount = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
  }) {
    return Album(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      albumArtist: albumArtist == const $CopyWithPlaceholder()
          ? _value.albumArtist
          // ignore: cast_nullable_to_non_nullable
          : albumArtist as ArtistRef?,
      year: year == const $CopyWithPlaceholder()
          ? _value.year
          // ignore: cast_nullable_to_non_nullable
          : year as int?,
      artworkId: artworkId == const $CopyWithPlaceholder()
          ? _value.artworkId
          // ignore: cast_nullable_to_non_nullable
          : artworkId as String?,
      trackCount: trackCount == const $CopyWithPlaceholder()
          ? _value.trackCount
          // ignore: cast_nullable_to_non_nullable
          : trackCount as int,
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int?,
    );
  }
}

extension $AlbumCopyWith on Album {
  /// Returns a callable class that can be used as follows: `instanceOfAlbum.copyWith(...)` or like so:`instanceOfAlbum.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AlbumCWProxy get copyWith => _$AlbumCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Album',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['id', 'title', 'track_count']);
    final val = Album(
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      albumArtist: $checkedConvert(
        'album_artist',
        (v) => v == null ? null : ArtistRef.fromJson(v as Map<String, dynamic>),
      ),
      year: $checkedConvert('year', (v) => (v as num?)?.toInt()),
      artworkId: $checkedConvert('artwork_id', (v) => v as String?),
      trackCount: $checkedConvert('track_count', (v) => (v as num).toInt()),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'albumArtist': 'album_artist',
    'artworkId': 'artwork_id',
    'trackCount': 'track_count',
    'durationMs': 'duration_ms',
  },
);

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'album_artist': ?instance.albumArtist?.toJson(),
  'year': ?instance.year,
  'artwork_id': ?instance.artworkId,
  'track_count': instance.trackCount,
  'duration_ms': ?instance.durationMs,
};
