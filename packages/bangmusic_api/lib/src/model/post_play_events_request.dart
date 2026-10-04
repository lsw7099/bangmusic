//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/play_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_play_events_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PostPlayEventsRequest {
  /// Returns a new [PostPlayEventsRequest] instance.
  PostPlayEventsRequest({

    required  this.events,
  });

  @JsonKey(
    
    name: r'events',
    required: true,
    includeIfNull: false,
  )


  final List<PlayEvent> events;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PostPlayEventsRequest &&
      other.events == events;

    @override
    int get hashCode =>
        events.hashCode;

  factory PostPlayEventsRequest.fromJson(Map<String, dynamic> json) => _$PostPlayEventsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PostPlayEventsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

