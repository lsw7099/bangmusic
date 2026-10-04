// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_variant_lines_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LyricsVariantLinesInnerCWProxy {
  LyricsVariantLinesInner tMs(int? tMs);

  LyricsVariantLinesInner text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LyricsVariantLinesInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LyricsVariantLinesInner(...).copyWith(id: 12, name: "My name")
  /// ````
  LyricsVariantLinesInner call({int? tMs, String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLyricsVariantLinesInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLyricsVariantLinesInner.copyWith.fieldName(...)`
class _$LyricsVariantLinesInnerCWProxyImpl
    implements _$LyricsVariantLinesInnerCWProxy {
  const _$LyricsVariantLinesInnerCWProxyImpl(this._value);

  final LyricsVariantLinesInner _value;

  @override
  LyricsVariantLinesInner tMs(int? tMs) => this(tMs: tMs);

  @override
  LyricsVariantLinesInner text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LyricsVariantLinesInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LyricsVariantLinesInner(...).copyWith(id: 12, name: "My name")
  /// ````
  LyricsVariantLinesInner call({
    Object? tMs = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return LyricsVariantLinesInner(
      tMs: tMs == const $CopyWithPlaceholder()
          ? _value.tMs
          // ignore: cast_nullable_to_non_nullable
          : tMs as int?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $LyricsVariantLinesInnerCopyWith on LyricsVariantLinesInner {
  /// Returns a callable class that can be used as follows: `instanceOfLyricsVariantLinesInner.copyWith(...)` or like so:`instanceOfLyricsVariantLinesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LyricsVariantLinesInnerCWProxy get copyWith =>
      _$LyricsVariantLinesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LyricsVariantLinesInner _$LyricsVariantLinesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LyricsVariantLinesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['t_ms', 'text']);
  final val = LyricsVariantLinesInner(
    tMs: $checkedConvert('t_ms', (v) => (v as num?)?.toInt()),
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'tMs': 't_ms'});

Map<String, dynamic> _$LyricsVariantLinesInnerToJson(
  LyricsVariantLinesInner instance,
) => <String, dynamic>{'t_ms': instance.tMs, 'text': instance.text};
