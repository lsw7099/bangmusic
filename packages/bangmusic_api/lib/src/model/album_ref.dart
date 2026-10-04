//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'album_ref.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlbumRef {
  /// Returns a new [AlbumRef] instance.
  AlbumRef({

    required  this.id,

    required  this.title,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlbumRef &&
      other.id == id &&
      other.title == title;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode;

  factory AlbumRef.fromJson(Map<String, dynamic> json) => _$AlbumRefFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

