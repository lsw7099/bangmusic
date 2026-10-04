//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'job.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Job {
  /// Returns a new [Job] instance.
  Job({

    required  this.id,

    required  this.type,

    required  this.state,

     this.progress,

     this.errorCode,

     this.startedAt,

     this.finishedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  unknownEnumValue: JobTypeEnum.unknownDefaultOpenApi,
  )


  final JobTypeEnum type;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  unknownEnumValue: JobStateEnum.unknownDefaultOpenApi,
  )


  final JobStateEnum state;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'progress',
    required: false,
    includeIfNull: false,
  )


  final num? progress;



  @JsonKey(
    
    name: r'error_code',
    required: false,
    includeIfNull: false,
  )


  final String? errorCode;



  @JsonKey(
    
    name: r'started_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? startedAt;



  @JsonKey(
    
    name: r'finished_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? finishedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Job &&
      other.id == id &&
      other.type == type &&
      other.state == state &&
      other.progress == progress &&
      other.errorCode == errorCode &&
      other.startedAt == startedAt &&
      other.finishedAt == finishedAt;

    @override
    int get hashCode =>
        id.hashCode +
        type.hashCode +
        state.hashCode +
        (progress == null ? 0 : progress.hashCode) +
        (errorCode == null ? 0 : errorCode.hashCode) +
        (startedAt == null ? 0 : startedAt.hashCode) +
        (finishedAt == null ? 0 : finishedAt.hashCode);

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  Map<String, dynamic> toJson() => _$JobToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum JobTypeEnum {
@JsonValue(r'scan')
scan(r'scan'),
@JsonValue(r'transcode')
transcode(r'transcode'),
@JsonValue(r'hash')
hash(r'hash'),
@JsonValue(r'backup')
backup(r'backup'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const JobTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


enum JobStateEnum {
@JsonValue(r'queued')
queued(r'queued'),
@JsonValue(r'running')
running(r'running'),
@JsonValue(r'succeeded')
succeeded(r'succeeded'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'canceled')
canceled(r'canceled'),
@JsonValue(r'unknown_default_open_api')
unknownDefaultOpenApi(r'unknown_default_open_api');

const JobStateEnum(this.value);

final String value;

@override
String toString() => value;
}


