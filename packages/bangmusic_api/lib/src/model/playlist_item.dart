//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/track.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistItem {
  /// Returns a new [PlaylistItem] instance.
  PlaylistItem({

    required  this.itemId,

    required  this.available,

     this.track,

     this.addedAt,
  });

  @JsonKey(
    
    name: r'item_id',
    required: true,
    includeIfNull: false,
  )


  final String itemId;



      /// false면 곡이 누락되었거나 접근 권한이 없어 `track`이 없다.
  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'track',
    required: false,
    includeIfNull: false,
  )


  final Track? track;



  @JsonKey(
    
    name: r'added_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? addedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistItem &&
      other.itemId == itemId &&
      other.available == available &&
      other.track == track &&
      other.addedAt == addedAt;

    @override
    int get hashCode =>
        itemId.hashCode +
        available.hashCode +
        track.hashCode +
        addedAt.hashCode;

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => _$PlaylistItemFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

