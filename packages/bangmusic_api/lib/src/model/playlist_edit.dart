//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'playlist_edit.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaylistEdit {
  /// Returns a new [PlaylistEdit] instance.
  PlaylistEdit({

    required  this.ops,
  });

  @JsonKey(
    
    name: r'ops',
    required: true,
    includeIfNull: false,
  )


  final List<PlaylistEditOpsInner> ops;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaylistEdit &&
      other.ops == ops;

    @override
    int get hashCode =>
        ops.hashCode;

  factory PlaylistEdit.fromJson(Map<String, dynamic> json) => _$PlaylistEditFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistEditToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

