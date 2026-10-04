//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_play_events200_response_rejected_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PostPlayEvents200ResponseRejectedInner {
  /// Returns a new [PostPlayEvents200ResponseRejectedInner] instance.
  PostPlayEvents200ResponseRejectedInner({

    required  this.eventId,

    required  this.code,
  });

  @JsonKey(
    
    name: r'event_id',
    required: true,
    includeIfNull: false,
  )


  final String eventId;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PostPlayEvents200ResponseRejectedInner &&
      other.eventId == eventId &&
      other.code == code;

    @override
    int get hashCode =>
        eventId.hashCode +
        code.hashCode;

  factory PostPlayEvents200ResponseRejectedInner.fromJson(Map<String, dynamic> json) => _$PostPlayEvents200ResponseRejectedInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PostPlayEvents200ResponseRejectedInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

