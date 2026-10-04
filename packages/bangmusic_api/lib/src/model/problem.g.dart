// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProblemCWProxy {
  Problem type(String type);

  Problem title(String title);

  Problem status(int status);

  Problem code(String code);

  Problem detail(String? detail);

  Problem requestId(String? requestId);

  Problem retryable(bool? retryable);

  Problem errors(List<ProblemErrorsInner>? errors);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Problem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Problem(...).copyWith(id: 12, name: "My name")
  /// ````
  Problem call({
    String type,
    String title,
    int status,
    String code,
    String? detail,
    String? requestId,
    bool? retryable,
    List<ProblemErrorsInner>? errors,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProblem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProblem.copyWith.fieldName(...)`
class _$ProblemCWProxyImpl implements _$ProblemCWProxy {
  const _$ProblemCWProxyImpl(this._value);

  final Problem _value;

  @override
  Problem type(String type) => this(type: type);

  @override
  Problem title(String title) => this(title: title);

  @override
  Problem status(int status) => this(status: status);

  @override
  Problem code(String code) => this(code: code);

  @override
  Problem detail(String? detail) => this(detail: detail);

  @override
  Problem requestId(String? requestId) => this(requestId: requestId);

  @override
  Problem retryable(bool? retryable) => this(retryable: retryable);

  @override
  Problem errors(List<ProblemErrorsInner>? errors) => this(errors: errors);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Problem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Problem(...).copyWith(id: 12, name: "My name")
  /// ````
  Problem call({
    Object? type = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
    Object? retryable = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
  }) {
    return Problem(
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as int,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String?,
      retryable: retryable == const $CopyWithPlaceholder()
          ? _value.retryable
          // ignore: cast_nullable_to_non_nullable
          : retryable as bool?,
      errors: errors == const $CopyWithPlaceholder()
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as List<ProblemErrorsInner>?,
    );
  }
}

extension $ProblemCopyWith on Problem {
  /// Returns a callable class that can be used as follows: `instanceOfProblem.copyWith(...)` or like so:`instanceOfProblem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProblemCWProxy get copyWith => _$ProblemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Problem _$ProblemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Problem',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['type', 'title', 'status', 'code']);
    final val = Problem(
      type: $checkedConvert('type', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      status: $checkedConvert('status', (v) => (v as num).toInt()),
      code: $checkedConvert('code', (v) => v as String),
      detail: $checkedConvert('detail', (v) => v as String?),
      requestId: $checkedConvert('request_id', (v) => v as String?),
      retryable: $checkedConvert('retryable', (v) => v as bool?),
      errors: $checkedConvert(
        'errors',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ProblemErrorsInner.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'requestId': 'request_id'},
);

Map<String, dynamic> _$ProblemToJson(Problem instance) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'status': instance.status,
  'code': instance.code,
  'detail': ?instance.detail,
  'request_id': ?instance.requestId,
  'retryable': ?instance.retryable,
  'errors': ?instance.errors?.map((e) => e.toJson()).toList(),
};
