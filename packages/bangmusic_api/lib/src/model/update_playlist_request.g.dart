// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_playlist_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdatePlaylistRequestCWProxy {
  UpdatePlaylistRequest name(String? name);

  UpdatePlaylistRequest description(String? description);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdatePlaylistRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdatePlaylistRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdatePlaylistRequest call({String? name, String? description});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUpdatePlaylistRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUpdatePlaylistRequest.copyWith.fieldName(...)`
class _$UpdatePlaylistRequestCWProxyImpl
    implements _$UpdatePlaylistRequestCWProxy {
  const _$UpdatePlaylistRequestCWProxyImpl(this._value);

  final UpdatePlaylistRequest _value;

  @override
  UpdatePlaylistRequest name(String? name) => this(name: name);

  @override
  UpdatePlaylistRequest description(String? description) =>
      this(description: description);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdatePlaylistRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdatePlaylistRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdatePlaylistRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
  }) {
    return UpdatePlaylistRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
    );
  }
}

extension $UpdatePlaylistRequestCopyWith on UpdatePlaylistRequest {
  /// Returns a callable class that can be used as follows: `instanceOfUpdatePlaylistRequest.copyWith(...)` or like so:`instanceOfUpdatePlaylistRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdatePlaylistRequestCWProxy get copyWith =>
      _$UpdatePlaylistRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePlaylistRequest _$UpdatePlaylistRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdatePlaylistRequest', json, ($checkedConvert) {
  final val = UpdatePlaylistRequest(
    name: $checkedConvert('name', (v) => v as String?),
    description: $checkedConvert('description', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$UpdatePlaylistRequestToJson(
  UpdatePlaylistRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'description': ?instance.description,
};
