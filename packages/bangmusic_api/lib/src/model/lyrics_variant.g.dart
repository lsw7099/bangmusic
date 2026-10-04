// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_variant.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LyricsVariantCWProxy {
  LyricsVariant kind(LyricsKind kind);

  LyricsVariant language(String? language);

  LyricsVariant synced(bool synced);

  LyricsVariant lines(List<LyricsVariantLinesInner> lines);

  LyricsVariant source_(LyricsVariantSource source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LyricsVariant(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LyricsVariant(...).copyWith(id: 12, name: "My name")
  /// ````
  LyricsVariant call({
    LyricsKind kind,
    String? language,
    bool synced,
    List<LyricsVariantLinesInner> lines,
    LyricsVariantSource source_,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLyricsVariant.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLyricsVariant.copyWith.fieldName(...)`
class _$LyricsVariantCWProxyImpl implements _$LyricsVariantCWProxy {
  const _$LyricsVariantCWProxyImpl(this._value);

  final LyricsVariant _value;

  @override
  LyricsVariant kind(LyricsKind kind) => this(kind: kind);

  @override
  LyricsVariant language(String? language) => this(language: language);

  @override
  LyricsVariant synced(bool synced) => this(synced: synced);

  @override
  LyricsVariant lines(List<LyricsVariantLinesInner> lines) =>
      this(lines: lines);

  @override
  LyricsVariant source_(LyricsVariantSource source_) => this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LyricsVariant(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LyricsVariant(...).copyWith(id: 12, name: "My name")
  /// ````
  LyricsVariant call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
    Object? synced = const $CopyWithPlaceholder(),
    Object? lines = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return LyricsVariant(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as LyricsKind,
      language: language == const $CopyWithPlaceholder()
          ? _value.language
          // ignore: cast_nullable_to_non_nullable
          : language as String?,
      synced: synced == const $CopyWithPlaceholder()
          ? _value.synced
          // ignore: cast_nullable_to_non_nullable
          : synced as bool,
      lines: lines == const $CopyWithPlaceholder()
          ? _value.lines
          // ignore: cast_nullable_to_non_nullable
          : lines as List<LyricsVariantLinesInner>,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as LyricsVariantSource,
    );
  }
}

extension $LyricsVariantCopyWith on LyricsVariant {
  /// Returns a callable class that can be used as follows: `instanceOfLyricsVariant.copyWith(...)` or like so:`instanceOfLyricsVariant.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LyricsVariantCWProxy get copyWith => _$LyricsVariantCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LyricsVariant _$LyricsVariantFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LyricsVariant', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['kind', 'synced', 'lines', 'source'],
      );
      final val = LyricsVariant(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(
            _$LyricsKindEnumMap,
            v,
            unknownValue: LyricsKind.unknownDefaultOpenApi,
          ),
        ),
        language: $checkedConvert('language', (v) => v as String?),
        synced: $checkedConvert('synced', (v) => v as bool),
        lines: $checkedConvert(
          'lines',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    LyricsVariantLinesInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        source_: $checkedConvert(
          'source',
          (v) => LyricsVariantSource.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$LyricsVariantToJson(LyricsVariant instance) =>
    <String, dynamic>{
      'kind': _$LyricsKindEnumMap[instance.kind]!,
      'language': ?instance.language,
      'synced': instance.synced,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'source': instance.source_.toJson(),
    };

const _$LyricsKindEnumMap = {
  LyricsKind.original: 'original',
  LyricsKind.pronunciationKo: 'pronunciation_ko',
  LyricsKind.translationKo: 'translation_ko',
  LyricsKind.unknownDefaultOpenApi: 'unknown_default_open_api',
};
