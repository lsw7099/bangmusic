// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_edit_ops_inner_one_of.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistEditOpsInnerOneOfCWProxy {
  PlaylistEditOpsInnerOneOf op(Object? op);

  PlaylistEditOpsInnerOneOf trackIds(List<String> trackIds);

  PlaylistEditOpsInnerOneOf afterItemId(String? afterItemId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInnerOneOf(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInnerOneOf(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInnerOneOf call({
    Object? op,
    List<String> trackIds,
    String? afterItemId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistEditOpsInnerOneOf.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistEditOpsInnerOneOf.copyWith.fieldName(...)`
class _$PlaylistEditOpsInnerOneOfCWProxyImpl
    implements _$PlaylistEditOpsInnerOneOfCWProxy {
  const _$PlaylistEditOpsInnerOneOfCWProxyImpl(this._value);

  final PlaylistEditOpsInnerOneOf _value;

  @override
  PlaylistEditOpsInnerOneOf op(Object? op) => this(op: op);

  @override
  PlaylistEditOpsInnerOneOf trackIds(List<String> trackIds) =>
      this(trackIds: trackIds);

  @override
  PlaylistEditOpsInnerOneOf afterItemId(String? afterItemId) =>
      this(afterItemId: afterItemId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEditOpsInnerOneOf(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEditOpsInnerOneOf(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEditOpsInnerOneOf call({
    Object? op = const $CopyWithPlaceholder(),
    Object? trackIds = const $CopyWithPlaceholder(),
    Object? afterItemId = const $CopyWithPlaceholder(),
  }) {
    return PlaylistEditOpsInnerOneOf(
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
          : afterItemId as String?,
    );
  }
}

extension $PlaylistEditOpsInnerOneOfCopyWith on PlaylistEditOpsInnerOneOf {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistEditOpsInnerOneOf.copyWith(...)` or like so:`instanceOfPlaylistEditOpsInnerOneOf.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistEditOpsInnerOneOfCWProxy get copyWith =>
      _$PlaylistEditOpsInnerOneOfCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistEditOpsInnerOneOf _$PlaylistEditOpsInnerOneOfFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PlaylistEditOpsInnerOneOf',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['op', 'track_ids']);
    final val = PlaylistEditOpsInnerOneOf(
      op: $checkedConvert('op', (v) => v),
      trackIds: $checkedConvert(
        'track_ids',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      afterItemId: $checkedConvert('after_item_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'trackIds': 'track_ids', 'afterItemId': 'after_item_id'},
);

Map<String, dynamic> _$PlaylistEditOpsInnerOneOfToJson(
  PlaylistEditOpsInnerOneOf instance,
) => <String, dynamic>{
  'op': instance.op,
  'track_ids': instance.trackIds,
  'after_item_id': ?instance.afterItemId,
};
