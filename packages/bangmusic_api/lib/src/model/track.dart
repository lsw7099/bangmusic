//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/source_format.dart';
import 'package:bangmusic_api/src/model/artist_ref.dart';
import 'package:bangmusic_api/src/model/lyrics_kind.dart';
import 'package:bangmusic_api/src/model/album_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'track.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Track {
  /// Returns a new [Track] instance.
  Track({

    required  this.id,

    required  this.title,

     this.titleSort,

    required  this.artists,

     this.album,

     this.discNo,

     this.trackNo,

    required  this.durationMs,

     this.year,

     this.genre,

     this.artworkId,

    required  this.mediaVersion,

     this.sourceFormat,

    required  this.state,

     this.hasLyrics,

    required  this.updatedAt,
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
    
    name: r'title_sort',
    required: false,
    includeIfNull: false,
  )


  final String? titleSort;



  @JsonKey(
    
    name: r'artists',
    required: true,
    includeIfNull: false,
  )


  final List<ArtistRef> artists;



  @JsonKey(
    
    name: r'album',
    required: false,
    includeIfNull: false,
  )


  final AlbumRef? album;



  @JsonKey(
    
    name: r'disc_no',
    required: false,
    includeIfNull: false,
  )


  final int? discNo;



  @JsonKey(
    
    name: r'track_no',
    required: false,
    includeIfNull: false,
  )


  final int? trackNo;



  @JsonKey(
    
    name: r'duration_ms',
    required: true,
    includeIfNull: false,
  )


  final int durationMs;



  @JsonKey(
    
    name: r'year',
    required: false,
    includeIfNull: false,
  )


  final int? year;



  @JsonKey(
    
    name: r'genre',
    required: false,
    includeIfNull: false,
  )


  final String? genre;



  @JsonKey(
    
    name: r'artwork_id',
    required: false,
    includeIfNull: false,
  )


  final String? artworkId;



      /// 원본 바이트가 바뀌면 바뀌는 값. 다운로드본이 낡았는지 판단하는 기준.
  @JsonKey(
    
    name: r'media_version',
    required: true,
    includeIfNull: false,
  )


  final String mediaVersion;



  @JsonKey(
    
    name: r'source_format',
    required: false,
    includeIfNull: false,
  )


  final SourceFormat? sourceFormat;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  unknownEnumValue: TrackStateEnum.unknownDefaultOpenApi,
  )


  final TrackStateEnum state;



  @JsonKey(
    
    name: r'has_lyrics',
    required: false,
    includeIfNull: false,
  )


  final List<LyricsKind>? hasLyrics;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Track &&
      other.id == id &&
      other.title == title &&
      other.titleSort == titleSort &&
      other.artists == artists &&
      other.album == album &&
      other.discNo == discNo &&
      other.trackNo == trackNo &&
      other.durationMs == durationMs &&
      other.year == year &&
      other.genre == genre &&
      other.artworkId == artworkId &&
      other.mediaVersion == mediaVersion &&
      other.sourceFormat == sourceFormat &&
      other.state == state &&
      other.hasLyrics == hasLyrics &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        (titleSort == null ? 0 : titleSort.hashCode) +
        artists.hashCode +
        (album == null ? 0 : album.hashCode) +
        (discNo == null ? 0 : discNo.hashCode) +
        (trackNo == null ? 0 : trackNo.hashCode) +
        durationMs.hashCode +
        (year == null ? 0 : year.hashCode) +
        (genre == null ? 0 : genre.hashCode) +
        (artworkId == null ? 0 : artworkId.hashCode) +
        mediaVersion.hashCode +
        sourceFormat.hashCode +
        state.hashCode +
        hasLyrics.hashCode +
        updatedAt.hashCode;

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  Map<String, dynamic> toJson() => _$TrackToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum TrackStateEnum {
@JsonValue(r'available')
available(r'available'),
@JsonValue(r'missing')
missing(r'missing'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const TrackStateEnum(this.value);

final String value;

@override
String toString() => value;
}


