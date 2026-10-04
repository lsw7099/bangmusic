//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner_one_of1.dart';
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner_one_of2.dart';
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner_one_of.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_edit_ops_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistEditOpsInner {
  /// Returns a new [PlaylistEditOpsInner] instance.
  PlaylistEditOpsInner({

    required  this.op,

    required  this.trackIds,

    required  this.afterItemId,

    required  this.itemIds,

    required  this.itemId,
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



  @JsonKey(
    
    name: r'after_item_id',
    required: true,
    includeIfNull: false,
  )


  final String afterItemId;



  @JsonKey(
    
    name: r'item_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> itemIds;



  @JsonKey(
    
    name: r'item_id',
    required: true,
    includeIfNull: false,
  )


  final String itemId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistEditOpsInner &&
      other.op == op &&
      other.trackIds == trackIds &&
      other.afterItemId == afterItemId &&
      other.itemIds == itemIds &&
      other.itemId == itemId;

    @override
    int get hashCode =>
        (op == null ? 0 : op.hashCode) +
        trackIds.hashCode +
        afterItemId.hashCode +
        itemIds.hashCode +
        itemId.hashCode;

  factory PlaylistEditOpsInner.fromJson(Map<String, dynamic> json) => _$PlaylistEditOpsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistEditOpsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

