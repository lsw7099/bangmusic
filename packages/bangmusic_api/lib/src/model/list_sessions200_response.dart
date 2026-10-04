//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/session.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_sessions200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListSessions200Response {
  /// Returns a new [ListSessions200Response] instance.
  ListSessions200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Session> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListSessions200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListSessions200Response.fromJson(Map<String, dynamic> json) => _$ListSessions200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListSessions200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

