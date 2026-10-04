// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'format_spec.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FormatSpecCWProxy {
  FormatSpec container(String container);

  FormatSpec codec(String codec);

  FormatSpec maxSampleRate(int? maxSampleRate);

  FormatSpec maxBitDepth(int? maxBitDepth);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FormatSpec(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FormatSpec(...).copyWith(id: 12, name: "My name")
  /// ````
  FormatSpec call({
    String container,
    String codec,
    int? maxSampleRate,
    int? maxBitDepth,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFormatSpec.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFormatSpec.copyWith.fieldName(...)`
class _$FormatSpecCWProxyImpl implements _$FormatSpecCWProxy {
  const _$FormatSpecCWProxyImpl(this._value);

  final FormatSpec _value;

  @override
  FormatSpec container(String container) => this(container: container);

  @override
  FormatSpec codec(String codec) => this(codec: codec);

  @override
  FormatSpec maxSampleRate(int? maxSampleRate) =>
      this(maxSampleRate: maxSampleRate);

  @override
  FormatSpec maxBitDepth(int? maxBitDepth) => this(maxBitDepth: maxBitDepth);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FormatSpec(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FormatSpec(...).copyWith(id: 12, name: "My name")
  /// ````
  FormatSpec call({
    Object? container = const $CopyWithPlaceholder(),
    Object? codec = const $CopyWithPlaceholder(),
    Object? maxSampleRate = const $CopyWithPlaceholder(),
    Object? maxBitDepth = const $CopyWithPlaceholder(),
  }) {
    return FormatSpec(
      container: container == const $CopyWithPlaceholder()
          ? _value.container
          // ignore: cast_nullable_to_non_nullable
          : container as String,
      codec: codec == const $CopyWithPlaceholder()
          ? _value.codec
          // ignore: cast_nullable_to_non_nullable
          : codec as String,
      maxSampleRate: maxSampleRate == const $CopyWithPlaceholder()
          ? _value.maxSampleRate
          // ignore: cast_nullable_to_non_nullable
          : maxSampleRate as int?,
      maxBitDepth: maxBitDepth == const $CopyWithPlaceholder()
          ? _value.maxBitDepth
          // ignore: cast_nullable_to_non_nullable
          : maxBitDepth as int?,
    );
  }
}

extension $FormatSpecCopyWith on FormatSpec {
  /// Returns a callable class that can be used as follows: `instanceOfFormatSpec.copyWith(...)` or like so:`instanceOfFormatSpec.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FormatSpecCWProxy get copyWith => _$FormatSpecCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormatSpec _$FormatSpecFromJson(Map<String, dynamic> json) => $checkedCreate(
  'FormatSpec',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['container', 'codec']);
    final val = FormatSpec(
      container: $checkedConvert('container', (v) => v as String),
      codec: $checkedConvert('codec', (v) => v as String),
      maxSampleRate: $checkedConvert(
        'max_sample_rate',
        (v) => (v as num?)?.toInt(),
      ),
      maxBitDepth: $checkedConvert(
        'max_bit_depth',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'maxSampleRate': 'max_sample_rate',
    'maxBitDepth': 'max_bit_depth',
  },
);

Map<String, dynamic> _$FormatSpecToJson(FormatSpec instance) =>
    <String, dynamic>{
      'container': instance.container,
      'codec': instance.codec,
      'max_sample_rate': ?instance.maxSampleRate,
      'max_bit_depth': ?instance.maxBitDepth,
    };
