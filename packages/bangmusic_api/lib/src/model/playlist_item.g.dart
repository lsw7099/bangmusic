// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistItemCWProxy {
  PlaylistItem itemId(String itemId);

  PlaylistItem available(bool available);

  PlaylistItem track(Track? track);

  PlaylistItem addedAt(DateTime? addedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistItem(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistItem call({
    String itemId,
    bool available,
    Track? track,
    DateTime? addedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistItem.copyWith.fieldName(...)`
class _$PlaylistItemCWProxyImpl implements _$PlaylistItemCWProxy {
  const _$PlaylistItemCWProxyImpl(this._value);

  final PlaylistItem _value;

  @override
  PlaylistItem itemId(String itemId) => this(itemId: itemId);

  @override
  PlaylistItem available(bool available) => this(available: available);

  @override
  PlaylistItem track(Track? track) => this(track: track);

  @override
  PlaylistItem addedAt(DateTime? addedAt) => this(addedAt: addedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistItem(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistItem call({
    Object? itemId = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
    Object? track = const $CopyWithPlaceholder(),
    Object? addedAt = const $CopyWithPlaceholder(),
  }) {
    return PlaylistItem(
      itemId: itemId == const $CopyWithPlaceholder()
          ? _value.itemId
          // ignore: cast_nullable_to_non_nullable
          : itemId as String,
      available: available == const $CopyWithPlaceholder()
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      track: track == const $CopyWithPlaceholder()
          ? _value.track
          // ignore: cast_nullable_to_non_nullable
          : track as Track?,
      addedAt: addedAt == const $CopyWithPlaceholder()
          ? _value.addedAt
          // ignore: cast_nullable_to_non_nullable
          : addedAt as DateTime?,
    );
  }
}

extension $PlaylistItemCopyWith on PlaylistItem {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistItem.copyWith(...)` or like so:`instanceOfPlaylistItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistItemCWProxy get copyWith => _$PlaylistItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistItem _$PlaylistItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaylistItem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['item_id', 'available']);
      final val = PlaylistItem(
        itemId: $checkedConvert('item_id', (v) => v as String),
        available: $checkedConvert('available', (v) => v as bool),
        track: $checkedConvert(
          'track',
          (v) => v == null ? null : Track.fromJson(v as Map<String, dynamic>),
        ),
        addedAt: $checkedConvert(
          'added_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'itemId': 'item_id', 'addedAt': 'added_at'});

Map<String, dynamic> _$PlaylistItemToJson(PlaylistItem instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'available': instance.available,
      'track': ?instance.track?.toJson(),
      'added_at': ?instance.addedAt?.toIso8601String(),
    };
