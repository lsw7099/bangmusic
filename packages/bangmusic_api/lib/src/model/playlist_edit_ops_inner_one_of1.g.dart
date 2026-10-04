// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_edit_ops_inner_one_of1.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistEditOpsInnerOneOf1CWProxy {
  PlaylistEditOpsInnerOneOf1 op(Object? op);

  PlaylistEditOpsInnerOneOf1 itemIds(List<String> itemIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInnerOneOf1(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInnerOneOf1(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInnerOneOf1 call({Object? op, List<String> itemIds});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistEditOpsInnerOneOf1.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistEditOpsInnerOneOf1.copyWith.fieldName(...)`
class _$PlaylistEditOpsInnerOneOf1CWProxyImpl
    implements _$PlaylistEditOpsInnerOneOf1CWProxy {
  const _$PlaylistEditOpsInnerOneOf1CWProxyImpl(this._value);

  final PlaylistEditOpsInnerOneOf1 _value;

  @override
  PlaylistEditOpsInnerOneOf1 op(Object? op) => this(op: op);

  @override
  PlaylistEditOpsInnerOneOf1 itemIds(List<String> itemIds) =>
      this(itemIds: itemIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInnerOneOf1(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInnerOneOf1(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInnerOneOf1 call({
    Object? op = const $CopyWithPlaceholder(),
    Object? itemIds = const $CopyWithPlaceholder(),
  }) {
    return PlaylistEditOpsInnerOneOf1(
      op: op == const $CopyWithPlaceholder()
          ? _value.op
          // ignore: cast_nullable_to_non_nullable
          : op as Object?,
      itemIds: itemIds == const $CopyWithPlaceholder()
          ? _value.itemIds
          // ignore: cast_nullable_to_non_nullable
          : itemIds as List<String>,
    );
  }
}

extension $PlaylistEditOpsInnerOneOf1CopyWith on PlaylistEditOpsInnerOneOf1 {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistEditOpsInnerOneOf1.copyWith(...)` or like so:`instanceOfPlaylistEditOpsInnerOneOf1.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistEditOpsInnerOneOf1CWProxy get copyWith =>
      _$PlaylistEditOpsInnerOneOf1CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistEditOpsInnerOneOf1 _$PlaylistEditOpsInnerOneOf1FromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlaylistEditOpsInnerOneOf1', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['op', 'item_ids']);
  final val = PlaylistEditOpsInnerOneOf1(
    op: $checkedConvert('op', (v) => v),
    itemIds: $checkedConvert(
      'item_ids',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'itemIds': 'item_ids'});

Map<String, dynamic> _$PlaylistEditOpsInnerOneOf1ToJson(
  PlaylistEditOpsInnerOneOf1 instance,
) => <String, dynamic>{'op': instance.op, 'item_ids': instance.itemIds};
