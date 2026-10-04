import 'package:bangmusic_api/src/model/admin_create_user_request.dart';
import 'package:bangmusic_api/src/model/admin_library.dart';
import 'package:bangmusic_api/src/model/admin_list_libraries200_response.dart';
import 'package:bangmusic_api/src/model/admin_list_users200_response.dart';
import 'package:bangmusic_api/src/model/admin_update_user_request.dart';
import 'package:bangmusic_api/src/model/admin_user.dart';
import 'package:bangmusic_api/src/model/album.dart';
import 'package:bangmusic_api/src/model/album_detail.dart';
import 'package:bangmusic_api/src/model/album_page.dart';
import 'package:bangmusic_api/src/model/album_ref.dart';
import 'package:bangmusic_api/src/model/artist.dart';
import 'package:bangmusic_api/src/model/artist_page.dart';
import 'package:bangmusic_api/src/model/artist_ref.dart';
import 'package:bangmusic_api/src/model/change_batch.dart';
import 'package:bangmusic_api/src/model/change_batch_changes_inner.dart';
import 'package:bangmusic_api/src/model/change_password_request.dart';
import 'package:bangmusic_api/src/model/create_playlist_request.dart';
import 'package:bangmusic_api/src/model/delete_me_request.dart';
import 'package:bangmusic_api/src/model/device_info.dart';
import 'package:bangmusic_api/src/model/format_spec.dart';
import 'package:bangmusic_api/src/model/home.dart';
import 'package:bangmusic_api/src/model/job.dart';
import 'package:bangmusic_api/src/model/list_sessions200_response.dart';
import 'package:bangmusic_api/src/model/login_request.dart';
import 'package:bangmusic_api/src/model/lyrics.dart';
import 'package:bangmusic_api/src/model/lyrics_variant.dart';
import 'package:bangmusic_api/src/model/lyrics_variant_lines_inner.dart';
import 'package:bangmusic_api/src/model/lyrics_variant_source.dart';
import 'package:bangmusic_api/src/model/me.dart';
import 'package:bangmusic_api/src/model/me_all_of_libraries.dart';
import 'package:bangmusic_api/src/model/play_event.dart';
import 'package:bangmusic_api/src/model/play_event_context.dart';
import 'package:bangmusic_api/src/model/playlist.dart';
import 'package:bangmusic_api/src/model/playlist_edit.dart';
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner.dart';
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner_one_of.dart';
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner_one_of1.dart';
import 'package:bangmusic_api/src/model/playlist_edit_ops_inner_one_of2.dart';
import 'package:bangmusic_api/src/model/playlist_item.dart';
import 'package:bangmusic_api/src/model/playlist_item_page.dart';
import 'package:bangmusic_api/src/model/playlist_page.dart';
import 'package:bangmusic_api/src/model/post_play_events200_response.dart';
import 'package:bangmusic_api/src/model/post_play_events200_response_rejected_inner.dart';
import 'package:bangmusic_api/src/model/post_play_events_request.dart';
import 'package:bangmusic_api/src/model/problem.dart';
import 'package:bangmusic_api/src/model/problem_errors_inner.dart';
import 'package:bangmusic_api/src/model/put_lyrics_offset_request.dart';
import 'package:bangmusic_api/src/model/put_lyrics_variant_request.dart';
import 'package:bangmusic_api/src/model/refresh_token_request.dart';
import 'package:bangmusic_api/src/model/rendition.dart';
import 'package:bangmusic_api/src/model/rendition_request.dart';
import 'package:bangmusic_api/src/model/search_result.dart';
import 'package:bangmusic_api/src/model/server_info.dart';
import 'package:bangmusic_api/src/model/server_info_api.dart';
import 'package:bangmusic_api/src/model/session.dart';
import 'package:bangmusic_api/src/model/source_format.dart';
import 'package:bangmusic_api/src/model/token_response.dart';
import 'package:bangmusic_api/src/model/track.dart';
import 'package:bangmusic_api/src/model/track_page.dart';
import 'package:bangmusic_api/src/model/update_playlist_request.dart';
import 'package:bangmusic_api/src/model/user_summary.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'AdminCreateUserRequest':
          return AdminCreateUserRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminLibrary':
          return AdminLibrary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminListLibraries200Response':
          return AdminListLibraries200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminListUsers200Response':
          return AdminListUsers200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminUpdateUserRequest':
          return AdminUpdateUserRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminUser':
          return AdminUser.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Album':
          return Album.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlbumDetail':
          return AlbumDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlbumPage':
          return AlbumPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AlbumRef':
          return AlbumRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Artist':
          return Artist.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ArtistPage':
          return ArtistPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ArtistRef':
          return ArtistRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChangeBatch':
          return ChangeBatch.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChangeBatchChangesInner':
          return ChangeBatchChangesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChangePasswordRequest':
          return ChangePasswordRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatePlaylistRequest':
          return CreatePlaylistRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteMeRequest':
          return DeleteMeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceInfo':
          return DeviceInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FormatSpec':
          return FormatSpec.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Home':
          return Home.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Job':
          return Job.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListSessions200Response':
          return ListSessions200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LoginRequest':
          return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Lyrics':
          return Lyrics.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LyricsKind':
          
          
        case 'LyricsVariant':
          return LyricsVariant.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LyricsVariantLinesInner':
          return LyricsVariantLinesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LyricsVariantSource':
          return LyricsVariantSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Me':
          return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MeAllOfLibraries':
          return MeAllOfLibraries.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlayEvent':
          return PlayEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlayEventContext':
          return PlayEventContext.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Playlist':
          return Playlist.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistEdit':
          return PlaylistEdit.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistEditOpsInner':
          return PlaylistEditOpsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistEditOpsInnerOneOf':
          return PlaylistEditOpsInnerOneOf.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistEditOpsInnerOneOf1':
          return PlaylistEditOpsInnerOneOf1.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistEditOpsInnerOneOf2':
          return PlaylistEditOpsInnerOneOf2.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistItem':
          return PlaylistItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistItemPage':
          return PlaylistItemPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlaylistPage':
          return PlaylistPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PostPlayEvents200Response':
          return PostPlayEvents200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PostPlayEvents200ResponseRejectedInner':
          return PostPlayEvents200ResponseRejectedInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PostPlayEventsRequest':
          return PostPlayEventsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Problem':
          return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProblemErrorsInner':
          return ProblemErrorsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PutLyricsOffsetRequest':
          return PutLyricsOffsetRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PutLyricsVariantRequest':
          return PutLyricsVariantRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshTokenRequest':
          return RefreshTokenRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Rendition':
          return Rendition.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RenditionRequest':
          return RenditionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchResult':
          return SearchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ServerInfo':
          return ServerInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ServerInfoApi':
          return ServerInfoApi.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Session':
          return Session.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SourceFormat':
          return SourceFormat.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TokenResponse':
          return TokenResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Track':
          return Track.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TrackPage':
          return TrackPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePlaylistRequest':
          return UpdatePlaylistRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UserSummary':
          return UserSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }