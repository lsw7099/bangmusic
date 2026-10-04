//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Session {
  /// Returns a new [Session] instance.
  Session({

    required  this.id,

    required  this.deviceName,

    required  this.platform,

     this.appVersion,

    required  this.createdAt,

    required  this.lastSeenAt,

    required  this.current,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'device_name',
    required: true,
    includeIfNull: false,
  )


  final String deviceName;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final String platform;



  @JsonKey(
    
    name: r'app_version',
    required: false,
    includeIfNull: false,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'last_seen_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime lastSeenAt;



  @JsonKey(
    
    name: r'current',
    required: true,
    includeIfNull: false,
  )


  final bool current;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Session &&
      other.id == id &&
      other.deviceName == deviceName &&
      other.platform == platform &&
      other.appVersion == appVersion &&
      other.createdAt == createdAt &&
      other.lastSeenAt == lastSeenAt &&
      other.current == current;

    @override
    int get hashCode =>
        id.hashCode +
        deviceName.hashCode +
        platform.hashCode +
        appVersion.hashCode +
        createdAt.hashCode +
        lastSeenAt.hashCode +
        current.hashCode;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  Map<String, dynamic> toJson() => _$SessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

