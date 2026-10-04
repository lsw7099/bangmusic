// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_play_events200_response_rejected_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PostPlayEvents200ResponseRejectedInnerCWProxy {
  PostPlayEvents200ResponseRejectedInner eventId(String eventId);

  PostPlayEvents200ResponseRejectedInner code(String code);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostPlayEvents200ResponseRejectedInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostPlayEvents200ResponseRejectedInner(...).copyWith(id: 12, name: "My name")
  /// ````
  PostPlayEvents200ResponseRejectedInner call({String eventId, String code});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPostPlayEvents200ResponseRejectedInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPostPlayEvents200ResponseRejectedInner.copyWith.fieldName(...)`
class _$PostPlayEvents200ResponseRejectedInnerCWProxyImpl
    implements _$PostPlayEvents200ResponseRejectedInnerCWProxy {
  const _$PostPlayEvents200ResponseRejectedInnerCWProxyImpl(this._value);

  final PostPlayEvents200ResponseRejectedInner _value;

  @override
  PostPlayEvents200ResponseRejectedInner eventId(String eventId) =>
      this(eventId: eventId);

  @override
  PostPlayEvents200ResponseRejectedInner code(String code) => this(code: code);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostPlayEvents200ResponseRejectedInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostPlayEvents200ResponseRejectedInner(...).copyWith(id: 12, name: "My name")
  /// ````
  PostPlayEvents200ResponseRejectedInner call({
    Object? eventId = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
  }) {
    return PostPlayEvents200ResponseRejectedInner(
      eventId: eventId == const $CopyWithPlaceholder()
          ? _value.eventId
          // ignore: cast_nullable_to_non_nullable
          : eventId as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
    );
  }
}

extension $PostPlayEvents200ResponseRejectedInnerCopyWith
    on PostPlayEvents200ResponseRejectedInner {
  /// Returns a callable class that can be used as follows: `instanceOfPostPlayEvents200ResponseRejectedInner.copyWith(...)` or like so:`instanceOfPostPlayEvents200ResponseRejectedInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PostPlayEvents200ResponseRejectedInnerCWProxy get copyWith =>
      _$PostPlayEvents200ResponseRejectedInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostPlayEvents200ResponseRejectedInner
_$PostPlayEvents200ResponseRejectedInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PostPlayEvents200ResponseRejectedInner',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['event_id', 'code']);
        final val = PostPlayEvents200ResponseRejectedInner(
          eventId: $checkedConvert('event_id', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'eventId': 'event_id'},
    );

Map<String, dynamic> _$PostPlayEvents200ResponseRejectedInnerToJson(
  PostPlayEvents200ResponseRejectedInner instance,
) => <String, dynamic>{'event_id': instance.eventId, 'code': instance.code};
