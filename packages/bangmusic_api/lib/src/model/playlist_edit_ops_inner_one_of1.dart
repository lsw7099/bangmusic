//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_edit_ops_inner_one_of1.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistEditOpsInnerOneOf1 {
  /// Returns a new [PlaylistEditOpsInnerOneOf1] instance.
  PlaylistEditOpsInnerOneOf1({

    required  this.op,

    required  this.itemIds,
  });

  @JsonKey(
    
    name: r'op',
    required: true,
    includeIfNull: true,
  )


  final Object? op;



  @JsonKey(
    
    name: r'item_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> itemIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistEditOpsInnerOneOf1 &&
      other.op == op &&
      other.itemIds == itemIds;

    @override
    int get hashCode =>
        (op == null ? 0 : op.hashCode) +
        itemIds.hashCode;

  factory PlaylistEditOpsInnerOneOf1.fromJson(Map<String, dynamic> json) => _$PlaylistEditOpsInnerOneOf1FromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistEditOpsInnerOneOf1ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

