//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rendition.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Rendition {
  /// Returns a new [Rendition] instance.
  Rendition({

    required  this.id,

    required  this.trackId,

    required  this.mediaVersion,

    required  this.profile,

    required  this.state,

     this.mime,

     this.container,

     this.codec,

     this.sizeBytes,

     this.durationMs,

     this.sha256,

     this.etag,

     this.seekable,

     this.mediaUrl,

     this.ticketExpiresAt,

     this.errorCode,

     this.retryAfterS,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'track_id',
    required: true,
    includeIfNull: false,
  )


  final String trackId;



  @JsonKey(
    
    name: r'media_version',
    required: true,
    includeIfNull: false,
  )


  final String mediaVersion;



  @JsonKey(
    
    name: r'profile',
    required: true,
    includeIfNull: false,
  )


  final String profile;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  unknownEnumValue: RenditionStateEnum.unknownDefaultOpenApi,
  )


  final RenditionStateEnum state;



  @JsonKey(
    
    name: r'mime',
    required: false,
    includeIfNull: false,
  )


  final String? mime;



  @JsonKey(
    
    name: r'container',
    required: false,
    includeIfNull: false,
  )


  final String? container;



  @JsonKey(
    
    name: r'codec',
    required: false,
    includeIfNull: false,
  )


  final String? codec;



      /// `ready`일 때만. 정확한 바이트 수.
  @JsonKey(
    
    name: r'size_bytes',
    required: false,
    includeIfNull: false,
  )


  final int? sizeBytes;



      /// 실제 제공 파일의 길이. 원본과 수 ms 다를 수 있다.
  @JsonKey(
    
    name: r'duration_ms',
    required: false,
    includeIfNull: false,
  )


  final int? durationMs;



      /// 제공 바이트 전체의 해시. 아직 계산 전이면 null.
  @JsonKey(
    
    name: r'sha256',
    required: false,
    includeIfNull: false,
  )


  final String? sha256;



  @JsonKey(
    
    name: r'etag',
    required: false,
    includeIfNull: false,
  )


  final String? etag;



  @JsonKey(
    
    name: r'seekable',
    required: false,
    includeIfNull: false,
  )


  final bool? seekable;



      /// 서버 기준 상대 경로 + 미디어 티켓. 저장하지 말고 필요할 때 다시 받는다.
  @JsonKey(
    
    name: r'media_url',
    required: false,
    includeIfNull: false,
  )


  final String? mediaUrl;



  @JsonKey(
    
    name: r'ticket_expires_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? ticketExpiresAt;



      /// `failed`일 때: `transcode_failed`, `unsupported_source`, `media_missing`
  @JsonKey(
    
    name: r'error_code',
    required: false,
    includeIfNull: false,
  )


  final String? errorCode;



  @JsonKey(
    
    name: r'retry_after_s',
    required: false,
    includeIfNull: false,
  )


  final int? retryAfterS;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Rendition &&
      other.id == id &&
      other.trackId == trackId &&
      other.mediaVersion == mediaVersion &&
      other.profile == profile &&
      other.state == state &&
      other.mime == mime &&
      other.container == container &&
      other.codec == codec &&
      other.sizeBytes == sizeBytes &&
      other.durationMs == durationMs &&
      other.sha256 == sha256 &&
      other.etag == etag &&
      other.seekable == seekable &&
      other.mediaUrl == mediaUrl &&
      other.ticketExpiresAt == ticketExpiresAt &&
      other.errorCode == errorCode &&
      other.retryAfterS == retryAfterS;

    @override
    int get hashCode =>
        id.hashCode +
        trackId.hashCode +
        mediaVersion.hashCode +
        profile.hashCode +
        state.hashCode +
        mime.hashCode +
        container.hashCode +
        codec.hashCode +
        sizeBytes.hashCode +
        durationMs.hashCode +
        (sha256 == null ? 0 : sha256.hashCode) +
        etag.hashCode +
        seekable.hashCode +
        mediaUrl.hashCode +
        ticketExpiresAt.hashCode +
        (errorCode == null ? 0 : errorCode.hashCode) +
        (retryAfterS == null ? 0 : retryAfterS.hashCode);

  factory Rendition.fromJson(Map<String, dynamic> json) => _$RenditionFromJson(json);

  Map<String, dynamic> toJson() => _$RenditionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum RenditionStateEnum {
@JsonValue(r'ready')
ready(r'ready'),
@JsonValue(r'preparing')
preparing(r'preparing'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const RenditionStateEnum(this.value);

final String value;

@override
String toString() => value;
}


