// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_all_of_libraries.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MeAllOfLibrariesCWProxy {
  MeAllOfLibraries id(String id);

  MeAllOfLibraries name(String name);

  MeAllOfLibraries status(MeAllOfLibrariesStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeAllOfLibraries(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeAllOfLibraries(...).copyWith(id: 12, name: "My name")
  /// ````
  MeAllOfLibraries call({
    String id,
    String name,
    MeAllOfLibrariesStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMeAllOfLibraries.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMeAllOfLibraries.copyWith.fieldName(...)`
class _$MeAllOfLibrariesCWProxyImpl implements _$MeAllOfLibrariesCWProxy {
  const _$MeAllOfLibrariesCWProxyImpl(this._value);

  final MeAllOfLibraries _value;

  @override
  MeAllOfLibraries id(String id) => this(id: id);

  @override
  MeAllOfLibraries name(String name) => this(name: name);

  @override
  MeAllOfLibraries status(MeAllOfLibrariesStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MeAllOfLibraries(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MeAllOfLibraries(...).copyWith(id: 12, name: "My name")
  /// ````
  MeAllOfLibraries call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return MeAllOfLibraries(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as MeAllOfLibrariesStatusEnum,
    );
  }
}

extension $MeAllOfLibrariesCopyWith on MeAllOfLibraries {
  /// Returns a callable class that can be used as follows: `instanceOfMeAllOfLibraries.copyWith(...)` or like so:`instanceOfMeAllOfLibraries.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MeAllOfLibrariesCWProxy get copyWith => _$MeAllOfLibrariesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeAllOfLibraries _$MeAllOfLibrariesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MeAllOfLibraries', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'status']);
      final val = MeAllOfLibraries(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(
            _$MeAllOfLibrariesStatusEnumEnumMap,
            v,
            unknownValue: MeAllOfLibrariesStatusEnum.unknownDefaultOpenApi,
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MeAllOfLibrariesToJson(MeAllOfLibraries instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': _$MeAllOfLibrariesStatusEnumEnumMap[instance.status]!,
    };

const _$MeAllOfLibrariesStatusEnumEnumMap = {
  MeAllOfLibrariesStatusEnum.online: 'online',
  MeAllOfLibrariesStatusEnum.unavailable: 'unavailable',
  MeAllOfLibrariesStatusEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
