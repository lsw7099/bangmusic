//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'format_spec.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FormatSpec {
  /// Returns a new [FormatSpec] instance.
  FormatSpec({

    required  this.container,

    required  this.codec,

     this.maxSampleRate,

     this.maxBitDepth,
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
    
    name: r'max_sample_rate',
    required: false,
    includeIfNull: false,
  )


  final int? maxSampleRate;



  @JsonKey(
    
    name: r'max_bit_depth',
    required: false,
    includeIfNull: false,
  )


  final int? maxBitDepth;





    @override
    bool operator ==(Object other) => identical(this, other) || other is FormatSpec &&
      other.container == container &&
      other.codec == codec &&
      other.maxSampleRate == maxSampleRate &&
      other.maxBitDepth == maxBitDepth;

    @override
    int get hashCode =>
        container.hashCode +
        codec.hashCode +
        maxSampleRate.hashCode +
        maxBitDepth.hashCode;

  factory FormatSpec.fromJson(Map<String, dynamic> json) => _$FormatSpecFromJson(json);

  Map<String, dynamic> toJson() => _$FormatSpecToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

