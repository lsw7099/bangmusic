// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_edit_ops_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistEditOpsInnerCWProxy {
  PlaylistEditOpsInner op(Object? op);

  PlaylistEditOpsInner trackIds(List<String> trackIds);

  PlaylistEditOpsInner afterItemId(String afterItemId);

  PlaylistEditOpsInner itemIds(List<String> itemIds);

  PlaylistEditOpsInner itemId(String itemId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInner call({
    Object? op,
    List<String> trackIds,
    String afterItemId,
    List<String> itemIds,
    String itemId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistEditOpsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistEditOpsInner.copyWith.fieldName(...)`
class _$PlaylistEditOpsInnerCWProxyImpl
    implements _$PlaylistEditOpsInnerCWProxy {
  const _$PlaylistEditOpsInnerCWProxyImpl(this._value);

  final PlaylistEditOpsInner _value;

  @override
  PlaylistEditOpsInner op(Object? op) => this(op: op);

  @override
  PlaylistEditOpsInner trackIds(List<String> trackIds) =>
      this(trackIds: trackIds);

  @override
  PlaylistEditOpsInner afterItemId(String afterItemId) =>
      this(afterItemId: afterItemId);

  @override
  PlaylistEditOpsInner itemIds(List<String> itemIds) => this(itemIds: itemIds);

  @override
  PlaylistEditOpsInner itemId(String itemId) => this(itemId: itemId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInner call({
    Object? op = const $CopyWithPlaceholder(),
    Object? trackIds = const $CopyWithPlaceholder(),
    Object? afterItemId = const $CopyWithPlaceholder(),
    Object? itemIds = const $CopyWithPlaceholder(),
    Object? itemId = const $CopyWithPlaceholder(),
  }) {
    return PlaylistEditOpsInner(
      op: op == const $CopyWithPlaceholder()
          ? _value.op
          // ignore: cast_nullable_to_non_nullable
          : op as Object?,
      trackIds: trackIds == const $CopyWithPlaceholder()
          ? _value.trackIds
          // ignore: cast_nullable_to_non_nullable
          : trackIds as List<String>,
      afterItemId: afterItemId == const $CopyWithPlaceholder()
          ? _value.afterItemId
          // ignore: cast_nullable_to_non_nullable
          : afterItemId as String,
      itemIds: itemIds == const $CopyWithPlaceholder()
          ? _value.itemIds
          // ignore: cast_nullable_to_non_nullable
          : itemIds as List<String>,
      itemId: itemId == const $CopyWithPlaceholder()
          ? _value.itemId
          // ignore: cast_nullable_to_non_nullable
          : itemId as String,
    );
  }
}

extension $PlaylistEditOpsInnerCopyWith on PlaylistEditOpsInner {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistEditOpsInner.copyWith(...)` or like so:`instanceOfPlaylistEditOpsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistEditOpsInnerCWProxy get copyWith =>
      _$PlaylistEditOpsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistEditOpsInner _$PlaylistEditOpsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PlaylistEditOpsInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'op',
        'track_ids',
        'after_item_id',
        'item_ids',
        'item_id',
      ],
    );
    final val = PlaylistEditOpsInner(
      op: $checkedConvert('op', (v) => v),
      trackIds: $checkedConvert(
        'track_ids',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      afterItemId: $checkedConvert('after_item_id', (v) => v as String),
      itemIds: $checkedConvert(
        'item_ids',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      itemId: $checkedConvert('item_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'trackIds': 'track_ids',
    'afterItemId': 'after_item_id',
    'itemIds': 'item_ids',
    'itemId': 'item_id',
  },
);

Map<String, dynamic> _$PlaylistEditOpsInnerToJson(
  PlaylistEditOpsInner instance,
) => <String, dynamic>{
  'op': instance.op,
  'track_ids': instance.trackIds,
  'after_item_id': instance.afterItemId,
  'item_ids': instance.itemIds,
  'item_id': instance.itemId,
};
