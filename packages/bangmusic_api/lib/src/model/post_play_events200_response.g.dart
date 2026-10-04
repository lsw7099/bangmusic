// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_play_events200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PostPlayEvents200ResponseCWProxy {
  PostPlayEvents200Response accepted(int accepted);

  PostPlayEvents200Response duplicates(int duplicates);

  PostPlayEvents200Response rejected(
    List<PostPlayEvents200ResponseRejectedInner> rejected,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostPlayEvents200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostPlayEvents200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  PostPlayEvents200Response call({
    int accepted,
    int duplicates,
    List<PostPlayEvents200ResponseRejectedInner> rejected,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPostPlayEvents200Response.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPostPlayEvents200Response.copyWith.fieldName(...)`
class _$PostPlayEvents200ResponseCWProxyImpl
    implements _$PostPlayEvents200ResponseCWProxy {
  const _$PostPlayEvents200ResponseCWProxyImpl(this._value);

  final PostPlayEvents200Response _value;

  @override
  PostPlayEvents200Response accepted(int accepted) => this(accepted: accepted);

  @override
  PostPlayEvents200Response duplicates(int duplicates) =>
      this(duplicates: duplicates);

  @override
  PostPlayEvents200Response rejected(
    List<PostPlayEvents200ResponseRejectedInner> rejected,
  ) => this(rejected: rejected);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostPlayEvents200Response(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostPlayEvents200Response(...).copyWith(id: 12, name: "My name")
  /// ````
  PostPlayEvents200Response call({
    Object? accepted = const $CopyWithPlaceholder(),
    Object? duplicates = const $CopyWithPlaceholder(),
    Object? rejected = const $CopyWithPlaceholder(),
  }) {
    return PostPlayEvents200Response(
      accepted: accepted == const $CopyWithPlaceholder()
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as int,
      duplicates: duplicates == const $CopyWithPlaceholder()
          ? _value.duplicates
          // ignore: cast_nullable_to_non_nullable
          : duplicates as int,
      rejected: rejected == const $CopyWithPlaceholder()
          ? _value.rejected
          // ignore: cast_nullable_to_non_nullable
          : rejected as List<PostPlayEvents200ResponseRejectedInner>,
    );
  }
}

extension $PostPlayEvents200ResponseCopyWith on PostPlayEvents200Response {
  /// Returns a callable class that can be used as follows: `instanceOfPostPlayEvents200Response.copyWith(...)` or like so:`instanceOfPostPlayEvents200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PostPlayEvents200ResponseCWProxy get copyWith =>
      _$PostPlayEvents200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostPlayEvents200Response _$PostPlayEvents200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PostPlayEvents200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['accepted', 'duplicates', 'rejected']);
  final val = PostPlayEvents200Response(
    accepted: $checkedConvert('accepted', (v) => (v as num).toInt()),
    duplicates: $checkedConvert('duplicates', (v) => (v as num).toInt()),
    rejected: $checkedConvert(
      'rejected',
      (v) => (v as List<dynamic>)
          .map(
            (e) => PostPlayEvents200ResponseRejectedInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PostPlayEvents200ResponseToJson(
  PostPlayEvents200Response instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'duplicates': instance.duplicates,
  'rejected': instance.rejected.map((e) => e.toJson()).toList(),
};
