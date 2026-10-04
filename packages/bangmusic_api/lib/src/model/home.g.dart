// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HomeCWProxy {
  Home playlists(List<Playlist> playlists);

  Home recentTracks(List<Track> recentTracks);

  Home topTracks(List<Track> topTracks);

  Home recentlyAddedAlbums(List<Album> recentlyAddedAlbums);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Home(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Home(...).copyWith(id: 12, name: "My name")
  /// ````
  Home call({
    List<Playlist> playlists,
    List<Track> recentTracks,
    List<Track> topTracks,
    List<Album> recentlyAddedAlbums,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHome.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHome.copyWith.fieldName(...)`
class _$HomeCWProxyImpl implements _$HomeCWProxy {
  const _$HomeCWProxyImpl(this._value);

  final Home _value;

  @override
  Home playlists(List<Playlist> playlists) => this(playlists: playlists);

  @override
  Home recentTracks(List<Track> recentTracks) =>
      this(recentTracks: recentTracks);

  @override
  Home topTracks(List<Track> topTracks) => this(topTracks: topTracks);

  @override
  Home recentlyAddedAlbums(List<Album> recentlyAddedAlbums) =>
      this(recentlyAddedAlbums: recentlyAddedAlbums);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Home(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Home(...).copyWith(id: 12, name: "My name")
  /// ````
  Home call({
    Object? playlists = const $CopyWithPlaceholder(),
    Object? recentTracks = const $CopyWithPlaceholder(),
    Object? topTracks = const $CopyWithPlaceholder(),
    Object? recentlyAddedAlbums = const $CopyWithPlaceholder(),
  }) {
    return Home(
      playlists: playlists == const $CopyWithPlaceholder()
          ? _value.playlists
          // ignore: cast_nullable_to_non_nullable
          : playlists as List<Playlist>,
      recentTracks: recentTracks == const $CopyWithPlaceholder()
          ? _value.recentTracks
          // ignore: cast_nullable_to_non_nullable
          : recentTracks as List<Track>,
      topTracks: topTracks == const $CopyWithPlaceholder()
          ? _value.topTracks
          // ignore: cast_nullable_to_non_nullable
          : topTracks as List<Track>,
      recentlyAddedAlbums: recentlyAddedAlbums == const $CopyWithPlaceholder()
          ? _value.recentlyAddedAlbums
          // ignore: cast_nullable_to_non_nullable
          : recentlyAddedAlbums as List<Album>,
    );
  }
}

extension $HomeCopyWith on Home {
  /// Returns a callable class that can be used as follows: `instanceOfHome.copyWith(...)` or like so:`instanceOfHome.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HomeCWProxy get copyWith => _$HomeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Home _$HomeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Home',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'playlists',
        'recent_tracks',
        'top_tracks',
        'recently_added_albums',
      ],
    );
    final val = Home(
      playlists: $checkedConvert(
        'playlists',
        (v) => (v as List<dynamic>)
            .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      recentTracks: $checkedConvert(
        'recent_tracks',
        (v) => (v as List<dynamic>)
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      topTracks: $checkedConvert(
        'top_tracks',
        (v) => (v as List<dynamic>)
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      recentlyAddedAlbums: $checkedConvert(
        'recently_added_albums',
        (v) => (v as List<dynamic>)
            .map((e) => Album.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'recentTracks': 'recent_tracks',
    'topTracks': 'top_tracks',
    'recentlyAddedAlbums': 'recently_added_albums',
  },
);

Map<String, dynamic> _$HomeToJson(Home instance) => <String, dynamic>{
  'playlists': instance.playlists.map((e) => e.toJson()).toList(),
  'recent_tracks': instance.recentTracks.map((e) => e.toJson()).toList(),
  'top_tracks': instance.topTracks.map((e) => e.toJson()).toList(),
  'recently_added_albums': instance.recentlyAddedAlbums
      .map((e) => e.toJson())
      .toList(),
};
