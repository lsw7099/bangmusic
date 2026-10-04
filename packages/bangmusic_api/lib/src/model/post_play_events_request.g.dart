// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_play_events_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PostPlayEventsRequestCWProxy {
  PostPlayEventsRequest events(List<PlayEvent> events);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostPlayEventsRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostPlayEventsRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PostPlayEventsRequest call({List<PlayEvent> events});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPostPlayEventsRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPostPlayEventsRequest.copyWith.fieldName(...)`
class _$PostPlayEventsRequestCWProxyImpl
    implements _$PostPlayEventsRequestCWProxy {
  const _$PostPlayEventsRequestCWProxyImpl(this._value);

  final PostPlayEventsRequest _value;

  @override
  PostPlayEventsRequest events(List<PlayEvent> events) => this(events: events);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostPlayEventsRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostPlayEventsRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PostPlayEventsRequest call({Object? events = const $CopyWithPlaceholder()}) {
    return PostPlayEventsRequest(
      events: events == const $CopyWithPlaceholder()
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<PlayEvent>,
    );
  }
}

extension $PostPlayEventsRequestCopyWith on PostPlayEventsRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPostPlayEventsRequest.copyWith(...)` or like so:`instanceOfPostPlayEventsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PostPlayEventsRequestCWProxy get copyWith =>
      _$PostPlayEventsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostPlayEventsRequest _$PostPlayEventsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PostPlayEventsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['events']);
  final val = PostPlayEventsRequest(
    events: $checkedConvert(
      'events',
      (v) => (v as List<dynamic>)
          .map((e) => PlayEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PostPlayEventsRequestToJson(
  PostPlayEventsRequest instance,
) => <String, dynamic>{
  'events': instance.events.map((e) => e.toJson()).toList(),
};
