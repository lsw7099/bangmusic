// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_edit_ops_inner_one_of2.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistEditOpsInnerOneOf2CWProxy {
  PlaylistEditOpsInnerOneOf2 op(Object? op);

  PlaylistEditOpsInnerOneOf2 itemId(String itemId);

  PlaylistEditOpsInnerOneOf2 afterItemId(String? afterItemId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInnerOneOf2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInnerOneOf2(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInnerOneOf2 call({
    Object? op,
    String itemId,
    String? afterItemId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistEditOpsInnerOneOf2.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistEditOpsInnerOneOf2.copyWith.fieldName(...)`
class _$PlaylistEditOpsInnerOneOf2CWProxyImpl
    implements _$PlaylistEditOpsInnerOneOf2CWProxy {
  const _$PlaylistEditOpsInnerOneOf2CWProxyImpl(this._value);

  final PlaylistEditOpsInnerOneOf2 _value;

  @override
  PlaylistEditOpsInnerOneOf2 op(Object? op) => this(op: op);

  @override
  PlaylistEditOpsInnerOneOf2 itemId(String itemId) => this(itemId: itemId);

  @override
  PlaylistEditOpsInnerOneOf2 afterItemId(String? afterItemId) =>
      this(afterItemId: afterItemId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInnerOneOf2(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInnerOneOf2(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInnerOneOf2 call({
    Object? op = const $CopyWithPlaceholder(),
    Object? itemId = const $CopyWithPlaceholder(),
    Object? afterItemId = const $CopyWithPlaceholder(),
  }) {
    return PlaylistEditOpsInnerOneOf2(
      op: op == const $CopyWithPlaceholder()
          ? _value.op
          // ignore: cast_nullable_to_non_nullable
          : op as Object?,
      itemId: itemId == const $CopyWithPlaceholder()
          ? _value.itemId
          // ignore: cast_nullable_to_non_nullable
          : itemId as String,
      afterItemId: afterItemId == const $CopyWithPlaceholder()
          ? _value.afterItemId
          // ignore: cast_nullable_to_non_nullable
          : afterItemId as String?,
    );
  }
}

extension $PlaylistEditOpsInnerOneOf2CopyWith on PlaylistEditOpsInnerOneOf2 {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistEditOpsInnerOneOf2.copyWith(...)` or like so:`instanceOfPlaylistEditOpsInnerOneOf2.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistEditOpsInnerOneOf2CWProxy get copyWith =>
      _$PlaylistEditOpsInnerOneOf2CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistEditOpsInnerOneOf2 _$PlaylistEditOpsInnerOneOf2FromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PlaylistEditOpsInnerOneOf2',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['op', 'item_id', 'after_item_id']);
    final val = PlaylistEditOpsInnerOneOf2(
      op: $checkedConvert('op', (v) => v),
      itemId: $checkedConvert('item_id', (v) => v as String),
      afterItemId: $checkedConvert('after_item_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'itemId': 'item_id', 'afterItemId': 'after_item_id'},
);

Map<String, dynamic> _$PlaylistEditOpsInnerOneOf2ToJson(
  PlaylistEditOpsInnerOneOf2 instance,
) => <String, dynamic>{
  'op': instance.op,
  'item_id': instance.itemId,
  'after_item_id': instance.afterItemId,
};
