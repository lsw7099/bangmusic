//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_update_user_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUpdateUserRequest {
  /// Returns a new [AdminUpdateUserRequest] instance.
  AdminUpdateUserRequest({

     this.displayName,

     this.role,

     this.status,

     this.libraryIds,

     this.newPassword,

     this.revokeSessions,
  });

  @JsonKey(
    
    name: r'display_name',
    required: false,
    includeIfNull: false,
  )


  final String? displayName;



  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  unknownEnumValue: AdminUpdateUserRequestRoleEnum.unknownDefaultOpenApi,
  )


  final AdminUpdateUserRequestRoleEnum? role;



  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  unknownEnumValue: AdminUpdateUserRequestStatusEnum.unknownDefaultOpenApi,
  )


  final AdminUpdateUserRequestStatusEnum? status;



  @JsonKey(
    
    name: r'library_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? libraryIds;



  @JsonKey(
    
    name: r'new_password',
    required: false,
    includeIfNull: false,
  )


  final String? newPassword;



  @JsonKey(
    
    name: r'revoke_sessions',
    required: false,
    includeIfNull: false,
  )


  final bool? revokeSessions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminUpdateUserRequest &&
      other.displayName == displayName &&
      other.role == role &&
      other.status == status &&
      other.libraryIds == libraryIds &&
      other.newPassword == newPassword &&
      other.revokeSessions == revokeSessions;

    @override
    int get hashCode =>
        displayName.hashCode +
        role.hashCode +
        status.hashCode +
        libraryIds.hashCode +
        newPassword.hashCode +
        revokeSessions.hashCode;

  factory AdminUpdateUserRequest.fromJson(Map<String, dynamic> json) => _$AdminUpdateUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUpdateUserRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminUpdateUserRequestRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const AdminUpdateUserRequestRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


enum AdminUpdateUserRequestStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'disabled')
disabled(r'disabled'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const AdminUpdateUserRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


