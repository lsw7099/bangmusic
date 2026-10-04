// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistPageCWProxy {
  PlaylistPage items(List<Playlist> items);

  PlaylistPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistPage call({List<Playlist> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistPage.copyWith.fieldName(...)`
class _$PlaylistPageCWProxyImpl implements _$PlaylistPageCWProxy {
  const _$PlaylistPageCWProxyImpl(this._value);

  final PlaylistPage _value;

  @override
  PlaylistPage items(List<Playlist> items) => this(items: items);

  @override
  PlaylistPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PlaylistPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Playlist>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PlaylistPageCopyWith on PlaylistPage {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistPage.copyWith(...)` or like so:`instanceOfPlaylistPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistPageCWProxy get copyWith => _$PlaylistPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistPage _$PlaylistPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaylistPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor']);
      final val = PlaylistPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$PlaylistPageToJson(PlaylistPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };
