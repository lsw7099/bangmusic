// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AlbumRefCWProxy {
  AlbumRef id(String id);

  AlbumRef title(String title);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AlbumRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AlbumRef(...).copyWith(id: 12, name: "My name")
  /// ````
  AlbumRef call({String id, String title});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAlbumRef.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAlbumRef.copyWith.fieldName(...)`
class _$AlbumRefCWProxyImpl implements _$AlbumRefCWProxy {
  const _$AlbumRefCWProxyImpl(this._value);

  final AlbumRef _value;

  @override
  AlbumRef id(String id) => this(id: id);

  @override
  AlbumRef title(String title) => this(title: title);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AlbumRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AlbumRef(...).copyWith(id: 12, name: "My name")
  /// ````
  AlbumRef call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
  }) {
    return AlbumRef(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
    );
  }
}

extension $AlbumRefCopyWith on AlbumRef {
  /// Returns a callable class that can be used as follows: `instanceOfAlbumRef.copyWith(...)` or like so:`instanceOfAlbumRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AlbumRefCWProxy get copyWith => _$AlbumRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumRef _$AlbumRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AlbumRef', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'title']);
      final val = AlbumRef(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AlbumRefToJson(AlbumRef instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};
