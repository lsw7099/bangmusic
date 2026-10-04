// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_variant_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LyricsVariantSourceCWProxy {
  LyricsVariantSource type(LyricsVariantSourceTypeEnum type);

  LyricsVariantSource name(String? name);

  LyricsVariantSource licenseNote(String? licenseNote);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LyricsVariantSource(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LyricsVariantSource(...).copyWith(id: 12, name: "My name")
  /// ````
  LyricsVariantSource call({
    LyricsVariantSourceTypeEnum type,
    String? name,
    String? licenseNote,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLyricsVariantSource.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLyricsVariantSource.copyWith.fieldName(...)`
class _$LyricsVariantSourceCWProxyImpl implements _$LyricsVariantSourceCWProxy {
  const _$LyricsVariantSourceCWProxyImpl(this._value);

  final LyricsVariantSource _value;

  @override
  LyricsVariantSource type(LyricsVariantSourceTypeEnum type) =>
      this(type: type);

  @override
  LyricsVariantSource name(String? name) => this(name: name);

  @override
  LyricsVariantSource licenseNote(String? licenseNote) =>
      this(licenseNote: licenseNote);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LyricsVariantSource(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LyricsVariantSource(...).copyWith(id: 12, name: "My name")
  /// ````
  LyricsVariantSource call({
    Object? type = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? licenseNote = const $CopyWithPlaceholder(),
  }) {
    return LyricsVariantSource(
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as LyricsVariantSourceTypeEnum,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      licenseNote: licenseNote == const $CopyWithPlaceholder()
          ? _value.licenseNote
          // ignore: cast_nullable_to_non_nullable
          : licenseNote as String?,
    );
  }
}

extension $LyricsVariantSourceCopyWith on LyricsVariantSource {
  /// Returns a callable class that can be used as follows: `instanceOfLyricsVariantSource.copyWith(...)` or like so:`instanceOfLyricsVariantSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LyricsVariantSourceCWProxy get copyWith =>
      _$LyricsVariantSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LyricsVariantSource _$LyricsVariantSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LyricsVariantSource', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['type']);
      final val = LyricsVariantSource(
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(
            _$LyricsVariantSourceTypeEnumEnumMap,
            v,
            unknownValue: LyricsVariantSourceTypeEnum.unknownDefaultOpenApi,
          ),
        ),
        name: $checkedConvert('name', (v) => v as String?),
        licenseNote: $checkedConvert('license_note', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'licenseNote': 'license_note'});

Map<String, dynamic> _$LyricsVariantSourceToJson(
  LyricsVariantSource instance,
) => <String, dynamic>{
  'type': _$LyricsVariantSourceTypeEnumEnumMap[instance.type]!,
  'name': ?instance.name,
  'license_note': ?instance.licenseNote,
};

const _$LyricsVariantSourceTypeEnumEnumMap = {
  LyricsVariantSourceTypeEnum.sidecar: 'sidecar',
  LyricsVariantSourceTypeEnum.embedded: 'embedded',
  LyricsVariantSourceTypeEnum.user: 'user',
  LyricsVariantSourceTypeEnum.provider: 'provider',
  LyricsVariantSourceTypeEnum.generated: 'generated',
  LyricsVariantSourceTypeEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
