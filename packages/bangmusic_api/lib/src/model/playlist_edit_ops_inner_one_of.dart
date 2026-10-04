//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_edit_ops_inner_one_of.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistEditOpsInnerOneOf {
  /// Returns a new [PlaylistEditOpsInnerOneOf] instance.
  PlaylistEditOpsInnerOneOf({

    required  this.op,

    required  this.trackIds,

     this.afterItemId,
  });

  @JsonKey(
    
    name: r'op',
    required: true,
    includeIfNull: true,
  )


  final Object? op;



  @JsonKey(
    
    name: r'track_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> trackIds;



      /// null이면 맨 앞. 생략하면 맨 뒤.
  @JsonKey(
    
    name: r'after_item_id',
    required: false,
    includeIfNull: false,
  )


  final String? afterItemId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistEditOpsInnerOneOf &&
      other.op == op &&
      other.trackIds == trackIds &&
      other.afterItemId == afterItemId;

    @override
    int get hashCode =>
        (op == null ? 0 : op.hashCode) +
        trackIds.hashCode +
        (afterItemId == null ? 0 : afterItemId.hashCode);

  factory PlaylistEditOpsInnerOneOf.fromJson(Map<String, dynamic> json) => _$PlaylistEditOpsInnerOneOfFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistEditOpsInnerOneOfToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

