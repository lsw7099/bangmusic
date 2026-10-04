//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_summary.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserSummary {
  /// Returns a new [UserSummary] instance.
  UserSummary({

    required  this.id,

    required  this.username,

     this.displayName,

    required  this.role,
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
  unknownEnumValue: UserSummaryRoleEnum.unknownDefaultOpenApi,
  )


  final UserSummaryRoleEnum role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UserSummary &&
      other.id == id &&
      other.username == username &&
      other.displayName == displayName &&
      other.role == role;

    @override
    int get hashCode =>
        id.hashCode +
        username.hashCode +
        displayName.hashCode +
        role.hashCode;

  factory UserSummary.fromJson(Map<String, dynamic> json) => _$UserSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$UserSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum UserSummaryRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const UserSummaryRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


