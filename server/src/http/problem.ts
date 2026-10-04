// RFC 9457 problem+json 오류 (02장 §6). detail에는 경로·SQL·스택을 넣지 않는다.

export const STATUS_TITLES: Record<number, string> = {
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  409: 'Conflict',
  410: 'Gone',
  412: 'Precondition Failed',
  413: 'Payload Too Large',
  415: 'Unsupported Media Type',
  416: 'Range Not Satisfiable',
  422: 'Unprocessable Content',
  426: 'Upgrade Required',
  428: 'Precondition Required',
  429: 'Too Many Requests',
  500: 'Internal Server Error',
  503: 'Service Unavailable',
};

const DETAILS: Record<string, string> = {
  validation_failed: '요청 형식이 올바르지 않습니다.',
  invalid_credentials: '사용자 이름 또는 비밀번호가 올바르지 않습니다.',
  access_expired: '액세스 토큰이 만료되었습니다.',
  access_invalid: '액세스 토큰이 올바르지 않습니다.',
  refresh_expired: '세션이 만료되었습니다. 다시 로그인하세요.',
  session_revoked: '세션이 취소되었습니다. 다시 로그인하세요.',
  account_disabled: '계정이 비활성화되었습니다.',
  ticket_expired: '미디어 티켓이 만료되었습니다.',
  ticket_invalid: '미디어 티켓이 올바르지 않습니다.',
  forbidden: '관리자 권한이 필요합니다.',
  not_found: '찾을 수 없습니다.',
  media_missing: '서버에 원본 파일이 없습니다.',
  username_taken: '이미 사용 중인 사용자 이름입니다.',
  last_admin: '마지막 관리자 계정은 변경하거나 삭제할 수 없습니다.',
  rendition_superseded: '원본이 바뀌었습니다. 다시 요청하세요.',
  sync_token_expired: '동기화 기준점이 너무 오래되었습니다. 전체 동기화가 필요합니다.',
  range_not_satisfiable: '요청한 범위가 파일 길이를 벗어났습니다.',
  no_playable_format: '이 기기에서 재생할 수 있는 형식이 없습니다.',
  client_too_old: '앱을 업데이트해야 이 서버에 연결할 수 있습니다.',
  rate_limited: '요청이 너무 많습니다. 잠시 후 다시 시도하세요.',
  internal_error: '서버 내부 오류가 발생했습니다.',
  storage_unavailable: '서버의 음악 저장소에 연결할 수 없습니다.',
  setup_required: '서버 초기 설정이 완료되지 않았습니다.',
  maintenance: '서버 점검 중입니다.',
};

const RETRYABLE = new Set(['access_expired', 'access_invalid', 'ticket_expired', 'ticket_invalid', 'rate_limited', 'storage_unavailable', 'maintenance', 'internal_error', 'rendition_superseded']);

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly headers: Record<string, string>;
  readonly errors: { field: string; message: string }[] | undefined;

  constructor(status: number, code: string, opts: { headers?: Record<string, string>; errors?: { field: string; message: string }[] } = {}) {
    super(code);
    this.status = status;
    this.code = code;
    this.headers = opts.headers ?? {};
    this.errors = opts.errors;
  }
}

export function problemBody(status: number, code: string, requestId: string, errors?: { field: string; message: string }[]) {
  return {
    type: 'about:blank',
    title: STATUS_TITLES[status] ?? 'Error',
    status,
    code,
    detail: DETAILS[code] ?? STATUS_TITLES[status] ?? '오류',
    request_id: requestId,
    retryable: RETRYABLE.has(code),
    ...(errors && errors.length ? { errors } : {}),
  };
}

export const notFound = () => new ApiError(404, 'not_found');
export const badRequest = (field: string, message: string) =>
  new ApiError(400, 'validation_failed', { errors: [{ field, message }] });
