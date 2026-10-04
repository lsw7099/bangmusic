//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/admin_library.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_list_libraries200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminListLibraries200Response {
  /// Returns a new [AdminListLibraries200Response] instance.
  AdminListLibraries200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminLibrary> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminListLibraries200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminListLibraries200Response.fromJson(Map<String, dynamic> json) => _$AdminListLibraries200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminListLibraries200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

