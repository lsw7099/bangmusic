//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/playlist_page.dart';
import 'package:bangmusic_api/src/model/album_page.dart';
import 'package:bangmusic_api/src/model/track_page.dart';
import 'package:bangmusic_api/src/model/artist_page.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchResult {
  /// Returns a new [SearchResult] instance.
  SearchResult({

    required  this.queryNormalized,

     this.tracks,

     this.albums,

     this.artists,

     this.playlists,
  });

  @JsonKey(
    
    name: r'query_normalized',
    required: true,
    includeIfNull: false,
  )


  final String queryNormalized;



  @JsonKey(
    
    name: r'tracks',
    required: false,
    includeIfNull: false,
  )


  final TrackPage? tracks;



  @JsonKey(
    
    name: r'albums',
    required: false,
    includeIfNull: false,
  )


  final AlbumPage? albums;



  @JsonKey(
    
    name: r'artists',
    required: false,
    includeIfNull: false,
  )


  final ArtistPage? artists;



  @JsonKey(
    
    name: r'playlists',
    required: false,
    includeIfNull: false,
  )


  final PlaylistPage? playlists;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SearchResult &&
      other.queryNormalized == queryNormalized &&
      other.tracks == tracks &&
      other.albums == albums &&
      other.artists == artists &&
      other.playlists == playlists;

    @override
    int get hashCode =>
        queryNormalized.hashCode +
        tracks.hashCode +
        albums.hashCode +
        artists.hashCode +
        playlists.hashCode;

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

