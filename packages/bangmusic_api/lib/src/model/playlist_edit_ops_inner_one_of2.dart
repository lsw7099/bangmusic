//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_edit_ops_inner_one_of2.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistEditOpsInnerOneOf2 {
  /// Returns a new [PlaylistEditOpsInnerOneOf2] instance.
  PlaylistEditOpsInnerOneOf2({

    required  this.op,

    required  this.itemId,

    required  this.afterItemId,
  });

  @JsonKey(
    
    name: r'op',
    required: true,
    includeIfNull: true,
  )


  final Object? op;



  @JsonKey(
    
    name: r'item_id',
    required: true,
    includeIfNull: false,
  )


  final String itemId;



  @JsonKey(
    
    name: r'after_item_id',
    required: true,
    includeIfNull: true,
  )


  final String? afterItemId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistEditOpsInnerOneOf2 &&
      other.op == op &&
      other.itemId == itemId &&
      other.afterItemId == afterItemId;

    @override
    int get hashCode =>
        (op == null ? 0 : op.hashCode) +
        itemId.hashCode +
        (afterItemId == null ? 0 : afterItemId.hashCode);

  factory PlaylistEditOpsInnerOneOf2.fromJson(Map<String, dynamic> json) => _$PlaylistEditOpsInnerOneOf2FromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistEditOpsInnerOneOf2ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

