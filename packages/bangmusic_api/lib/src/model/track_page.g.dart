// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TrackPageCWProxy {
  TrackPage items(List<Track> items);

  TrackPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TrackPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TrackPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TrackPage call({List<Track> items, String? nextCursor});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTrackPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTrackPage.copyWith.fieldName(...)`
class _$TrackPageCWProxyImpl implements _$TrackPageCWProxy {
  const _$TrackPageCWProxyImpl(this._value);

  final TrackPage _value;

  @override
  TrackPage items(List<Track> items) => this(items: items);

  @override
  TrackPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TrackPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TrackPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TrackPage call({
    Object? items = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return TrackPage(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Track>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $TrackPageCopyWith on TrackPage {
  /// Returns a callable class that can be used as follows: `instanceOfTrackPage.copyWith(...)` or like so:`instanceOfTrackPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TrackPageCWProxy get copyWith => _$TrackPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackPage _$TrackPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TrackPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'next_cursor']);
      final val = TrackPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$TrackPageToJson(TrackPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': instance.nextCursor,
};
