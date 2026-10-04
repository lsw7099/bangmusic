//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:bangmusic_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'dart:typed_data';
import 'package:bangmusic_api/src/model/problem.dart';
import 'package:bangmusic_api/src/model/rendition.dart';
import 'package:bangmusic_api/src/model/rendition_request.dart';

class MediaApi {

  final Dio _dio;

  const MediaApi(this._dio);

  /// 오디오 바이트 (스트리밍과 다운로드 공용)
  /// 렌디션은 불변이다. 같은 ID는 항상 같은 바이트를 가리키며, 원본이 바뀌면 410이 된다. 따라서 이어받기에서 옛 바이트와 새 바이트가 섞일 수 없다. 단일 범위의 &#x60;Range&#x60;만 지원한다. 여러 범위를 요청하면 전체(200)를 돌려준다. 
  ///
  /// Parameters:
  /// * [renditionId] 
  /// * [range] 
  /// * [ifRange] - 렌디션의 ETag. 일치하지 않으면 200 전체 응답.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Uint8List] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Uint8List>> getMedia({ 
    required String renditionId,
    String? range,
    String? ifRange,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/media/{renditionId}'.replaceAll('{' r'renditionId' '}', renditionId.toString());
    final _options = Options(
      method: r'GET',
      responseType: ResponseType.bytes,
      headers: <String, dynamic>{
        if (range != null) r'Range': range,
        if (ifRange != null) r'If-Range': ifRange,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'mediaTicket',
            'keyName': 'mt',
            'where': 'query',
          },{
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    Uint8List? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : rawData as Uint8List;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Uint8List>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// 렌디션 상태 조회 및 미디어 티켓 재발급
  /// &#x60;preparing&#x60; 상태 폴링과, 티켓이 만료된 뒤 새 &#x60;media_url&#x60;을 받는 데 쓴다. 원본이 바뀌어 이 렌디션이 더 이상 유효하지 않으면 410 &#x60;rendition_superseded&#x60;. 
  ///
  /// Parameters:
  /// * [renditionId] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Rendition] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Rendition>> getRendition({ 
    required String renditionId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/renditions/{renditionId}'.replaceAll('{' r'renditionId' '}', renditionId.toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    Rendition? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<Rendition, Rendition>(rawData, 'Rendition', growable: true);

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Rendition>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// 길이·MIME·ETag 확인 (본문 없음)
  /// 
  ///
  /// Parameters:
  /// * [renditionId] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> headMedia({ 
    required String renditionId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/media/{renditionId}'.replaceAll('{' r'renditionId' '}', renditionId.toString());
    final _options = Options(
      method: r'HEAD',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'mediaTicket',
            'keyName': 'mt',
            'where': 'query',
          },{
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// 이 기기에서 재생/다운로드할 제공 형식 결정
  /// 앱이 재생 가능한 형식과 원하는 품질을 보내면 서버가 원본 제공 또는 변환을 결정한다. - 원본을 그대로 줄 수 있거나 변환본이 캐시에 있으면 200과 &#x60;state&#x3D;ready&#x60;. - 변환이 필요하면 작업을 대기열에 넣고 202와 &#x60;state&#x3D;preparing&#x60;, &#x60;Retry-After&#x60;.   앱은 &#x60;GET /renditions/{id}&#x60;를 폴링한다. 같은 요청을 반복해도 같은 렌디션이 나온다(멱등). 응답의 &#x60;media_url&#x60;은 서버 기준 상대 경로이며 &#x60;mt&#x60; 미디어 티켓이 포함되어 있어 플레이어·다운로더가 헤더 없이 요청할 수 있다. 
  ///
  /// Parameters:
  /// * [trackId] 
  /// * [renditionRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Rendition] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Rendition>> resolveRendition({ 
    required String trackId,
    required RenditionRequest renditionRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/tracks/{trackId}/renditions'.replaceAll('{' r'trackId' '}', trackId.toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(renditionRequest);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    Rendition? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<Rendition, Rendition>(rawData, 'Rendition', growable: true);

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Rendition>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
