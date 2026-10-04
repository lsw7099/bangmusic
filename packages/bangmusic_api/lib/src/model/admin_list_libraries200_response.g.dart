// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_list_libraries200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminListLibraries200ResponseCWProxy {
  AdminListLibraries200Response items(List<AdminLibrary> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminListLibraries200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminListLibraries200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminListLibraries200Response call({List<AdminLibrary> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminListLibraries200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminListLibraries200Response.copyWith.fieldName(...)`
class _$AdminListLibraries200ResponseCWProxyImpl
    implements _$AdminListLibraries200ResponseCWProxy {
  const _$AdminListLibraries200ResponseCWProxyImpl(this._value);

  final AdminListLibraries200Response _value;

  @override
  AdminListLibraries200Response items(List<AdminLibrary> items) =>
      this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminListLibraries200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminListLibraries200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminListLibraries200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return AdminListLibraries200Response(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminLibrary>,
    );
  }
}

extension $AdminListLibraries200ResponseCopyWith
    on AdminListLibraries200Response {
  /// Returns a callable class that can be used as follows: `instanceOfAdminListLibraries200Response.copyWith(...)` or like so:`instanceOfAdminListLibraries200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminListLibraries200ResponseCWProxy get copyWith =>
      _$AdminListLibraries200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminListLibraries200Response _$AdminListLibraries200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminListLibraries200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = AdminListLibraries200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => AdminLibrary.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminListLibraries200ResponseToJson(
  AdminListLibraries200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
