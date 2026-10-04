//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_library.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminLibrary {
  /// Returns a new [AdminLibrary] instance.
  AdminLibrary({

    required  this.id,

    required  this.name,

    required  this.status,

     this.trackCount,

     this.missingCount,

     this.lastScanAt,

     this.pendingReview,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AdminLibraryStatusEnum.unknownDefaultOpenApi,
  )


  final AdminLibraryStatusEnum status;



  @JsonKey(
    
    name: r'track_count',
    required: false,
    includeIfNull: false,
  )


  final int? trackCount;



  @JsonKey(
    
    name: r'missing_count',
    required: false,
    includeIfNull: false,
  )


  final int? missingCount;



  @JsonKey(
    
    name: r'last_scan_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? lastScanAt;



      /// 대량 누락이 감지되어 스캔 결과 적용이 보류됨
  @JsonKey(
    
    name: r'pending_review',
    required: false,
    includeIfNull: false,
  )


  final bool? pendingReview;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminLibrary &&
      other.id == id &&
      other.name == name &&
      other.status == status &&
      other.trackCount == trackCount &&
      other.missingCount == missingCount &&
      other.lastScanAt == lastScanAt &&
      other.pendingReview == pendingReview;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        status.hashCode +
        trackCount.hashCode +
        missingCount.hashCode +
        (lastScanAt == null ? 0 : lastScanAt.hashCode) +
        pendingReview.hashCode;

  factory AdminLibrary.fromJson(Map<String, dynamic> json) => _$AdminLibraryFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLibraryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminLibraryStatusEnum {
@JsonValue(r'online')
online(r'online'),
@JsonValue(r'unavailable')
unavailable(r'unavailable'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const AdminLibraryStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


