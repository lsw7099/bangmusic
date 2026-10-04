//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lyrics_variant_source.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LyricsVariantSource {
  /// Returns a new [LyricsVariantSource] instance.
  LyricsVariantSource({

    required  this.type,

     this.name,

     this.licenseNote,
  });

      /// `generated`는 서버가 오프라인으로 만든 값(현재는 한글 발음, 05장 §8.4). 사람이 확인하지 않았으므로 앱은 출처를 함께 보인다.
  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  unknownEnumValue: LyricsVariantSourceTypeEnum.unknownDefaultOpenApi,
  )


  final LyricsVariantSourceTypeEnum type;



  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'license_note',
    required: false,
    includeIfNull: false,
  )


  final String? licenseNote;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LyricsVariantSource &&
      other.type == type &&
      other.name == name &&
      other.licenseNote == licenseNote;

    @override
    int get hashCode =>
        type.hashCode +
        (name == null ? 0 : name.hashCode) +
        (licenseNote == null ? 0 : licenseNote.hashCode);

  factory LyricsVariantSource.fromJson(Map<String, dynamic> json) => _$LyricsVariantSourceFromJson(json);

  Map<String, dynamic> toJson() => _$LyricsVariantSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// `generated`는 서버가 오프라인으로 만든 값(현재는 한글 발음, 05장 §8.4). 사람이 확인하지 않았으므로 앱은 출처를 함께 보인다.
enum LyricsVariantSourceTypeEnum {
@JsonValue(r'sidecar')
sidecar(r'sidecar'),
@JsonValue(r'embedded')
embedded(r'embedded'),
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'provider')
provider(r'provider'),
@JsonValue(r'generated')
generated(r'generated'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const LyricsVariantSourceTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


