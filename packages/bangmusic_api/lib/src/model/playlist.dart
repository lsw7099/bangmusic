//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Playlist {
  /// Returns a new [Playlist] instance.
  Playlist({

    required  this.id,

    required  this.name,

     this.description,

     this.artworkId,

     this.mosaicArtworkIds,

    required  this.version,

    required  this.itemCount,

    required  this.durationMs,

     this.createdAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



      /// 업로드한 표지. null이면 앱이 `mosaic_artwork_ids`로 모자이크를 만든다.
  @JsonKey(
    
    name: r'artwork_id',
    required: false,
    includeIfNull: false,
  )


  final String? artworkId;



  @JsonKey(
    
    name: r'mosaic_artwork_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? mosaicArtworkIds;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'item_count',
    required: true,
    includeIfNull: false,
  )


  final int itemCount;



  @JsonKey(
    
    name: r'duration_ms',
    required: true,
    includeIfNull: false,
  )


  final int durationMs;



  @JsonKey(
    
    name: r'created_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? createdAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Playlist &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.artworkId == artworkId &&
      other.mosaicArtworkIds == mosaicArtworkIds &&
      other.version == version &&
      other.itemCount == itemCount &&
      other.durationMs == durationMs &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        (description == null ? 0 : description.hashCode) +
        (artworkId == null ? 0 : artworkId.hashCode) +
        mosaicArtworkIds.hashCode +
        version.hashCode +
        itemCount.hashCode +
        durationMs.hashCode +
        createdAt.hashCode +
        updatedAt.hashCode;

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

