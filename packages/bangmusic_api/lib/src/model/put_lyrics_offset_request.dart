//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'put_lyrics_offset_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PutLyricsOffsetRequest {
  /// Returns a new [PutLyricsOffsetRequest] instance.
  PutLyricsOffsetRequest({

    required  this.offsetMs,
  });

          // minimum: -10000
          // maximum: 10000
  @JsonKey(
    
    name: r'offset_ms',
    required: true,
    includeIfNull: false,
  )


  final int offsetMs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PutLyricsOffsetRequest &&
      other.offsetMs == offsetMs;

    @override
    int get hashCode =>
        offsetMs.hashCode;

  factory PutLyricsOffsetRequest.fromJson(Map<String, dynamic> json) => _$PutLyricsOffsetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PutLyricsOffsetRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

