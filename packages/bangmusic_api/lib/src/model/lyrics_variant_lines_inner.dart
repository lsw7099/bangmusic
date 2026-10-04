//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lyrics_variant_lines_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LyricsVariantLinesInner {
  /// Returns a new [LyricsVariantLinesInner] instance.
  LyricsVariantLinesInner({

    required  this.tMs,

    required  this.text,
  });

  @JsonKey(
    
    name: r't_ms',
    required: true,
    includeIfNull: true,
  )


  final int? tMs;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LyricsVariantLinesInner &&
      other.tMs == tMs &&
      other.text == text;

    @override
    int get hashCode =>
        (tMs == null ? 0 : tMs.hashCode) +
        text.hashCode;

  factory LyricsVariantLinesInner.fromJson(Map<String, dynamic> json) => _$LyricsVariantLinesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$LyricsVariantLinesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

