// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_event_context.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlayEventContextCWProxy {
  PlayEventContext type(PlayEventContextTypeEnum? type);

  PlayEventContext id(String? id);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlayEventContext(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlayEventContext(...).copyWith(id: 12, name: "My name")
  /// ````
  PlayEventContext call({PlayEventContextTypeEnum? type, String? id});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPlayEventContext.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPlayEventContext.copyWith.fieldName(...)`
class _$PlayEventContextCWProxyImpl implements _$PlayEventContextCWProxy {
  const _$PlayEventContextCWProxyImpl(this._value);

  final PlayEventContext _value;

  @override
  PlayEventContext type(PlayEventContextTypeEnum? type) => this(type: type);

  @override
  PlayEventContext id(String? id) => this(id: id);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PlayEventContext(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PlayEventContext(...).copyWith(id: 12, name: "My name")
  /// ````
  PlayEventContext call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return PlayEventContext(
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PlayEventContextTypeEnum?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String?,
    );
  }
}

extension $PlayEventContextCopyWith on PlayEventContext {
  /// Returns a callable class that can be used as follows: `instanceOfPlayEventContext.copyWith(...)` or like so:`instanceOfPlayEventContext.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlayEventContextCWProxy get copyWith => _$PlayEventContextCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayEventContext _$PlayEventContextFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlayEventContext', json, ($checkedConvert) {
      final val = PlayEventContext(
        type: $checkedConvert(
          'type',
          (v) => $enumDecodeNullable(
            _$PlayEventContextTypeEnumEnumMap,
            v,
            unknownValue: PlayEventContextTypeEnum.unknownDefaultOpenApi,
          ),
        ),
        id: $checkedConvert('id', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PlayEventContextToJson(PlayEventContext instance) =>
    <String, dynamic>{
      'type': ?_$PlayEventContextTypeEnumEnumMap[instance.type],
      'id': ?instance.id,
    };

const _$PlayEventContextTypeEnumEnumMap = {
  PlayEventContextTypeEnum.album: 'album',
  PlayEventContextTypeEnum.playlist: 'playlist',
  PlayEventContextTypeEnum.artist: 'artist',
  PlayEventContextTypeEnum.search: 'search',
  PlayEventContextTypeEnum.library_: 'library',
  PlayEventContextTypeEnum.queue: 'queue',
  PlayEventContextTypeEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
