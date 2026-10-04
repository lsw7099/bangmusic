//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delete_me_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeleteMeRequest {
  /// Returns a new [DeleteMeRequest] instance.
  DeleteMeRequest({

    required  this.password,
  });

  @JsonKey(
    
    name: r'password',
    required: true,
    includeIfNull: false,
  )


  final String password;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeleteMeRequest &&
      other.password == password;

    @override
    int get hashCode =>
        password.hashCode;

  factory DeleteMeRequest.fromJson(Map<String, dynamic> json) => _$DeleteMeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteMeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

