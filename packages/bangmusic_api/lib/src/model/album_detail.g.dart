// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AlbumDetailCWProxy {
  AlbumDetail id(String id);

  AlbumDetail title(String title);

  AlbumDetail albumArtist(ArtistRef? albumArtist);

  AlbumDetail year(int? year);

  AlbumDetail artworkId(String? artworkId);

  AlbumDetail trackCount(int trackCount);

  AlbumDetail durationMs(int? durationMs);

  AlbumDetail tracks(List<Track> tracks);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AlbumDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AlbumDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  AlbumDetail call({
    String id,
    String title,
    ArtistRef? albumArtist,
    int? year,
    String? artworkId,
    int trackCount,
    int? durationMs,
    List<Track> tracks,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAlbumDetail.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAlbumDetail.copyWith.fieldName(...)`
class _$AlbumDetailCWProxyImpl implements _$AlbumDetailCWProxy {
  const _$AlbumDetailCWProxyImpl(this._value);

  final AlbumDetail _value;

  @override
  AlbumDetail id(String id) => this(id: id);

  @override
  AlbumDetail title(String title) => this(title: title);

  @override
  AlbumDetail albumArtist(ArtistRef? albumArtist) =>
      this(albumArtist: albumArtist);

  @override
  AlbumDetail year(int? year) => this(year: year);

  @override
  AlbumDetail artworkId(String? artworkId) => this(artworkId: artworkId);

  @override
  AlbumDetail trackCount(int trackCount) => this(trackCount: trackCount);

  @override
  AlbumDetail durationMs(int? durationMs) => this(durationMs: durationMs);

  @override
  AlbumDetail tracks(List<Track> tracks) => this(tracks: tracks);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AlbumDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AlbumDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  AlbumDetail call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? albumArtist = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
    Object? artworkId = const $CopyWithPlaceholder(),
    Object? trackCount = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? tracks = const $CopyWithPlaceholder(),
  }) {
    return AlbumDetail(
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
      tracks: tracks == const $CopyWithPlaceholder()
          ? _value.tracks
          // ignore: cast_nullable_to_non_nullable
          : tracks as List<Track>,
    );
  }
}

extension $AlbumDetailCopyWith on AlbumDetail {
  /// Returns a callable class that can be used as follows: `instanceOfAlbumDetail.copyWith(...)` or like so:`instanceOfAlbumDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AlbumDetailCWProxy get copyWith => _$AlbumDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumDetail _$AlbumDetailFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AlbumDetail',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['id', 'title', 'track_count', 'tracks'],
    );
    final val = AlbumDetail(
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
      tracks: $checkedConvert(
        'tracks',
        (v) => (v as List<dynamic>)
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
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

Map<String, dynamic> _$AlbumDetailToJson(AlbumDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'album_artist': ?instance.albumArtist?.toJson(),
      'year': ?instance.year,
      'artwork_id': ?instance.artworkId,
      'track_count': instance.trackCount,
      'duration_ms': ?instance.durationMs,
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };
