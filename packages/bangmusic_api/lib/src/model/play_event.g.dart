// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlayEventCWProxy {
  PlayEvent eventId(String eventId);

  PlayEvent trackId(String trackId);

  PlayEvent startedAt(DateTime startedAt);

  PlayEvent playedMs(int playedMs);

  PlayEvent completed(bool completed);

  PlayEvent source_(PlayEventSource_Enum source_);

  PlayEvent context(PlayEventContext? context);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlayEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlayEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  PlayEvent call({
    String eventId,
    String trackId,
    DateTime startedAt,
    int playedMs,
    bool completed,
    PlayEventSource_Enum source_,
    PlayEventContext? context,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlayEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlayEvent.copyWith.fieldName(...)`
class _$PlayEventCWProxyImpl implements _$PlayEventCWProxy {
  const _$PlayEventCWProxyImpl(this._value);

  final PlayEvent _value;

  @override
  PlayEvent eventId(String eventId) => this(eventId: eventId);

  @override
  PlayEvent trackId(String trackId) => this(trackId: trackId);

  @override
  PlayEvent startedAt(DateTime startedAt) => this(startedAt: startedAt);

  @override
  PlayEvent playedMs(int playedMs) => this(playedMs: playedMs);

  @override
  PlayEvent completed(bool completed) => this(completed: completed);

  @override
  PlayEvent source_(PlayEventSource_Enum source_) => this(source_: source_);

  @override
  PlayEvent context(PlayEventContext? context) => this(context: context);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlayEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlayEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  PlayEvent call({
    Object? eventId = const $CopyWithPlaceholder(),
    Object? trackId = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? playedMs = const $CopyWithPlaceholder(),
    Object? completed = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? context = const $CopyWithPlaceholder(),
  }) {
    return PlayEvent(
      eventId: eventId == const $CopyWithPlaceholder()
          ? _value.eventId
          // ignore: cast_nullable_to_non_nullable
          : eventId as String,
      trackId: trackId == const $CopyWithPlaceholder()
          ? _value.trackId
          // ignore: cast_nullable_to_non_nullable
          : trackId as String,
      startedAt: startedAt == const $CopyWithPlaceholder()
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime,
      playedMs: playedMs == const $CopyWithPlaceholder()
          ? _value.playedMs
          // ignore: cast_nullable_to_non_nullable
          : playedMs as int,
      completed: completed == const $CopyWithPlaceholder()
          ? _value.completed
          // ignore: cast_nullable_to_non_nullable
          : completed as bool,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as PlayEventSource_Enum,
      context: context == const $CopyWithPlaceholder()
          ? _value.context
          // ignore: cast_nullable_to_non_nullable
          : context as PlayEventContext?,
    );
  }
}

extension $PlayEventCopyWith on PlayEvent {
  /// Returns a callable class that can be used as follows: `instanceOfPlayEvent.copyWith(...)` or like so:`instanceOfPlayEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlayEventCWProxy get copyWith => _$PlayEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayEvent _$PlayEventFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PlayEvent',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'event_id',
        'track_id',
        'started_at',
        'played_ms',
        'completed',
        'source',
      ],
    );
    final val = PlayEvent(
      eventId: $checkedConvert('event_id', (v) => v as String),
      trackId: $checkedConvert('track_id', (v) => v as String),
      startedAt: $checkedConvert(
        'started_at',
        (v) => DateTime.parse(v as String),
      ),
      playedMs: $checkedConvert('played_ms', (v) => (v as num).toInt()),
      completed: $checkedConvert('completed', (v) => v as bool),
      source_: $checkedConvert(
        'source',
        (v) => $enumDecode(
          _$PlayEventSource_EnumEnumMap,
          v,
          unknownValue: PlayEventSource_Enum.unknownDefaultOpenApi,
        ),
      ),
      context: $checkedConvert(
        'context',
        (v) => v == null
            ? null
            : PlayEventContext.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'eventId': 'event_id',
    'trackId': 'track_id',
    'startedAt': 'started_at',
    'playedMs': 'played_ms',
    'source_': 'source',
  },
);

Map<String, dynamic> _$PlayEventToJson(PlayEvent instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'track_id': instance.trackId,
  'started_at': instance.startedAt.toIso8601String(),
  'played_ms': instance.playedMs,
  'completed': instance.completed,
  'source': _$PlayEventSource_EnumEnumMap[instance.source_]!,
  'context': ?instance.context?.toJson(),
};

const _$PlayEventSource_EnumEnumMap = {
  PlayEventSource_Enum.stream: 'stream',
  PlayEventSource_Enum.offline: 'offline',
  PlayEventSource_Enum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
