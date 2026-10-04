// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_batch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChangeBatchCWProxy {
  ChangeBatch changes(List<ChangeBatchChangesInner> changes);

  ChangeBatch nextSince(String nextSince);

  ChangeBatch hasMore(bool hasMore);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeBatch(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeBatch(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeBatch call({
    List<ChangeBatchChangesInner> changes,
    String nextSince,
    bool hasMore,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChangeBatch.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChangeBatch.copyWith.fieldName(...)`
class _$ChangeBatchCWProxyImpl implements _$ChangeBatchCWProxy {
  const _$ChangeBatchCWProxyImpl(this._value);

  final ChangeBatch _value;

  @override
  ChangeBatch changes(List<ChangeBatchChangesInner> changes) =>
      this(changes: changes);

  @override
  ChangeBatch nextSince(String nextSince) => this(nextSince: nextSince);

  @override
  ChangeBatch hasMore(bool hasMore) => this(hasMore: hasMore);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeBatch(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeBatch(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeBatch call({
    Object? changes = const $CopyWithPlaceholder(),
    Object? nextSince = const $CopyWithPlaceholder(),
    Object? hasMore = const $CopyWithPlaceholder(),
  }) {
    return ChangeBatch(
      changes: changes == const $CopyWithPlaceholder()
          ? _value.changes
          // ignore: cast_nullable_to_non_nullable
          : changes as List<ChangeBatchChangesInner>,
      nextSince: nextSince == const $CopyWithPlaceholder()
          ? _value.nextSince
          // ignore: cast_nullable_to_non_nullable
          : nextSince as String,
      hasMore: hasMore == const $CopyWithPlaceholder()
          ? _value.hasMore
          // ignore: cast_nullable_to_non_nullable
          : hasMore as bool,
    );
  }
}

extension $ChangeBatchCopyWith on ChangeBatch {
  /// Returns a callable class that can be used as follows: `instanceOfChangeBatch.copyWith(...)` or like so:`instanceOfChangeBatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChangeBatchCWProxy get copyWith => _$ChangeBatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeBatch _$ChangeBatchFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ChangeBatch',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['changes', 'next_since', 'has_more']);
    final val = ChangeBatch(
      changes: $checkedConvert(
        'changes',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  ChangeBatchChangesInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      nextSince: $checkedConvert('next_since', (v) => v as String),
      hasMore: $checkedConvert('has_more', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {'nextSince': 'next_since', 'hasMore': 'has_more'},
);

Map<String, dynamic> _$ChangeBatchToJson(ChangeBatch instance) =>
    <String, dynamic>{
      'changes': instance.changes.map((e) => e.toJson()).toList(),
      'next_since': instance.nextSince,
      'has_more': instance.hasMore,
    };
