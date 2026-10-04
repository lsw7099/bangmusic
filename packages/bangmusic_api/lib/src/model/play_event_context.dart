//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'play_event_context.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlayEventContext {
  /// Returns a new [PlayEventContext] instance.
  PlayEventContext({

     this.type,

     this.id,
  });

  @JsonKey(
    
    name: r'type',
    required: false,
    includeIfNull: false,
  unknownEnumValue: PlayEventContextTypeEnum.unknownDefaultOpenApi,
  )


  final PlayEventContextTypeEnum? type;



  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false,
  )


  final String? id;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlayEventContext &&
      other.type == type &&
      other.id == id;

    @override
    int get hashCode =>
        type.hashCode +
        (id == null ? 0 : id.hashCode);

  factory PlayEventContext.fromJson(Map<String, dynamic> json) => _$PlayEventContextFromJson(json);

  Map<String, dynamic> toJson() => _$PlayEventContextToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PlayEventContextTypeEnum {
@JsonValue(r'album')
album(r'album'),
@JsonValue(r'playlist')
playlist(r'playlist'),
@JsonValue(r'artist')
artist(r'artist'),
@JsonValue(r'search')
search(r'search'),
@JsonValue(r'library')
library_(r'library'),
@JsonValue(r'queue')
queue(r'queue'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const PlayEventContextTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


