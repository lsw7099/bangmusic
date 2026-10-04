//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/artist.dart';
import 'package:bangmusic_api/src/model/album.dart';
import 'package:bangmusic_api/src/model/track.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'change_batch_changes_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangeBatchChangesInner {
  /// Returns a new [ChangeBatchChangesInner] instance.
  ChangeBatchChangesInner({

    required  this.entity,

    required  this.id,

    required  this.op,

     this.track,

     this.album,

     this.artist,
  });

  @JsonKey(
    
    name: r'entity',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ChangeBatchChangesInnerEntityEnum.unknownDefaultOpenApi,
  )


  final ChangeBatchChangesInnerEntityEnum entity;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'op',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ChangeBatchChangesInnerOpEnum.unknownDefaultOpenApi,
  )


  final ChangeBatchChangesInnerOpEnum op;



  @JsonKey(
    
    name: r'track',
    required: false,
    includeIfNull: false,
  )


  final Track? track;



  @JsonKey(
    
    name: r'album',
    required: false,
    includeIfNull: false,
  )


  final Album? album;



  @JsonKey(
    
    name: r'artist',
    required: false,
    includeIfNull: false,
  )


  final Artist? artist;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChangeBatchChangesInner &&
      other.entity == entity &&
      other.id == id &&
      other.op == op &&
      other.track == track &&
      other.album == album &&
      other.artist == artist;

    @override
    int get hashCode =>
        entity.hashCode +
        id.hashCode +
        op.hashCode +
        track.hashCode +
        album.hashCode +
        artist.hashCode;

  factory ChangeBatchChangesInner.fromJson(Map<String, dynamic> json) => _$ChangeBatchChangesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeBatchChangesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ChangeBatchChangesInnerEntityEnum {
@JsonValue(r'track')
track(r'track'),
@JsonValue(r'album')
album(r'album'),
@JsonValue(r'artist')
artist(r'artist'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const ChangeBatchChangesInnerEntityEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ChangeBatchChangesInnerOpEnum {
@JsonValue(r'upsert')
upsert(r'upsert'),
@JsonValue(r'delete')
delete(r'delete'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const ChangeBatchChangesInnerOpEnum(this.value);

final String value;

@override
String toString() => value;
}


