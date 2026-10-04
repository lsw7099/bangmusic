//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/change_batch_changes_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_batch.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangeBatch {
  /// Returns a new [ChangeBatch] instance.
  ChangeBatch({

    required  this.changes,

    required  this.nextSince,

    required  this.hasMore,
  });

  @JsonKey(
    
    name: r'changes',
    required: true,
    includeIfNull: false,
  )


  final List<ChangeBatchChangesInner> changes;



  @JsonKey(
    
    name: r'next_since',
    required: true,
    includeIfNull: false,
  )


  final String nextSince;



  @JsonKey(
    
    name: r'has_more',
    required: true,
    includeIfNull: false,
  )


  final bool hasMore;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChangeBatch &&
      other.changes == changes &&
      other.nextSince == nextSince &&
      other.hasMore == hasMore;

    @override
    int get hashCode =>
        changes.hashCode +
        nextSince.hashCode +
        hasMore.hashCode;

  factory ChangeBatch.fromJson(Map<String, dynamic> json) => _$ChangeBatchFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeBatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

