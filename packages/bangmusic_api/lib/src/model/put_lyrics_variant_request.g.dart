// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put_lyrics_variant_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PutLyricsVariantRequestCWProxy {
  PutLyricsVariantRequest format(PutLyricsVariantRequestFormatEnum format);

  PutLyricsVariantRequest language(String? language);

  PutLyricsVariantRequest body(String body);

  PutLyricsVariantRequest sourceName(String? sourceName);

  PutLyricsVariantRequest licenseNote(String? licenseNote);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PutLyricsVariantRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PutLyricsVariantRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PutLyricsVariantRequest call({
    PutLyricsVariantRequestFormatEnum format,
    String? language,
    String body,
    String? sourceName,
    String? licenseNote,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPutLyricsVariantRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPutLyricsVariantRequest.copyWith.fieldName(...)`
class _$PutLyricsVariantRequestCWProxyImpl
    implements _$PutLyricsVariantRequestCWProxy {
  const _$PutLyricsVariantRequestCWProxyImpl(this._value);

  final PutLyricsVariantRequest _value;

  @override
  PutLyricsVariantRequest format(PutLyricsVariantRequestFormatEnum format) =>
      this(format: format);

  @override
  PutLyricsVariantRequest language(String? language) =>
      this(language: language);

  @override
  PutLyricsVariantRequest body(String body) => this(body: body);

  @override
  PutLyricsVariantRequest sourceName(String? sourceName) =>
      this(sourceName: sourceName);

  @override
  PutLyricsVariantRequest licenseNote(String? licenseNote) =>
      this(licenseNote: licenseNote);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PutLyricsVariantRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PutLyricsVariantRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PutLyricsVariantRequest call({
    Object? format = const $CopyWithPlaceholder(),
    Object? language = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? sourceName = const $CopyWithPlaceholder(),
    Object? licenseNote = const $CopyWithPlaceholder(),
  }) {
    return PutLyricsVariantRequest(
      format: format == const $CopyWithPlaceholder()
          ? _value.format
          // ignore: cast_nullable_to_non_nullable
          : format as PutLyricsVariantRequestFormatEnum,
      language: language == const $CopyWithPlaceholder()
          ? _value.language
          // ignore: cast_nullable_to_non_nullable
          : language as String?,
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      sourceName: sourceName == const $CopyWithPlaceholder()
          ? _value.sourceName
          // ignore: cast_nullable_to_non_nullable
          : sourceName as String?,
      licenseNote: licenseNote == const $CopyWithPlaceholder()
          ? _value.licenseNote
          // ignore: cast_nullable_to_non_nullable
          : licenseNote as String?,
    );
  }
}

extension $PutLyricsVariantRequestCopyWith on PutLyricsVariantRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPutLyricsVariantRequest.copyWith(...)` or like so:`instanceOfPutLyricsVariantRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PutLyricsVariantRequestCWProxy get copyWith =>
      _$PutLyricsVariantRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutLyricsVariantRequest _$PutLyricsVariantRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PutLyricsVariantRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['format', 'body']);
    final val = PutLyricsVariantRequest(
      format: $checkedConvert(
        'format',
        (v) => $enumDecode(
          _$PutLyricsVariantRequestFormatEnumEnumMap,
          v,
          unknownValue: PutLyricsVariantRequestFormatEnum.unknownDefaultOpenApi,
        ),
      ),
      language: $checkedConvert('language', (v) => v as String?),
      body: $checkedConvert('body', (v) => v as String),
      sourceName: $checkedConvert('source_name', (v) => v as String?),
      licenseNote: $checkedConvert('license_note', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'sourceName': 'source_name',
    'licenseNote': 'license_note',
  },
);

Map<String, dynamic> _$PutLyricsVariantRequestToJson(
  PutLyricsVariantRequest instance,
) => <String, dynamic>{
  'format': _$PutLyricsVariantRequestFormatEnumEnumMap[instance.format]!,
  'language': ?instance.language,
  'body': instance.body,
  'source_name': ?instance.sourceName,
  'license_note': ?instance.licenseNote,
};

const _$PutLyricsVariantRequestFormatEnumEnumMap = {
  PutLyricsVariantRequestFormatEnum.lrc: 'lrc',
  PutLyricsVariantRequestFormatEnum.plain: 'plain',
  PutLyricsVariantRequestFormatEnum.unknownDefaultOpenApi:
      'unknown_default_open_api',
};
