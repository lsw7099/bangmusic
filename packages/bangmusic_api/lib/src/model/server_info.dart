//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/server_info_api.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServerInfo {
  /// Returns a new [ServerInfo] instance.
  ServerInfo({

    required  this.serverId,

    required  this.name,

    required  this.product,

    required  this.version,

    required  this.api,

    required  this.minClientApiMinor,

    required  this.features,

     this.transcodeProfiles,

    required  this.limits,

    required  this.setupRequired,
  });

      /// 서버 설치의 영속 식별자. 앱의 서버 프로필·캐시 분리 키.
  @JsonKey(
    
    name: r'server_id',
    required: true,
    includeIfNull: false,
  )


  final String serverId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'product',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ServerInfoProductEnum.unknownDefaultOpenApi,
  )


  final ServerInfoProductEnum product;



      /// 서버 소프트웨어 버전(SemVer)
  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final String version;



  @JsonKey(
    
    name: r'api',
    required: true,
    includeIfNull: false,
  )


  final ServerInfoApi api;



  @JsonKey(
    
    name: r'min_client_api_minor',
    required: true,
    includeIfNull: false,
  )


  final int minClientApiMinor;



      /// 서버가 켜 둔 선택 기능. 앱은 모르는 값을 무시한다.
  @JsonKey(
    
    name: r'features',
    required: true,
    includeIfNull: false,
  )


  final List<String> features;



  @JsonKey(
    
    name: r'transcode_profiles',
    required: false,
    includeIfNull: false,
  )


  final List<String>? transcodeProfiles;



  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, int> limits;



  @JsonKey(
    
    name: r'setup_required',
    required: true,
    includeIfNull: false,
  )


  final bool setupRequired;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ServerInfo &&
      other.serverId == serverId &&
      other.name == name &&
      other.product == product &&
      other.version == version &&
      other.api == api &&
      other.minClientApiMinor == minClientApiMinor &&
      other.features == features &&
      other.transcodeProfiles == transcodeProfiles &&
      other.limits == limits &&
      other.setupRequired == setupRequired;

    @override
    int get hashCode =>
        serverId.hashCode +
        name.hashCode +
        product.hashCode +
        version.hashCode +
        api.hashCode +
        minClientApiMinor.hashCode +
        features.hashCode +
        transcodeProfiles.hashCode +
        limits.hashCode +
        setupRequired.hashCode;

  factory ServerInfo.fromJson(Map<String, dynamic> json) => _$ServerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ServerInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ServerInfoProductEnum {
@JsonValue(r'bangmusic-server')
bangmusicServer(r'bangmusic-server'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const ServerInfoProductEnum(this.value);

final String value;

@override
String toString() => value;
}


