//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/artist_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Album {
  /// Returns a new [Album] instance.
  Album({

    required  this.id,

    required  this.title,

     this.albumArtist,

     this.year,

     this.artworkId,

    required  this.trackCount,

     this.durationMs,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'album_artist',
    required: false,
    includeIfNull: false,
  )


  final ArtistRef? albumArtist;



  @JsonKey(
    
    name: r'year',
    required: false,
    includeIfNull: false,
  )


  final int? year;



  @JsonKey(
    
    name: r'artwork_id',
    required: false,
    includeIfNull: false,
  )


  final String? artworkId;



  @JsonKey(
    
    name: r'track_count',
    required: true,
    includeIfNull: false,
  )


  final int trackCount;



  @JsonKey(
    
    name: r'duration_ms',
    required: false,
    includeIfNull: false,
  )


  final int? durationMs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Album &&
      other.id == id &&
      other.title == title &&
      other.albumArtist == albumArtist &&
      other.year == year &&
      other.artworkId == artworkId &&
      other.trackCount == trackCount &&
      other.durationMs == durationMs;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        (albumArtist == null ? 0 : albumArtist.hashCode) +
        (year == null ? 0 : year.hashCode) +
        (artworkId == null ? 0 : artworkId.hashCode) +
        trackCount.hashCode +
        durationMs.hashCode;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

