//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/admin_user.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_list_users200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminListUsers200Response {
  /// Returns a new [AdminListUsers200Response] instance.
  AdminListUsers200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminUser> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminListUsers200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminListUsers200Response.fromJson(Map<String, dynamic> json) => _$AdminListUsers200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminListUsers200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

