// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtistRefCWProxy {
  ArtistRef id(String id);

  ArtistRef name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ArtistRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ArtistRef(...).copyWith(id: 12, name: "My name")
  /// ````
  ArtistRef call({String id, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfArtistRef.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfArtistRef.copyWith.fieldName(...)`
class _$ArtistRefCWProxyImpl implements _$ArtistRefCWProxy {
  const _$ArtistRefCWProxyImpl(this._value);

  final ArtistRef _value;

  @override
  ArtistRef id(String id) => this(id: id);

  @override
  ArtistRef name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ArtistRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ArtistRef(...).copyWith(id: 12, name: "My name")
  /// ````
  ArtistRef call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return ArtistRef(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $ArtistRefCopyWith on ArtistRef {
  /// Returns a callable class that can be used as follows: `instanceOfArtistRef.copyWith(...)` or like so:`instanceOfArtistRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtistRefCWProxy get copyWith => _$ArtistRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistRef _$ArtistRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtistRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name']);
      final val = ArtistRef(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ArtistRefToJson(ArtistRef instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
