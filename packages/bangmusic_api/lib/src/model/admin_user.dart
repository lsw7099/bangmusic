//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_user.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminUser {
  /// Returns a new [AdminUser] instance.
  AdminUser({

    required  this.id,

    required  this.username,

     this.displayName,

    required  this.role,

    required  this.status,

    required  this.libraryIds,

    required  this.createdAt,

     this.sessionCount,
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
  unknownEnumValue: AdminUserRoleEnum.unknownDefaultOpenApi,
  )


  final AdminUserRoleEnum role;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AdminUserStatusEnum.unknownDefaultOpenApi,
  )


  final AdminUserStatusEnum status;



  @JsonKey(
    
    name: r'library_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> libraryIds;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'session_count',
    required: false,
    includeIfNull: false,
  )


  final int? sessionCount;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminUser &&
      other.id == id &&
      other.username == username &&
      other.displayName == displayName &&
      other.role == role &&
      other.status == status &&
      other.libraryIds == libraryIds &&
      other.createdAt == createdAt &&
      other.sessionCount == sessionCount;

    @override
    int get hashCode =>
        id.hashCode +
        username.hashCode +
        displayName.hashCode +
        role.hashCode +
        status.hashCode +
        libraryIds.hashCode +
        createdAt.hashCode +
        sessionCount.hashCode;

  factory AdminUser.fromJson(Map<String, dynamic> json) => _$AdminUserFromJson(json);

  Map<String, dynamic> toJson() => _$AdminUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminUserRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const AdminUserRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


enum AdminUserStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'disabled')
disabled(r'disabled'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const AdminUserStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


