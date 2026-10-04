//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me_all_of_libraries.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeAllOfLibraries {
  /// Returns a new [MeAllOfLibraries] instance.
  MeAllOfLibraries({

    required  this.id,

    required  this.name,

    required  this.status,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: MeAllOfLibrariesStatusEnum.unknownDefaultOpenApi,
  )


  final MeAllOfLibrariesStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MeAllOfLibraries &&
      other.id == id &&
      other.name == name &&
      other.status == status;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        status.hashCode;

  factory MeAllOfLibraries.fromJson(Map<String, dynamic> json) => _$MeAllOfLibrariesFromJson(json);

  Map<String, dynamic> toJson() => _$MeAllOfLibrariesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum MeAllOfLibrariesStatusEnum {
@JsonValue(r'online')
online(r'online'),
@JsonValue(r'unavailable')
unavailable(r'unavailable'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const MeAllOfLibrariesStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


