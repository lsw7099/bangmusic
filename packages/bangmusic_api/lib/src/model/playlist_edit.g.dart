// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_edit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaylistEditCWProxy {
  PlaylistEdit ops(List<PlaylistEditOpsInner> ops);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEdit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEdit(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEdit call({List<PlaylistEditOpsInner> ops});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlaylistEdit.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlaylistEdit.copyWith.fieldName(...)`
class _$PlaylistEditCWProxyImpl implements _$PlaylistEditCWProxy {
  const _$PlaylistEditCWProxyImpl(this._value);

  final PlaylistEdit _value;

  @override
  PlaylistEdit ops(List<PlaylistEditOpsInner> ops) => this(ops: ops);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlaylistEdit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlaylistEdit(...).copyWith(id: 12, name: "My name")
  /// ````
  PlaylistEdit call({Object? ops = const $CopyWithPlaceholder()}) {
    return PlaylistEdit(
      ops: ops == const $CopyWithPlaceholder()
          ? _value.ops
          // ignore: cast_nullable_to_non_nullable
          : ops as List<PlaylistEditOpsInner>,
    );
  }
}

extension $PlaylistEditCopyWith on PlaylistEdit {
  /// Returns a callable class that can be used as follows: `instanceOfPlaylistEdit.copyWith(...)` or like so:`instanceOfPlaylistEdit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaylistEditCWProxy get copyWith => _$PlaylistEditCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistEdit _$PlaylistEditFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaylistEdit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ops']);
      final val = PlaylistEdit(
        ops: $checkedConvert(
          'ops',
          (v) => (v as List<dynamic>)
              .map(
                (e) => PlaylistEditOpsInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlaylistEditToJson(PlaylistEdit instance) =>
    <String, dynamic>{'ops': instance.ops.map((e) => e.toJson()).toList()};
