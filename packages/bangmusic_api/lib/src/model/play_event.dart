//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/play_event_context.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'play_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlayEvent {
  /// Returns a new [PlayEvent] instance.
  PlayEvent({

    required  this.eventId,

    required  this.trackId,

    required  this.startedAt,

    required  this.playedMs,

    required  this.completed,

    required  this.source_,

     this.context,
  });

  @JsonKey(
    
    name: r'event_id',
    required: true,
    includeIfNull: false,
  )


  final String eventId;



  @JsonKey(
    
    name: r'track_id',
    required: true,
    includeIfNull: false,
  )


  final String trackId;



  @JsonKey(
    
    name: r'started_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime startedAt;



          // minimum: 0
  @JsonKey(
    
    name: r'played_ms',
    required: true,
    includeIfNull: false,
  )


  final int playedMs;



  @JsonKey(
    
    name: r'completed',
    required: true,
    includeIfNull: false,
  )


  final bool completed;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  unknownEnumValue: PlayEventSource_Enum.unknownDefaultOpenApi,
  )


  final PlayEventSource_Enum source_;



  @JsonKey(
    
    name: r'context',
    required: false,
    includeIfNull: false,
  )


  final PlayEventContext? context;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlayEvent &&
      other.eventId == eventId &&
      other.trackId == trackId &&
      other.startedAt == startedAt &&
      other.playedMs == playedMs &&
      other.completed == completed &&
      other.source_ == source_ &&
      other.context == context;

    @override
    int get hashCode =>
        eventId.hashCode +
        trackId.hashCode +
        startedAt.hashCode +
        playedMs.hashCode +
        completed.hashCode +
        source_.hashCode +
        context.hashCode;

  factory PlayEvent.fromJson(Map<String, dynamic> json) => _$PlayEventFromJson(json);

  Map<String, dynamic> toJson() => _$PlayEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PlayEventSource_Enum {
@JsonValue(r'stream')
stream(r'stream'),
@JsonValue(r'offline')
offline(r'offline'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const PlayEventSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


