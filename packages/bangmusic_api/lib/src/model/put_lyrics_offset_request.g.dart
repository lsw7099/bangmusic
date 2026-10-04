// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put_lyrics_offset_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PutLyricsOffsetRequestCWProxy {
  PutLyricsOffsetRequest offsetMs(int offsetMs);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PutLyricsOffsetRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PutLyricsOffsetRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PutLyricsOffsetRequest call({int offsetMs});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPutLyricsOffsetRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPutLyricsOffsetRequest.copyWith.fieldName(...)`
class _$PutLyricsOffsetRequestCWProxyImpl
    implements _$PutLyricsOffsetRequestCWProxy {
  const _$PutLyricsOffsetRequestCWProxyImpl(this._value);

  final PutLyricsOffsetRequest _value;

  @override
  PutLyricsOffsetRequest offsetMs(int offsetMs) => this(offsetMs: offsetMs);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PutLyricsOffsetRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PutLyricsOffsetRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PutLyricsOffsetRequest call({
    Object? offsetMs = const $CopyWithPlaceholder(),
  }) {
    return PutLyricsOffsetRequest(
      offsetMs: offsetMs == const $CopyWithPlaceholder()
          ? _value.offsetMs
          // ignore: cast_nullable_to_non_nullable
          : offsetMs as int,
    );
  }
}

extension $PutLyricsOffsetRequestCopyWith on PutLyricsOffsetRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPutLyricsOffsetRequest.copyWith(...)` or like so:`instanceOfPutLyricsOffsetRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PutLyricsOffsetRequestCWProxy get copyWith =>
      _$PutLyricsOffsetRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutLyricsOffsetRequest _$PutLyricsOffsetRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PutLyricsOffsetRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['offset_ms']);
  final val = PutLyricsOffsetRequest(
    offsetMs: $checkedConvert('offset_ms', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'offsetMs': 'offset_ms'});

Map<String, dynamic> _$PutLyricsOffsetRequestToJson(
  PutLyricsOffsetRequest instance,
) => <String, dynamic>{'offset_ms': instance.offsetMs};
