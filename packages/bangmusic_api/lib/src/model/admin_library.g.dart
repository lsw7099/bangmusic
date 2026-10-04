// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_library.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminLibraryCWProxy {
  AdminLibrary id(String id);

  AdminLibrary name(String name);

  AdminLibrary status(AdminLibraryStatusEnum status);

  AdminLibrary trackCount(int? trackCount);

  AdminLibrary missingCount(int? missingCount);

  AdminLibrary lastScanAt(DateTime? lastScanAt);

  AdminLibrary pendingReview(bool? pendingReview);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminLibrary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminLibrary(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminLibrary call({
    String id,
    String name,
    AdminLibraryStatusEnum status,
    int? trackCount,
    int? missingCount,
    DateTime? lastScanAt,
    bool? pendingReview,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAdminLibrary.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAdminLibrary.copyWith.fieldName(...)`
class _$AdminLibraryCWProxyImpl implements _$AdminLibraryCWProxy {
  const _$AdminLibraryCWProxyImpl(this._value);

  final AdminLibrary _value;

  @override
  AdminLibrary id(String id) => this(id: id);

  @override
  AdminLibrary name(String name) => this(name: name);

  @override
  AdminLibrary status(AdminLibraryStatusEnum status) => this(status: status);

  @override
  AdminLibrary trackCount(int? trackCount) => this(trackCount: trackCount);

  @override
  AdminLibrary missingCount(int? missingCount) =>
      this(missingCount: missingCount);

  @override
  AdminLibrary lastScanAt(DateTime? lastScanAt) => this(lastScanAt: lastScanAt);

  @override
  AdminLibrary pendingReview(bool? pendingReview) =>
      this(pendingReview: pendingReview);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AdminLibrary(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AdminLibrary(...).copyWith(id: 12, name: "My name")
  /// ````
  AdminLibrary call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? trackCount = const $CopyWithPlaceholder(),
    Object? missingCount = const $CopyWithPlaceholder(),
    Object? lastScanAt = const $CopyWithPlaceholder(),
    Object? pendingReview = const $CopyWithPlaceholder(),
  }) {
    return AdminLibrary(
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
          : status as AdminLibraryStatusEnum,
      trackCount: trackCount == const $CopyWithPlaceholder()
          ? _value.trackCount
          // ignore: cast_nullable_to_non_nullable
          : trackCount as int?,
      missingCount: missingCount == const $CopyWithPlaceholder()
          ? _value.missingCount
          // ignore: cast_nullable_to_non_nullable
          : missingCount as int?,
      lastScanAt: lastScanAt == const $CopyWithPlaceholder()
          ? _value.lastScanAt
          // ignore: cast_nullable_to_non_nullable
          : lastScanAt as DateTime?,
      pendingReview: pendingReview == const $CopyWithPlaceholder()
          ? _value.pendingReview
          // ignore: cast_nullable_to_non_nullable
          : pendingReview as bool?,
    );
  }
}

extension $AdminLibraryCopyWith on AdminLibrary {
  /// Returns a callable class that can be used as follows: `instanceOfAdminLibrary.copyWith(...)` or like so:`instanceOfAdminLibrary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminLibraryCWProxy get copyWith => _$AdminLibraryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLibrary _$AdminLibraryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminLibrary',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['id', 'name', 'status']);
        final val = AdminLibrary(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(
              _$AdminLibraryStatusEnumEnumMap,
              v,
              unknownValue: AdminLibraryStatusEnum.unknownDefaultOpenApi,
            ),
          ),
          trackCount: $checkedConvert(
            'track_count',
            (v) => (v as num?)?.toInt(),
          ),
          missingCount: $checkedConvert(
            'missing_count',
            (v) => (v as num?)?.toInt(),
          ),
          lastScanAt: $checkedConvert(
            'last_scan_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          pendingReview: $checkedConvert('pending_review', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'trackCount': 'track_count',
        'missingCount': 'missing_count',
        'lastScanAt': 'last_scan_at',
        'pendingReview': 'pending_review',
      },
    );

Map<String, dynamic> _$AdminLibraryToJson(AdminLibrary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': _$AdminLibraryStatusEnumEnumMap[instance.status]!,
      'track_count': ?instance.trackCount,
      'missing_count': ?instance.missingCount,
      'last_scan_at': ?instance.lastScanAt?.toIso8601String(),
      'pending_review': ?instance.pendingReview,
    };

const _$AdminLibraryStatusEnumEnumMap = {
  AdminLibraryStatusEnum.online: 'online',
  AdminLibraryStatusEnum.unavailable: 'unavailable',
  AdminLibraryStatusEnum.unknownDefaultOpenApi: 'unknown_default_open_api',
};
