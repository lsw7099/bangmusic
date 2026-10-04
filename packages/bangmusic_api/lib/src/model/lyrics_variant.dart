//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/lyrics_variant_lines_inner.dart';
import 'package:bangmusic_api/src/model/lyrics_variant_source.dart';
import 'package:bangmusic_api/src/model/lyrics_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lyrics_variant.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LyricsVariant {
  /// Returns a new [LyricsVariant] instance.
  LyricsVariant({

    required  this.kind,

     this.language,

    required  this.synced,

    required  this.lines,

    required  this.source_,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  unknownEnumValue: LyricsKind.unknownDefaultOpenApi,
  )


  final LyricsKind kind;



      /// BCP 47
  @JsonKey(
    
    name: r'language',
    required: false,
    includeIfNull: false,
  )


  final String? language;



      /// false면 모든 `t_ms`가 null
  @JsonKey(
    
    name: r'synced',
    required: true,
    includeIfNull: false,
  )


  final bool synced;



  @JsonKey(
    
    name: r'lines',
    required: true,
    includeIfNull: false,
  )


  final List<LyricsVariantLinesInner> lines;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final LyricsVariantSource source_;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LyricsVariant &&
      other.kind == kind &&
      other.language == language &&
      other.synced == synced &&
      other.lines == lines &&
      other.source_ == source_;

    @override
    int get hashCode =>
        kind.hashCode +
        (language == null ? 0 : language.hashCode) +
        synced.hashCode +
        lines.hashCode +
        source_.hashCode;

  factory LyricsVariant.fromJson(Map<String, dynamic> json) => _$LyricsVariantFromJson(json);

  Map<String, dynamic> toJson() => _$LyricsVariantToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

