// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_format.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SourceFormatCWProxy {
  SourceFormat container(String container);

  SourceFormat codec(String codec);

  SourceFormat sampleRate(int? sampleRate);

  SourceFormat channels(int? channels);

  SourceFormat bitDepth(int? bitDepth);

  SourceFormat bitrate(int? bitrate);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SourceFormat(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SourceFormat(...).copyWith(id: 12, name: "My name")
  /// ````
  SourceFormat call({
    String container,
    String codec,
    int? sampleRate,
    int? channels,
    int? bitDepth,
    int? bitrate,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSourceFormat.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSourceFormat.copyWith.fieldName(...)`
class _$SourceFormatCWProxyImpl implements _$SourceFormatCWProxy {
  const _$SourceFormatCWProxyImpl(this._value);

  final SourceFormat _value;

  @override
  SourceFormat container(String container) => this(container: container);

  @override
  SourceFormat codec(String codec) => this(codec: codec);

  @override
  SourceFormat sampleRate(int? sampleRate) => this(sampleRate: sampleRate);

  @override
  SourceFormat channels(int? channels) => this(channels: channels);

  @override
  SourceFormat bitDepth(int? bitDepth) => this(bitDepth: bitDepth);

  @override
  SourceFormat bitrate(int? bitrate) => this(bitrate: bitrate);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SourceFormat(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SourceFormat(...).copyWith(id: 12, name: "My name")
  /// ````
  SourceFormat call({
    Object? container = const $CopyWithPlaceholder(),
    Object? codec = const $CopyWithPlaceholder(),
    Object? sampleRate = const $CopyWithPlaceholder(),
    Object? channels = const $CopyWithPlaceholder(),
    Object? bitDepth = const $CopyWithPlaceholder(),
    Object? bitrate = const $CopyWithPlaceholder(),
  }) {
    return SourceFormat(
      container: container == const $CopyWithPlaceholder()
          ? _value.container
          // ignore: cast_nullable_to_non_nullable
          : container as String,
      codec: codec == const $CopyWithPlaceholder()
          ? _value.codec
          // ignore: cast_nullable_to_non_nullable
          : codec as String,
      sampleRate: sampleRate == const $CopyWithPlaceholder()
          ? _value.sampleRate
          // ignore: cast_nullable_to_non_nullable
          : sampleRate as int?,
      channels: channels == const $CopyWithPlaceholder()
          ? _value.channels
          // ignore: cast_nullable_to_non_nullable
          : channels as int?,
      bitDepth: bitDepth == const $CopyWithPlaceholder()
          ? _value.bitDepth
          // ignore: cast_nullable_to_non_nullable
          : bitDepth as int?,
      bitrate: bitrate == const $CopyWithPlaceholder()
          ? _value.bitrate
          // ignore: cast_nullable_to_non_nullable
          : bitrate as int?,
    );
  }
}

extension $SourceFormatCopyWith on SourceFormat {
  /// Returns a callable class that can be used as follows: `instanceOfSourceFormat.copyWith(...)` or like so:`instanceOfSourceFormat.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SourceFormatCWProxy get copyWith => _$SourceFormatCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceFormat _$SourceFormatFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SourceFormat',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['container', 'codec']);
        final val = SourceFormat(
          container: $checkedConvert('container', (v) => v as String),
          codec: $checkedConvert('codec', (v) => v as String),
          sampleRate: $checkedConvert(
            'sample_rate',
            (v) => (v as num?)?.toInt(),
          ),
          channels: $checkedConvert('channels', (v) => (v as num?)?.toInt()),
          bitDepth: $checkedConvert('bit_depth', (v) => (v as num?)?.toInt()),
          bitrate: $checkedConvert('bitrate', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'sampleRate': 'sample_rate', 'bitDepth': 'bit_depth'},
    );

Map<String, dynamic> _$SourceFormatToJson(SourceFormat instance) =>
    <String, dynamic>{
      'container': instance.container,
      'codec': instance.codec,
      'sample_rate': ?instance.sampleRate,
      'channels': ?instance.channels,
      'bit_depth': ?instance.bitDepth,
      'bitrate': ?instance.bitrate,
    };
