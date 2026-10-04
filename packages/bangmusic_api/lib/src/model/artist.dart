//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'artist.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Artist {
  /// Returns a new [Artist] instance.
  Artist({

    required  this.id,

    required  this.name,

     this.nameSort,

     this.albumCount,

     this.trackCount,

     this.artworkId,
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
    
    name: r'name_sort',
    required: false,
    includeIfNull: false,
  )


  final String? nameSort;



  @JsonKey(
    
    name: r'album_count',
    required: false,
    includeIfNull: false,
  )


  final int? albumCount;



  @JsonKey(
    
    name: r'track_count',
    required: false,
    includeIfNull: false,
  )


  final int? trackCount;



  @JsonKey(
    
    name: r'artwork_id',
    required: false,
    includeIfNull: false,
  )


  final String? artworkId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Artist &&
      other.id == id &&
      other.name == name &&
      other.nameSort == nameSort &&
      other.albumCount == albumCount &&
      other.trackCount == trackCount &&
      other.artworkId == artworkId;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        (nameSort == null ? 0 : nameSort.hashCode) +
        albumCount.hashCode +
        trackCount.hashCode +
        (artworkId == null ? 0 : artworkId.hashCode);

  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);

  Map<String, dynamic> toJson() => _$ArtistToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

