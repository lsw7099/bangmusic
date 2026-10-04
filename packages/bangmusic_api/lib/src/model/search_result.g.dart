// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchResultCWProxy {
  SearchResult queryNormalized(String queryNormalized);

  SearchResult tracks(TrackPage? tracks);

  SearchResult albums(AlbumPage? albums);

  SearchResult artists(ArtistPage? artists);

  SearchResult playlists(PlaylistPage? playlists);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchResult(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchResult call({
    String queryNormalized,
    TrackPage? tracks,
    AlbumPage? albums,
    ArtistPage? artists,
    PlaylistPage? playlists,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearchResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearchResult.copyWith.fieldName(...)`
class _$SearchResultCWProxyImpl implements _$SearchResultCWProxy {
  const _$SearchResultCWProxyImpl(this._value);

  final SearchResult _value;

  @override
  SearchResult queryNormalized(String queryNormalized) =>
      this(queryNormalized: queryNormalized);

  @override
  SearchResult tracks(TrackPage? tracks) => this(tracks: tracks);

  @override
  SearchResult albums(AlbumPage? albums) => this(albums: albums);

  @override
  SearchResult artists(ArtistPage? artists) => this(artists: artists);

  @override
  SearchResult playlists(PlaylistPage? playlists) => this(playlists: playlists);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchResult(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchResult call({
    Object? queryNormalized = const $CopyWithPlaceholder(),
    Object? tracks = const $CopyWithPlaceholder(),
    Object? albums = const $CopyWithPlaceholder(),
    Object? artists = const $CopyWithPlaceholder(),
    Object? playlists = const $CopyWithPlaceholder(),
  }) {
    return SearchResult(
      queryNormalized: queryNormalized == const $CopyWithPlaceholder()
          ? _value.queryNormalized
          // ignore: cast_nullable_to_non_nullable
          : queryNormalized as String,
      tracks: tracks == const $CopyWithPlaceholder()
          ? _value.tracks
          // ignore: cast_nullable_to_non_nullable
          : tracks as TrackPage?,
      albums: albums == const $CopyWithPlaceholder()
          ? _value.albums
          // ignore: cast_nullable_to_non_nullable
          : albums as AlbumPage?,
      artists: artists == const $CopyWithPlaceholder()
          ? _value.artists
          // ignore: cast_nullable_to_non_nullable
          : artists as ArtistPage?,
      playlists: playlists == const $CopyWithPlaceholder()
          ? _value.playlists
          // ignore: cast_nullable_to_non_nullable
          : playlists as PlaylistPage?,
    );
  }
}

extension $SearchResultCopyWith on SearchResult {
  /// Returns a callable class that can be used as follows: `instanceOfSearchResult.copyWith(...)` or like so:`instanceOfSearchResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchResultCWProxy get copyWith => _$SearchResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResult _$SearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SearchResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['query_normalized']);
  final val = SearchResult(
    queryNormalized: $checkedConvert('query_normalized', (v) => v as String),
    tracks: $checkedConvert(
      'tracks',
      (v) => v == null ? null : TrackPage.fromJson(v as Map<String, dynamic>),
    ),
    albums: $checkedConvert(
      'albums',
      (v) => v == null ? null : AlbumPage.fromJson(v as Map<String, dynamic>),
    ),
    artists: $checkedConvert(
      'artists',
      (v) => v == null ? null : ArtistPage.fromJson(v as Map<String, dynamic>),
    ),
    playlists: $checkedConvert(
      'playlists',
      (v) =>
          v == null ? null : PlaylistPage.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'queryNormalized': 'query_normalized'});

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) =>
    <String, dynamic>{
      'query_normalized': instance.queryNormalized,
      'tracks': ?instance.tracks?.toJson(),
      'albums': ?instance.albums?.toJson(),
      'artists': ?instance.artists?.toJson(),
      'playlists': ?instance.playlists?.toJson(),
    };
