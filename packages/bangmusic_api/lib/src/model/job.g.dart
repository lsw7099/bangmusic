// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JobCWProxy {
  Job id(String id);

  Job type(JobTypeEnum type);

  Job state(JobStateEnum state);

  Job progress(num? progress);

  Job errorCode(String? errorCode);

  Job startedAt(DateTime? startedAt);

  Job finishedAt(DateTime? finishedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Job(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Job(...).copyWith(id: 12, name: "My name")
  /// ````
  Job call({
    String id,
    JobTypeEnum type,
    JobStateEnum state,
    num? progress,
    String? errorCode,
    DateTime? startedAt,
    DateTime? finishedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfJob.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfJob.copyWith.fieldName(...)`
class _$JobCWProxyImpl implements _$JobCWProxy {
  const _$JobCWProxyImpl(this._value);

  final Job _value;

  @override
  Job id(String id) => this(id: id);

  @override
  Job type(JobTypeEnum type) => this(type: type);

  @override
  Job state(JobStateEnum state) => this(state: state);

  @override
  Job progress(num? progress) => this(progress: progress);

  @override
  Job errorCode(String? errorCode) => this(errorCode: errorCode);

  @override
  Job startedAt(DateTime? startedAt) => this(startedAt: startedAt);

  @override
  Job finishedAt(DateTime? finishedAt) => this(finishedAt: finishedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Job(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Job(...).copyWith(id: 12, name: "My name")
  /// ````
  Job call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? progress = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? finishedAt = const $CopyWithPlaceholder(),
  }) {
    return Job(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as JobTypeEnum,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as JobStateEnum,
      progress: progress == const $CopyWithPlaceholder()
          ? _value.progress
          // ignore: cast_nullable_to_non_nullable
          : progress as num?,
      errorCode: errorCode == const $CopyWithPlaceholder()
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String?,
      startedAt: startedAt == const $CopyWithPlaceholder()
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime?,
      finishedAt: finishedAt == const $CopyWithPlaceholder()
          ? _value.finishedAt
          // ignore: cast_nullable_to_non_nullable
          : finishedAt as DateTime?,
    );
  }
}

extension $JobCopyWith on Job {
  /// Returns a callable class that can be used as follows: `instanceOfJob.copyWith(...)` or like so:`instanceOfJob.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JobCWProxy get copyWith => _$JobCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Job _$JobFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Job',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['id', 'type', 'state']);
    final val = Job(
      id: $checkedConvert('id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(
          _$JobTypeEnumEnumMap,
          v,
          unknownValue: JobTypeEnum.unknownDefaultOpenApi,
        ),
      ),
      state: $checkedConvert(
        'state',
        (v) => $enumDecode(
          _$JobStateEnumEnumMap,
          v,
          unknownValue: JobStateEnum.unknownDefaultOpenApi,
        ),
      ),
      progress: $checkedConvert('progress', (v) => v as num?),
      errorCode: $checkedConvert('error_code', (v) => v as String?),
      startedAt: $checkedConvert(
        'started_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      finishedAt: $checkedConvert(
        'finished_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'errorCode': 'error_code',
    'startedAt': 'started_at',
    'finishedAt': 'finished_at',
  },
);

Map<String, dynamic> _$JobToJson(Job instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$JobTypeEnumEnumMap[instance.type]!,
  'state': _$JobStateEnumEnumMap[instance.state]!,
  'progress': ?instance.progress,
  'error_code': ?instance.errorCode,
  'started_at': ?instance.startedAt?.toIso8601String(),
  'finished_at': ?instance.finishedAt?.toIso8601String(),
};

const _$JobTypeEnumEnumMap = {
  JobTypeEnum.scan: 'scan',
  JobTypeEnum.transcode: 'transcode',
  JobTypeEnum.hash: 'hash',
  JobTypeEnum.backup: 'backup',
  JobTypeEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$JobStateEnumEnumMap = {
  JobStateEnum.queued: 'queued',
  JobStateEnum.running: 'running',
  JobStateEnum.succeeded: 'succeeded',
  JobStateEnum.failed: 'failed',
  JobStateEnum.canceled: 'canceled',
  JobStateEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
