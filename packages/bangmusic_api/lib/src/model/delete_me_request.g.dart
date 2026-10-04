// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_me_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteMeRequestCWProxy {
  DeleteMeRequest password(String password);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeleteMeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeleteMeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  DeleteMeRequest call({String password});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeleteMeRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeleteMeRequest.copyWith.fieldName(...)`
class _$DeleteMeRequestCWProxyImpl implements _$DeleteMeRequestCWProxy {
  const _$DeleteMeRequestCWProxyImpl(this._value);

  final DeleteMeRequest _value;

  @override
  DeleteMeRequest password(String password) => this(password: password);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeleteMeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeleteMeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  DeleteMeRequest call({Object? password = const $CopyWithPlaceholder()}) {
    return DeleteMeRequest(
      password: password == const $CopyWithPlaceholder()
          ? _value.password
          // ignore: cast_nullable_to_non_nullable
          : password as String,
    );
  }
}

extension $DeleteMeRequestCopyWith on DeleteMeRequest {
  /// Returns a callable class that can be used as follows: `instanceOfDeleteMeRequest.copyWith(...)` or like so:`instanceOfDeleteMeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteMeRequestCWProxy get copyWith => _$DeleteMeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteMeRequest _$DeleteMeRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeleteMeRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['password']);
      final val = DeleteMeRequest(
        password: $checkedConvert('password', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeleteMeRequestToJson(DeleteMeRequest instance) =>
    <String, dynamic>{'password': instance.password};
