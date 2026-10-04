// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArtistPageCWProxy {
  ArtistPage items(List<Artist> items);

  ArtistPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ArtistPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ArtistPage(...).copyWith(id: 12, name: "My name")
  /// ````
  ArtistPage call({List<Artist> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfArtistPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfArtistPage.copyWith.fieldName(...)`
class _$ArtistPageCWProxyImpl implements _$ArtistPageCWProxy {
  const _$ArtistPageCWProxyImpl(this._value);

  final ArtistPage _value;

  @override
  ArtistPage items(List<Artist> items) => this(items: items);

  @override
  ArtistPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ArtistPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ArtistPage(...).copyWith(id: 12, name: "My name")
  /// ````
  ArtistPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return ArtistPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Artist>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $ArtistPageCopyWith on ArtistPage {
  /// Returns a callable class that can be used as follows: `instanceOfArtistPage.copyWith(...)` or like so:`instanceOfArtistPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArtistPageCWProxy get copyWith => _$ArtistPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistPage _$ArtistPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtistPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor']);
      final val = ArtistPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$ArtistPageToJson(ArtistPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };
