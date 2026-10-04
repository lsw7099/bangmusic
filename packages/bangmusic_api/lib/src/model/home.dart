//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/album.dart';
import 'package:bangmusic_api/src/model/track.dart';
import 'package:bangmusic_api/src/model/playlist.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Home {
  /// Returns a new [Home] instance.
  Home({

    required  this.playlists,

    required  this.recentTracks,

    required  this.topTracks,

    required  this.recentlyAddedAlbums,
  });

  @JsonKey(
    
    name: r'playlists',
    required: true,
    includeIfNull: false,
  )


  final List<Playlist> playlists;



  @JsonKey(
    
    name: r'recent_tracks',
    required: true,
    includeIfNull: false,
  )


  final List<Track> recentTracks;



  @JsonKey(
    
    name: r'top_tracks',
    required: true,
    includeIfNull: false,
  )


  final List<Track> topTracks;



  @JsonKey(
    
    name: r'recently_added_albums',
    required: true,
    includeIfNull: false,
  )


  final List<Album> recentlyAddedAlbums;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Home &&
      other.playlists == playlists &&
      other.recentTracks == recentTracks &&
      other.topTracks == topTracks &&
      other.recentlyAddedAlbums == recentlyAddedAlbums;

    @override
    int get hashCode =>
        playlists.hashCode +
        recentTracks.hashCode +
        topTracks.hashCode +
        recentlyAddedAlbums.hashCode;

  factory Home.fromJson(Map<String, dynamic> json) => _$HomeFromJson(json);

  Map<String, dynamic> toJson() => _$HomeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

