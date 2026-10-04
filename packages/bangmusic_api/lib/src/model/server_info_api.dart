//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_info_api.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServerInfoApi {
  /// Returns a new [ServerInfoApi] instance.
  ServerInfoApi({

    required  this.major,

    required  this.minor,
  });

  @JsonKey(
    
    name: r'major',
    required: true,
    includeIfNull: false,
  )


  final int major;



      /// `/v1` 안에서 기능이 추가될 때마다 증가
  @JsonKey(
    
    name: r'minor',
    required: true,
    includeIfNull: false,
  )


  final int minor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ServerInfoApi &&
      other.major == major &&
      other.minor == minor;

    @override
    int get hashCode =>
        major.hashCode +
        minor.hashCode;

  factory ServerInfoApi.fromJson(Map<String, dynamic> json) => _$ServerInfoApiFromJson(json);

  Map<String, dynamic> toJson() => _$ServerInfoApiToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

