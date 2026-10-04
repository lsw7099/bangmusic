//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/post_play_events200_response_rejected_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_play_events200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PostPlayEvents200Response {
  /// Returns a new [PostPlayEvents200Response] instance.
  PostPlayEvents200Response({

    required  this.accepted,

    required  this.duplicates,

    required  this.rejected,
  });

  @JsonKey(
    
    name: r'accepted',
    required: true,
    includeIfNull: false,
  )


  final int accepted;



  @JsonKey(
    
    name: r'duplicates',
    required: true,
    includeIfNull: false,
  )


  final int duplicates;



      /// 곡이 없거나 권한이 없어 버린 이벤트. 앱은 재전송하지 않는다.
  @JsonKey(
    
    name: r'rejected',
    required: true,
    includeIfNull: false,
  )


  final List<PostPlayEvents200ResponseRejectedInner> rejected;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PostPlayEvents200Response &&
      other.accepted == accepted &&
      other.duplicates == duplicates &&
      other.rejected == rejected;

    @override
    int get hashCode =>
        accepted.hashCode +
        duplicates.hashCode +
        rejected.hashCode;

  factory PostPlayEvents200Response.fromJson(Map<String, dynamic> json) => _$PostPlayEvents200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PostPlayEvents200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

