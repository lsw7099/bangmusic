//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_create_user_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCreateUserRequest {
  /// Returns a new [AdminCreateUserRequest] instance.
  AdminCreateUserRequest({

    required  this.username,

     this.displayName,

    required  this.password,

    required  this.role,

     this.libraryIds,
  });

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
    
    name: r'password',
    required: true,
    includeIfNull: false,
  )


  final String password;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AdminCreateUserRequestRoleEnum.unknownDefaultOpenApi,
  )


  final AdminCreateUserRequestRoleEnum role;



  @JsonKey(
    
    name: r'library_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? libraryIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminCreateUserRequest &&
      other.username == username &&
      other.displayName == displayName &&
      other.password == password &&
      other.role == role &&
      other.libraryIds == libraryIds;

    @override
    int get hashCode =>
        username.hashCode +
        displayName.hashCode +
        password.hashCode +
        role.hashCode +
        libraryIds.hashCode;

  factory AdminCreateUserRequest.fromJson(Map<String, dynamic> json) => _$AdminCreateUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCreateUserRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminCreateUserRequestRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const AdminCreateUserRequestRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


