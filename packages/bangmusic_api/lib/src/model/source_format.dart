//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'source_format.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SourceFormat {
  /// Returns a new [SourceFormat] instance.
  SourceFormat({

    required  this.container,

    required  this.codec,

     this.sampleRate,

     this.channels,

     this.bitDepth,

     this.bitrate,
  });

  @JsonKey(
    
    name: r'container',
    required: true,
    includeIfNull: false,
  )


  final String container;



  @JsonKey(
    
    name: r'codec',
    required: true,
    includeIfNull: false,
  )


  final String codec;



  @JsonKey(
    
    name: r'sample_rate',
    required: false,
    includeIfNull: false,
  )


  final int? sampleRate;



  @JsonKey(
    
    name: r'channels',
    required: false,
    includeIfNull: false,
  )


  final int? channels;



  @JsonKey(
    
    name: r'bit_depth',
    required: false,
    includeIfNull: false,
  )


  final int? bitDepth;



  @JsonKey(
    
    name: r'bitrate',
    required: false,
    includeIfNull: false,
  )


  final int? bitrate;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SourceFormat &&
      other.container == container &&
      other.codec == codec &&
      other.sampleRate == sampleRate &&
      other.channels == channels &&
      other.bitDepth == bitDepth &&
      other.bitrate == bitrate;

    @override
    int get hashCode =>
        container.hashCode +
        codec.hashCode +
        sampleRate.hashCode +
        channels.hashCode +
        (bitDepth == null ? 0 : bitDepth.hashCode) +
        (bitrate == null ? 0 : bitrate.hashCode);

  factory SourceFormat.fromJson(Map<String, dynamic> json) => _$SourceFormatFromJson(json);

  Map<String, dynamic> toJson() => _$SourceFormatToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

