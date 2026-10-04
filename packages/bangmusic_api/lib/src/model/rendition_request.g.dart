// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rendition_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RenditionRequestCWProxy {
  RenditionRequest purpose(RenditionRequestPurposeEnum purpose);

  RenditionRequest quality(String quality);

  RenditionRequest accept(List<FormatSpec> accept);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RenditionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RenditionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RenditionRequest call({
    RenditionRequestPurposeEnum purpose,
    String quality,
    List<FormatSpec> accept,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRenditionRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRenditionRequest.copyWith.fieldName(...)`
class _$RenditionRequestCWProxyImpl implements _$RenditionRequestCWProxy {
  const _$RenditionRequestCWProxyImpl(this._value);

  final RenditionRequest _value;

  @override
  RenditionRequest purpose(RenditionRequestPurposeEnum purpose) =>
      this(purpose: purpose);

  @override
  RenditionRequest quality(String quality) => this(quality: quality);

  @override
  RenditionRequest accept(List<FormatSpec> accept) => this(accept: accept);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RenditionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RenditionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RenditionRequest call({
    Object? purpose = const $CopyWithPlaceholder(),
    Object? quality = const $CopyWithPlaceholder(),
    Object? accept = const $CopyWithPlaceholder(),
  }) {
    return RenditionRequest(
      purpose: purpose == const $CopyWithPlaceholder()
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as RenditionRequestPurposeEnum,
      quality: quality == const $CopyWithPlaceholder()
          ? _value.quality
          // ignore: cast_nullable_to_non_nullable
          : quality as String,
      accept: accept == const $CopyWithPlaceholder()
          ? _value.accept
          // ignore: cast_nullable_to_non_nullable
          : accept as List<FormatSpec>,
    );
  }
}

extension $RenditionRequestCopyWith on RenditionRequest {
  /// Returns a callable class that can be used as follows: `instanceOfRenditionRequest.copyWith(...)` or like so:`instanceOfRenditionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RenditionRequestCWProxy get copyWith => _$RenditionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RenditionRequest _$RenditionRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RenditionRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['purpose', 'quality', 'accept']);
      final val = RenditionRequest(
        purpose: $checkedConvert(
          'purpose',
          (v) => $enumDecode(
            _$RenditionRequestPurposeEnumEnumMap,
            v,
            unknownValue: RenditionRequestPurposeEnum.unknownDefaultOpenApi,
          ),
        ),
        quality: $checkedConvert('quality', (v) => v as String),
        accept: $checkedConvert(
          'accept',
          (v) => (v as List<dynamic>)
              .map((e) => FormatSpec.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RenditionRequestToJson(RenditionRequest instance) =>
    <String, dynamic>{
      'purpose': _$RenditionRequestPurposeEnumEnumMap[instance.purpose]!,
      'quality': instance.quality,
      'accept': instance.accept.map((e) => e.toJson()).toList(),
    };

const _$RenditionRequestPurposeEnumEnumMap = {
  RenditionRequestPurposeEnum.stream: 'stream',
  RenditionRequestPurposeEnum.download: 'download',
  RenditionRequestPurposeEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
