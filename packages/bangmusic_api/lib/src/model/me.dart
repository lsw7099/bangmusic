//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/me_all_of_libraries.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Me {
  /// Returns a new [Me] instance.
  Me({

    required  this.id,

    required  this.username,

     this.displayName,

    required  this.role,

    required  this.libraries,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'username',
    required: true,
    includeIfNull: false,
  )


  final String username;



  @JsonKey(
    
    name: r'display_name',
    required: false,
    includeIfNull: false,
  )


  final String? displayName;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  unknownEnumValue: MeRoleEnum.unknownDefaultOpenApi,
  )


  final MeRoleEnum role;



  @JsonKey(
    
    name: r'libraries',
    required: true,
    includeIfNull: false,
  )


  final List<MeAllOfLibraries> libraries;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Me &&
      other.id == id &&
      other.username == username &&
      other.displayName == displayName &&
      other.role == role &&
      other.libraries == libraries;

    @override
    int get hashCode =>
        id.hashCode +
        username.hashCode +
        displayName.hashCode +
        role.hashCode +
        libraries.hashCode;

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  Map<String, dynamic> toJson() => _$MeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum MeRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const MeRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


