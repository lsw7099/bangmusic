//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/format_spec.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rendition_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RenditionRequest {
  /// Returns a new [RenditionRequest] instance.
  RenditionRequest({

    required  this.purpose,

    required  this.quality,

    required  this.accept,
  });

  @JsonKey(
    
    name: r'purpose',
    required: true,
    includeIfNull: false,
  unknownEnumValue: RenditionRequestPurposeEnum.unknownDefaultOpenApi,
  )


  final RenditionRequestPurposeEnum purpose;



      /// `original`은 가능하면 원본. 그 외는 `transcode_profiles` 중 하나이며 원본 비트레이트가 더 낮으면 원본을 준다.
  @JsonKey(
    
    name: r'quality',
    required: true,
    includeIfNull: false,
  )


  final String quality;



      /// 이 기기가 재생할 수 있는 형식. 원본이 여기에 없으면 서버가 변환한다.
  @JsonKey(
    
    name: r'accept',
    required: true,
    includeIfNull: false,
  )


  final List<FormatSpec> accept;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RenditionRequest &&
      other.purpose == purpose &&
      other.quality == quality &&
      other.accept == accept;

    @override
    int get hashCode =>
        purpose.hashCode +
        quality.hashCode +
        accept.hashCode;

  factory RenditionRequest.fromJson(Map<String, dynamic> json) => _$RenditionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RenditionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum RenditionRequestPurposeEnum {
@JsonValue(r'stream')
stream(r'stream'),
@JsonValue(r'download')
download(r'download'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const RenditionRequestPurposeEnum(this.value);

final String value;

@override
String toString() => value;
}


