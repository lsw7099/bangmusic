//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/lyrics_variant.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lyrics.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Lyrics {
  /// Returns a new [Lyrics] instance.
  Lyrics({

    required  this.trackId,

    required  this.version,

    required  this.offsetMs,

    required  this.variants,
  });

  @JsonKey(
    
    name: r'track_id',
    required: true,
    includeIfNull: false,
  )


  final String trackId;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



      /// 요청한 사용자의 보정값. 양수면 가사를 늦춘다.
  @JsonKey(
    
    name: r'offset_ms',
    required: true,
    includeIfNull: false,
  )


  final int offsetMs;



  @JsonKey(
    
    name: r'variants',
    required: true,
    includeIfNull: false,
  )


  final List<LyricsVariant> variants;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Lyrics &&
      other.trackId == trackId &&
      other.version == version &&
      other.offsetMs == offsetMs &&
      other.variants == variants;

    @override
    int get hashCode =>
        trackId.hashCode +
        version.hashCode +
        offsetMs.hashCode +
        variants.hashCode;

  factory Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);

  Map<String, dynamic> toJson() => _$LyricsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

