// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_list_users200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminListUsers200ResponseCWProxy {
  AdminListUsers200Response items(List<AdminUser> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminListUsers200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminListUsers200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminListUsers200Response call({List<AdminUser> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminListUsers200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminListUsers200Response.copyWith.fieldName(...)`
class _$AdminListUsers200ResponseCWProxyImpl
    implements _$AdminListUsers200ResponseCWProxy {
  const _$AdminListUsers200ResponseCWProxyImpl(this._value);

  final AdminListUsers200Response _value;

  @override
  AdminListUsers200Response items(List<AdminUser> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminListUsers200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminListUsers200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminListUsers200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return AdminListUsers200Response(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminUser>,
    );
  }
}

extension $AdminListUsers200ResponseCopyWith on AdminListUsers200Response {
  /// Returns a callable class that can be used as follows: `instanceOfAdminListUsers200Response.copyWith(...)` or like so:`instanceOfAdminListUsers200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminListUsers200ResponseCWProxy get copyWith =>
      _$AdminListUsers200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminListUsers200Response _$AdminListUsers200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminListUsers200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = AdminListUsers200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminListUsers200ResponseToJson(
  AdminListUsers200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
