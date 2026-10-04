//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceInfo {
  /// Returns a new [DeviceInfo] instance.
  DeviceInfo({

    required  this.name,

    required  this.platform,

    required  this.appVersion,

    required  this.installationId,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  unknownEnumValue: DeviceInfoPlatformEnum.unknownDefaultOpenApi,
  )


  final DeviceInfoPlatformEnum platform;



  @JsonKey(
    
    name: r'app_version',
    required: true,
    includeIfNull: false,
  )


  final String appVersion;



      /// 앱 설치마다 무작위 생성. 같은 값으로 다시 로그인하면 이전 세션을 대체한다. 하드웨어 식별자를 쓰지 않는다.
  @JsonKey(
    
    name: r'installation_id',
    required: true,
    includeIfNull: false,
  )


  final String installationId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceInfo &&
      other.name == name &&
      other.platform == platform &&
      other.appVersion == appVersion &&
      other.installationId == installationId;

    @override
    int get hashCode =>
        name.hashCode +
        platform.hashCode +
        appVersion.hashCode +
        installationId.hashCode;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum DeviceInfoPlatformEnum {
@JsonValue(r'android')
android(r'android'),
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'other')
other(r'other'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const DeviceInfoPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


