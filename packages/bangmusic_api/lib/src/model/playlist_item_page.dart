//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/playlist_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_item_page.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistItemPage {
  /// Returns a new [PlaylistItemPage] instance.
  PlaylistItemPage({

    required  this.items,

    required  this.nextCursor,

    required  this.version,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PlaylistItem> items;



  @JsonKey(
    
    name: r'next_cursor',
    required: true,
    includeIfNull: true,
  )


  final String? nextCursor;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistItemPage &&
      other.items == items &&
      other.nextCursor == nextCursor &&
      other.version == version;

    @override
    int get hashCode =>
        items.hashCode +
        (nextCursor == null ? 0 : nextCursor.hashCode) +
        version.hashCode;

  factory PlaylistItemPage.fromJson(Map<String, dynamic> json) => _$PlaylistItemPageFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistItemPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

