// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LyricsCWProxy {
  Lyrics trackId(String trackId);

  Lyrics version(int version);

  Lyrics offsetMs(int offsetMs);

  Lyrics variants(List<LyricsVariant> variants);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Lyrics(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Lyrics(...).copyWith(id: 12, name: "My name")
  /// ````
  Lyrics call({
    String trackId,
    int version,
    int offsetMs,
    List<LyricsVariant> variants,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLyrics.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLyrics.copyWith.fieldName(...)`
class _$LyricsCWProxyImpl implements _$LyricsCWProxy {
  const _$LyricsCWProxyImpl(this._value);

  final Lyrics _value;

  @override
  Lyrics trackId(String trackId) => this(trackId: trackId);

  @override
  Lyrics version(int version) => this(version: version);

  @override
  Lyrics offsetMs(int offsetMs) => this(offsetMs: offsetMs);

  @override
  Lyrics variants(List<LyricsVariant> variants) => this(variants: variants);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Lyrics(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Lyrics(...).copyWith(id: 12, name: "My name")
  /// ````
  Lyrics call({
    Object? trackId = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? offsetMs = const $CopyWithPlaceholder(),
    Object? variants = const $CopyWithPlaceholder(),
  }) {
    return Lyrics(
      trackId: trackId == const $CopyWithPlaceholder()
          ? _value.trackId
          // ignore: cast_nullable_to_non_nullable
          : trackId as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      offsetMs: offsetMs == const $CopyWithPlaceholder()
          ? _value.offsetMs
          // ignore: cast_nullable_to_non_nullable
          : offsetMs as int,
      variants: variants == const $CopyWithPlaceholder()
          ? _value.variants
          // ignore: cast_nullable_to_non_nullable
          : variants as List<LyricsVariant>,
    );
  }
}

extension $LyricsCopyWith on Lyrics {
  /// Returns a callable class that can be used as follows: `instanceOfLyrics.copyWith(...)` or like so:`instanceOfLyrics.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LyricsCWProxy get copyWith => _$LyricsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lyrics _$LyricsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Lyrics', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['track_id', 'version', 'offset_ms', 'variants'],
      );
      final val = Lyrics(
        trackId: $checkedConvert('track_id', (v) => v as String),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        offsetMs: $checkedConvert('offset_ms', (v) => (v as num).toInt()),
        variants: $checkedConvert(
          'variants',
          (v) => (v as List<dynamic>)
              .map((e) => LyricsVariant.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'trackId': 'track_id', 'offsetMs': 'offset_ms'});

Map<String, dynamic> _$LyricsToJson(Lyrics instance) => <String, dynamic>{
  'track_id': instance.trackId,
  'version': instance.version,
  'offset_ms': instance.offsetMs,
  'variants': instance.variants.map((e) => e.toJson()).toList(),
};
