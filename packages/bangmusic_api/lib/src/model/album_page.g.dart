// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AlbumPageCWProxy {
  AlbumPage items(List<Album> items);

  AlbumPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AlbumPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AlbumPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AlbumPage call({List<Album> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAlbumPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAlbumPage.copyWith.fieldName(...)`
class _$AlbumPageCWProxyImpl implements _$AlbumPageCWProxy {
  const _$AlbumPageCWProxyImpl(this._value);

  final AlbumPage _value;

  @override
  AlbumPage items(List<Album> items) => this(items: items);

  @override
  AlbumPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AlbumPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AlbumPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AlbumPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return AlbumPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Album>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $AlbumPageCopyWith on AlbumPage {
  /// Returns a callable class that can be used as follows: `instanceOfAlbumPage.copyWith(...)` or like so:`instanceOfAlbumPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AlbumPageCWProxy get copyWith => _$AlbumPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumPage _$AlbumPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AlbumPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor']);
      final val = AlbumPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$AlbumPageToJson(AlbumPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': instance.nextCursor,
};
