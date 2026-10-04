// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_sessions200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListSessions200ResponseCWProxy {
  ListSessions200Response items(List<Session> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListSessions200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListSessions200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  ListSessions200Response call({List<Session> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfListSessions200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfListSessions200Response.copyWith.fieldName(...)`
class _$ListSessions200ResponseCWProxyImpl
    implements _$ListSessions200ResponseCWProxy {
  const _$ListSessions200ResponseCWProxyImpl(this._value);

  final ListSessions200Response _value;

  @override
  ListSessions200Response items(List<Session> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ListSessions200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ListSessions200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  ListSessions200Response call({Object? items = const $CopyWithPlaceholder()}) {
    return ListSessions200Response(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Session>,
    );
  }
}

extension $ListSessions200ResponseCopyWith on ListSessions200Response {
  /// Returns a callable class that can be used as follows: `instanceOfListSessions200Response.copyWith(...)` or like so:`instanceOfListSessions200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListSessions200ResponseCWProxy get copyWith =>
      _$ListSessions200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListSessions200Response _$ListSessions200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListSessions200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ListSessions200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListSessions200ResponseToJson(
  ListSessions200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
