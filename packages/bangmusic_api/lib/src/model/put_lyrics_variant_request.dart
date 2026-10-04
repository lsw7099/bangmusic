//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'put_lyrics_variant_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PutLyricsVariantRequest {
  /// Returns a new [PutLyricsVariantRequest] instance.
  PutLyricsVariantRequest({

    required  this.format,

     this.language,

    required  this.body,

     this.sourceName,

     this.licenseNote,
  });

  @JsonKey(
    
    name: r'format',
    required: true,
    includeIfNull: false,
  unknownEnumValue: PutLyricsVariantRequestFormatEnum.unknownDefaultOpenApi,
  )


  final PutLyricsVariantRequestFormatEnum format;



  @JsonKey(
    
    name: r'language',
    required: false,
    includeIfNull: false,
  )


  final String? language;



  @JsonKey(
    
    name: r'body',
    required: true,
    includeIfNull: false,
  )


  final String body;



  @JsonKey(
    
    name: r'source_name',
    required: false,
    includeIfNull: false,
  )


  final String? sourceName;



  @JsonKey(
    
    name: r'license_note',
    required: false,
    includeIfNull: false,
  )


  final String? licenseNote;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PutLyricsVariantRequest &&
      other.format == format &&
      other.language == language &&
      other.body == body &&
      other.sourceName == sourceName &&
      other.licenseNote == licenseNote;

    @override
    int get hashCode =>
        format.hashCode +
        language.hashCode +
        body.hashCode +
        sourceName.hashCode +
        licenseNote.hashCode;

  factory PutLyricsVariantRequest.fromJson(Map<String, dynamic> json) => _$PutLyricsVariantRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PutLyricsVariantRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PutLyricsVariantRequestFormatEnum {
@JsonValue(r'lrc')
lrc(r'lrc'),
@JsonValue(r'plain')
plain(r'plain'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const PutLyricsVariantRequestFormatEnum(this.value);

final String value;

@override
String toString() => value;
}


