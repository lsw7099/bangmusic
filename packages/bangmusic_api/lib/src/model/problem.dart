//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:bangmusic_api/src/model/problem_errors_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'problem.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Problem {
  /// Returns a new [Problem] instance.
  Problem({

    required  this.type,

    required  this.title,

    required  this.status,

    required  this.code,

     this.detail,

     this.requestId,

     this.retryable,

     this.errors,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final int status;



      /// 기계 판독용 오류 코드. 전체 목록은 02-api-guide.md §오류 코드.
  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



      /// 사람이 읽는 설명. 경로·SQL·스택을 포함하지 않는다.
  @JsonKey(
    
    name: r'detail',
    required: false,
    includeIfNull: false,
  )


  final String? detail;



  @JsonKey(
    
    name: r'request_id',
    required: false,
    includeIfNull: false,
  )


  final String? requestId;



  @JsonKey(
    
    name: r'retryable',
    required: false,
    includeIfNull: false,
  )


  final bool? retryable;



  @JsonKey(
    
    name: r'errors',
    required: false,
    includeIfNull: false,
  )


  final List<ProblemErrorsInner>? errors;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Problem &&
      other.type == type &&
      other.title == title &&
      other.status == status &&
      other.code == code &&
      other.detail == detail &&
      other.requestId == requestId &&
      other.retryable == retryable &&
      other.errors == errors;

    @override
    int get hashCode =>
        type.hashCode +
        title.hashCode +
        status.hashCode +
        code.hashCode +
        detail.hashCode +
        requestId.hashCode +
        retryable.hashCode +
        errors.hashCode;

  factory Problem.fromJson(Map<String, dynamic> json) => _$ProblemFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

