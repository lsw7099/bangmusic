//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum LyricsKind {
      @JsonValue(r'original')
      original(r'original'),
      @JsonValue(r'pronunciation_ko')
      pronunciationKo(r'pronunciation_ko'),
      @JsonValue(r'translation_ko')
      translationKo(r'translation_ko'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const LyricsKind(this.value);

  final String value;

  @override
  String toString() => value;
}
