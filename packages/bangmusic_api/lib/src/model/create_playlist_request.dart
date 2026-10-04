//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_playlist_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatePlaylistRequest {
  /// Returns a new [CreatePlaylistRequest] instance.
  CreatePlaylistRequest({

    required  this.name,

     this.description,

     this.trackIds,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'track_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? trackIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatePlaylistRequest &&
      other.name == name &&
      other.description == description &&
      other.trackIds == trackIds;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        trackIds.hashCode;

  factory CreatePlaylistRequest.fromJson(Map<String, dynamic> json) => _$CreatePlaylistRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePlaylistRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

