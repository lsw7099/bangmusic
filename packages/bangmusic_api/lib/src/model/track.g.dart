// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TrackCWProxy {
  Track id(String id);

  Track title(String title);

  Track titleSort(String? titleSort);

  Track artists(List<ArtistRef> artists);

  Track album(AlbumRef? album);

  Track discNo(int? discNo);

  Track trackNo(int? trackNo);

  Track durationMs(int durationMs);

  Track year(int? year);

  Track genre(String? genre);

  Track artworkId(String? artworkId);

  Track mediaVersion(String mediaVersion);

  Track sourceFormat(SourceFormat? sourceFormat);

  Track state(TrackStateEnum state);

  Track hasLyrics(List<LyricsKind>? hasLyrics);

  Track updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Track(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Track(...).copyWith(id: 12, name: "My name")
  /// ````
  Track call({
    String id,
    String title,
    String? titleSort,
    List<ArtistRef> artists,
    AlbumRef? album,
    int? discNo,
    int? trackNo,
    int durationMs,
    int? year,
    String? genre,
    String? artworkId,
    String mediaVersion,
    SourceFormat? sourceFormat,
    TrackStateEnum state,
    List<LyricsKind>? hasLyrics,
    DateTime updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTrack.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTrack.copyWith.fieldName(...)`
class _$TrackCWProxyImpl implements _$TrackCWProxy {
  const _$TrackCWProxyImpl(this._value);

  final Track _value;

  @override
  Track id(String id) => this(id: id);

  @override
  Track title(String title) => this(title: title);

  @override
  Track titleSort(String? titleSort) => this(titleSort: titleSort);

  @override
  Track artists(List<ArtistRef> artists) => this(artists: artists);

  @override
  Track album(AlbumRef? album) => this(album: album);

  @override
  Track discNo(int? discNo) => this(discNo: discNo);

  @override
  Track trackNo(int? trackNo) => this(trackNo: trackNo);

  @override
  Track durationMs(int durationMs) => this(durationMs: durationMs);

  @override
  Track year(int? year) => this(year: year);

  @override
  Track genre(String? genre) => this(genre: genre);

  @override
  Track artworkId(String? artworkId) => this(artworkId: artworkId);

  @override
  Track mediaVersion(String mediaVersion) => this(mediaVersion: mediaVersion);

  @override
  Track sourceFormat(SourceFormat? sourceFormat) =>
      this(sourceFormat: sourceFormat);

  @override
  Track state(TrackStateEnum state) => this(state: state);

  @override
  Track hasLyrics(List<LyricsKind>? hasLyrics) => this(hasLyrics: hasLyrics);

  @override
  Track updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Track(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Track(...).copyWith(id: 12, name: "My name")
  /// ````
  Track call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? titleSort = const $CopyWithPlaceholder(),
    Object? artists = const $CopyWithPlaceholder(),
    Object? album = const $CopyWithPlaceholder(),
    Object? discNo = const $CopyWithPlaceholder(),
    Object? trackNo = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? year = const $CopyWithPlaceholder(),
    Object? genre = const $CopyWithPlaceholder(),
    Object? artworkId = const $CopyWithPlaceholder(),
    Object? mediaVersion = const $CopyWithPlaceholder(),
    Object? sourceFormat = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? hasLyrics = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Track(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      titleSort: titleSort == const $CopyWithPlaceholder()
          ? _value.titleSort
          // ignore: cast_nullable_to_non_nullable
          : titleSort as String?,
      artists: artists == const $CopyWithPlaceholder()
          ? _value.artists
          // ignore: cast_nullable_to_non_nullable
          : artists as List<ArtistRef>,
      album: album == const $CopyWithPlaceholder()
          ? _value.album
          // ignore: cast_nullable_to_non_nullable
          : album as AlbumRef?,
      discNo: discNo == const $CopyWithPlaceholder()
          ? _value.discNo
          // ignore: cast_nullable_to_non_nullable
          : discNo as int?,
      trackNo: trackNo == const $CopyWithPlaceholder()
          ? _value.trackNo
          // ignore: cast_nullable_to_non_nullable
          : trackNo as int?,
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int,
      year: year == const $CopyWithPlaceholder()
          ? _value.year
          // ignore: cast_nullable_to_non_nullable
          : year as int?,
      genre: genre == const $CopyWithPlaceholder()
          ? _value.genre
          // ignore: cast_nullable_to_non_nullable
          : genre as String?,
      artworkId: artworkId == const $CopyWithPlaceholder()
          ? _value.artworkId
          // ignore: cast_nullable_to_non_nullable
          : artworkId as String?,
      mediaVersion: mediaVersion == const $CopyWithPlaceholder()
          ? _value.mediaVersion
          // ignore: cast_nullable_to_non_nullable
          : mediaVersion as String,
      sourceFormat: sourceFormat == const $CopyWithPlaceholder()
          ? _value.sourceFormat
          // ignore: cast_nullable_to_non_nullable
          : sourceFormat as SourceFormat?,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as TrackStateEnum,
      hasLyrics: hasLyrics == const $CopyWithPlaceholder()
          ? _value.hasLyrics
          // ignore: cast_nullable_to_non_nullable
          : hasLyrics as List<LyricsKind>?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $TrackCopyWith on Track {
  /// Returns a callable class that can be used as follows: `instanceOfTrack.copyWith(...)` or like so:`instanceOfTrack.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TrackCWProxy get copyWith => _$TrackCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Track _$TrackFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Track',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'title',
        'artists',
        'duration_ms',
        'media_version',
        'state',
        'updated_at',
      ],
    );
    final val = Track(
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      titleSort: $checkedConvert('title_sort', (v) => v as String?),
      artists: $checkedConvert(
        'artists',
        (v) => (v as List<dynamic>)
            .map((e) => ArtistRef.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      album: $checkedConvert(
        'album',
        (v) => v == null ? null : AlbumRef.fromJson(v as Map<String, dynamic>),
      ),
      discNo: $checkedConvert('disc_no', (v) => (v as num?)?.toInt()),
      trackNo: $checkedConvert('track_no', (v) => (v as num?)?.toInt()),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num).toInt()),
      year: $checkedConvert('year', (v) => (v as num?)?.toInt()),
      genre: $checkedConvert('genre', (v) => v as String?),
      artworkId: $checkedConvert('artwork_id', (v) => v as String?),
      mediaVersion: $checkedConvert('media_version', (v) => v as String),
      sourceFormat: $checkedConvert(
        'source_format',
        (v) =>
            v == null ? null : SourceFormat.fromJson(v as Map<String, dynamic>),
      ),
      state: $checkedConvert(
        'state',
        (v) => $enumDecode(
          _$TrackStateEnumEnumMap,
          v,
          unknownValue: TrackStateEnum.unknownDefaultOpenApi,
        ),
      ),
      hasLyrics: $checkedConvert(
        'has_lyrics',
        (v) => (v as List<dynamic>?)
            ?.map((e) => $enumDecode(_$LyricsKindEnumMap, e))
            .toList(),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'titleSort': 'title_sort',
    'discNo': 'disc_no',
    'trackNo': 'track_no',
    'durationMs': 'duration_ms',
    'artworkId': 'artwork_id',
    'mediaVersion': 'media_version',
    'sourceFormat': 'source_format',
    'hasLyrics': 'has_lyrics',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$TrackToJson(Track instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'title_sort': ?instance.titleSort,
  'artists': instance.artists.map((e) => e.toJson()).toList(),
  'album': ?instance.album?.toJson(),
  'disc_no': ?instance.discNo,
  'track_no': ?instance.trackNo,
  'duration_ms': instance.durationMs,
  'year': ?instance.year,
  'genre': ?instance.genre,
  'artwork_id': ?instance.artworkId,
  'media_version': instance.mediaVersion,
  'source_format': ?instance.sourceFormat?.toJson(),
  'state': _$TrackStateEnumEnumMap[instance.state]!,
  'has_lyrics': ?instance.hasLyrics
      ?.map((e) => _$LyricsKindEnumMap[e]!)
      .toList(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$TrackStateEnumEnumMap = {
  TrackStateEnum.available: 'available',
  TrackStateEnum.missing: 'missing',
  TrackStateEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$LyricsKindEnumMap = {
  LyricsKind.original: 'original',
  LyricsKind.pronunciationKo: 'pronunciation_ko',
  LyricsKind.translationKo: 'translation_ko',
  LyricsKind.unknownDefaultOpenApi: 'unknown_default_open_api',
};
