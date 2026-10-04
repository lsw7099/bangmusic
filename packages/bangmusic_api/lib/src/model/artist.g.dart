// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtistCWProxy {
  Artist id(String id);

  Artist name(String name);

  Artist nameSort(String? nameSort);

  Artist albumCount(int? albumCount);

  Artist trackCount(int? trackCount);

  Artist artworkId(String? artworkId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Artist(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Artist(...).copyWith(id: 12, name: "My name")
  /// ````
  Artist call({
    String id,
    String name,
    String? nameSort,
    int? albumCount,
    int? trackCount,
    String? artworkId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfArtist.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfArtist.copyWith.fieldName(...)`
class _$ArtistCWProxyImpl implements _$ArtistCWProxy {
  const _$ArtistCWProxyImpl(this._value);

  final Artist _value;

  @override
  Artist id(String id) => this(id: id);

  @override
  Artist name(String name) => this(name: name);

  @override
  Artist nameSort(String? nameSort) => this(nameSort: nameSort);

  @override
  Artist albumCount(int? albumCount) => this(albumCount: albumCount);

  @override
  Artist trackCount(int? trackCount) => this(trackCount: trackCount);

  @override
  Artist artworkId(String? artworkId) => this(artworkId: artworkId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Artist(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Artist(...).copyWith(id: 12, name: "My name")
  /// ````
  Artist call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? nameSort = const $CopyWithPlaceholder(),
    Object? albumCount = const $CopyWithPlaceholder(),
    Object? trackCount = const $CopyWithPlaceholder(),
    Object? artworkId = const $CopyWithPlaceholder(),
  }) {
    return Artist(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      nameSort: nameSort == const $CopyWithPlaceholder()
          ? _value.nameSort
          // ignore: cast_nullable_to_non_nullable
          : nameSort as String?,
      albumCount: albumCount == const $CopyWithPlaceholder()
          ? _value.albumCount
          // ignore: cast_nullable_to_non_nullable
          : albumCount as int?,
      trackCount: trackCount == const $CopyWithPlaceholder()
          ? _value.trackCount
          // ignore: cast_nullable_to_non_nullable
          : trackCount as int?,
      artworkId: artworkId == const $CopyWithPlaceholder()
          ? _value.artworkId
          // ignore: cast_nullable_to_non_nullable
          : artworkId as String?,
    );
  }
}

extension $ArtistCopyWith on Artist {
  /// Returns a callable class that can be used as follows: `instanceOfArtist.copyWith(...)` or like so:`instanceOfArtist.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtistCWProxy get copyWith => _$ArtistCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Artist _$ArtistFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Artist',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['id', 'name']);
    final val = Artist(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      nameSort: $checkedConvert('name_sort', (v) => v as String?),
      albumCount: $checkedConvert('album_count', (v) => (v as num?)?.toInt()),
      trackCount: $checkedConvert('track_count', (v) => (v as num?)?.toInt()),
      artworkId: $checkedConvert('artwork_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'nameSort': 'name_sort',
    'albumCount': 'album_count',
    'trackCount': 'track_count',
    'artworkId': 'artwork_id',
  },
);

Map<String, dynamic> _$ArtistToJson(Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'name_sort': ?instance.nameSort,
  'album_count': ?instance.albumCount,
  'track_count': ?instance.trackCount,
  'artwork_id': ?instance.artworkId,
};
