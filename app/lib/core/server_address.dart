// 서버 주소 입력 정규화 (04장 S1). 스킴이 없으면 https://를 붙인다. http://는 릴리스에서 거부.

sealed class AddressResult {
  const AddressResult();
}

class AddressOk extends AddressResult {
  const AddressOk(this.baseUrl);

  /// 예: https://music.example.net (끝에 / 없음, /v1 없음)
  final String baseUrl;
}

class AddressError extends AddressResult {
  const AddressError(this.message);
  final String message;
}

AddressResult normalizeServerAddress(String input, {required bool allowCleartext}) {
  var s = input.trim();
  if (s.isEmpty) return const AddressError('서버 주소를 입력하세요.');
  if (!s.contains('://')) s = 'https://$s';
  final uri = Uri.tryParse(s);
  if (uri == null || uri.host.isEmpty) return const AddressError('주소 형식이 올바르지 않습니다.');
  if (uri.scheme == 'http' && !allowCleartext) {
    return const AddressError('보안 연결(HTTPS)만 지원합니다. 서버에 HTTPS를 설정하세요.');
  }
  if (uri.scheme != 'https' && uri.scheme != 'http') return const AddressError('https:// 주소만 쓸 수 있습니다.');
  if (uri.userInfo.isNotEmpty) return const AddressError('주소에 사용자 정보를 넣지 마세요.');
  var path = uri.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  if (path.endsWith('/v1')) path = path.substring(0, path.length - 3);
  final base = Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null, path: path).toString();
  return AddressOk(base);
}
