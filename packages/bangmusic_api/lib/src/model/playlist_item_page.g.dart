// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_item_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistItemPageCWProxy {
  PlaylistItemPage items(List<PlaylistItem> items);

  PlaylistItemPage nextCursor(String? nextCursor);

  PlaylistItemPage version(int version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistItemPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistItemPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistItemPage call({
    List<PlaylistItem> items,
    String? nextCursor,
    int version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistItemPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistItemPage.copyWith.fieldName(...)`
class _$PlaylistItemPageCWProxyImpl implements _$PlaylistItemPageCWProxy {
  const _$PlaylistItemPageCWProxyImpl(this._value);

  final PlaylistItemPage _value;

  @override
  PlaylistItemPage items(List<PlaylistItem> items) => this(items: items);

  @override
  PlaylistItemPage nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  PlaylistItemPage version(int version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistItemPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistItemPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistItemPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return PlaylistItemPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PlaylistItem>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $PlaylistItemPageCopyWith on PlaylistItemPage {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistItemPage.copyWith(...)` or like so:`instanceOfPlaylistItemPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistItemPageCWProxy get copyWith => _$PlaylistItemPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistItemPage _$PlaylistItemPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaylistItemPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor', 'version']);
      final val = PlaylistItemPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PlaylistItemPageToJson(PlaylistItemPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'version': instance.version,
    };
