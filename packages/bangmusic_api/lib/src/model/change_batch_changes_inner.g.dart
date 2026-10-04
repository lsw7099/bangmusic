// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_batch_changes_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChangeBatchChangesInnerCWProxy {
  ChangeBatchChangesInner entity(ChangeBatchChangesInnerEntityEnum entity);

  ChangeBatchChangesInner id(String id);

  ChangeBatchChangesInner op(ChangeBatchChangesInnerOpEnum op);

  ChangeBatchChangesInner track(Track? track);

  ChangeBatchChangesInner album(Album? album);

  ChangeBatchChangesInner artist(Artist? artist);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeBatchChangesInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeBatchChangesInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeBatchChangesInner call({
    ChangeBatchChangesInnerEntityEnum entity,
    String id,
    ChangeBatchChangesInnerOpEnum op,
    Track? track,
    Album? album,
    Artist? artist,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChangeBatchChangesInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChangeBatchChangesInner.copyWith.fieldName(...)`
class _$ChangeBatchChangesInnerCWProxyImpl
    implements _$ChangeBatchChangesInnerCWProxy {
  const _$ChangeBatchChangesInnerCWProxyImpl(this._value);

  final ChangeBatchChangesInner _value;

  @override
  ChangeBatchChangesInner entity(ChangeBatchChangesInnerEntityEnum entity) =>
      this(entity: entity);

  @override
  ChangeBatchChangesInner id(String id) => this(id: id);

  @override
  ChangeBatchChangesInner op(ChangeBatchChangesInnerOpEnum op) => this(op: op);

  @override
  ChangeBatchChangesInner track(Track? track) => this(track: track);

  @override
  ChangeBatchChangesInner album(Album? album) => this(album: album);

  @override
  ChangeBatchChangesInner artist(Artist? artist) => this(artist: artist);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeBatchChangesInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeBatchChangesInner(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeBatchChangesInner call({
    Object? entity = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? op = const $CopyWithPlaceholder(),
    Object? track = const $CopyWithPlaceholder(),
    Object? album = const $CopyWithPlaceholder(),
    Object? artist = const $CopyWithPlaceholder(),
  }) {
    return ChangeBatchChangesInner(
      entity: entity == const $CopyWithPlaceholder()
          ? _value.entity
          // ignore: cast_nullable_to_non_nullable
          : entity as ChangeBatchChangesInnerEntityEnum,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      op: op == const $CopyWithPlaceholder()
          ? _value.op
          // ignore: cast_nullable_to_non_nullable
          : op as ChangeBatchChangesInnerOpEnum,
      track: track == const $CopyWithPlaceholder()
          ? _value.track
          // ignore: cast_nullable_to_non_nullable
          : track as Track?,
      album: album == const $CopyWithPlaceholder()
          ? _value.album
          // ignore: cast_nullable_to_non_nullable
          : album as Album?,
      artist: artist == const $CopyWithPlaceholder()
          ? _value.artist
          // ignore: cast_nullable_to_non_nullable
          : artist as Artist?,
    );
  }
}

extension $ChangeBatchChangesInnerCopyWith on ChangeBatchChangesInner {
  /// Returns a callable class that can be used as follows: `instanceOfChangeBatchChangesInner.copyWith(...)` or like so:`instanceOfChangeBatchChangesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChangeBatchChangesInnerCWProxy get copyWith =>
      _$ChangeBatchChangesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeBatchChangesInner _$ChangeBatchChangesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ChangeBatchChangesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['entity', 'id', 'op']);
  final val = ChangeBatchChangesInner(
    entity: $checkedConvert(
      'entity',
      (v) => $enumDecode(
        _$ChangeBatchChangesInnerEntityEnumEnumMap,
        v,
        unknownValue: ChangeBatchChangesInnerEntityEnum.unknownDefaultOpenApi,
      ),
    ),
    id: $checkedConvert('id', (v) => v as String),
    op: $checkedConvert(
      'op',
      (v) => $enumDecode(
        _$ChangeBatchChangesInnerOpEnumEnumMap,
        v,
        unknownValue: ChangeBatchChangesInnerOpEnum.unknownDefaultOpenApi,
      ),
    ),
    track: $checkedConvert(
      'track',
      (v) => v == null ? null : Track.fromJson(v as Map<String, dynamic>),
    ),
    album: $checkedConvert(
      'album',
      (v) => v == null ? null : Album.fromJson(v as Map<String, dynamic>),
    ),
    artist: $checkedConvert(
      'artist',
      (v) => v == null ? null : Artist.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$ChangeBatchChangesInnerToJson(
  ChangeBatchChangesInner instance,
) => <String, dynamic>{
  'entity': _$ChangeBatchChangesInnerEntityEnumEnumMap[instance.entity]!,
  'id': instance.id,
  'op': _$ChangeBatchChangesInnerOpEnumEnumMap[instance.op]!,
  'track': ?instance.track?.toJson(),
  'album': ?instance.album?.toJson(),
  'artist': ?instance.artist?.toJson(),
};

const _$ChangeBatchChangesInnerEntityEnumEnumMap = {
  ChangeBatchChangesInnerEntityEnum.track: 'track',
  ChangeBatchChangesInnerEntityEnum.album: 'album',
  ChangeBatchChangesInnerEntityEnum.artist: 'artist',
  ChangeBatchChangesInnerEntityEnum.unknownDefaultOpenApi:
      'unknown_default_open_api',
};

const _$ChangeBatchChangesInnerOpEnumEnumMap = {
  ChangeBatchChangesInnerOpEnum.upsert: 'upsert',
  ChangeBatchChangesInnerOpEnum.delete: 'delete',
  ChangeBatchChangesInnerOpEnum.unknownDefaultOpenApi:
      'unknown_default_open_api',
};
