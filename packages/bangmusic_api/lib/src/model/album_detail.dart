//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/artist_ref.dart';
import 'package:bangmusic_api/src/model/track.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album_detail.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlbumDetail {
  /// Returns a new [AlbumDetail] instance.
  AlbumDetail({

    required  this.id,

    required  this.title,

     this.albumArtist,

     this.year,

     this.artworkId,

    required  this.trackCount,

     this.durationMs,

    required  this.tracks,
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



  @JsonKey(
    
    name: r'tracks',
    required: true,
    includeIfNull: false,
  )


  final List<Track> tracks;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlbumDetail &&
      other.id == id &&
      other.title == title &&
      other.albumArtist == albumArtist &&
      other.year == year &&
      other.artworkId == artworkId &&
      other.trackCount == trackCount &&
      other.durationMs == durationMs &&
      other.tracks == tracks;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        albumArtist.hashCode +
        year.hashCode +
        artworkId.hashCode +
        trackCount.hashCode +
        durationMs.hashCode +
        tracks.hashCode;

  factory AlbumDetail.fromJson(Map<String, dynamic> json) => _$AlbumDetailFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

