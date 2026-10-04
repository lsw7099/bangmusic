// 로그 규칙 (05장 §9.2): Authorization·쿠키·mt·비밀번호를 남기지 않는다.
// 파일 경로는 서버 로그에만 남고 HTTP 응답에는 넣지 않는다.
import { destination, pino, type Logger } from 'pino';

/** URL의 쿼리에서 mt 값을 가린다. */
export function redactUrl(url: string): string {
  return url.replace(/([?&]mt=)[^&#]*/g, '$1<redacted>');
}

export function createLogger(level: string, file: string | null): Logger {
  return pino(
    {
      level,
      redact: {
        paths: [
          'req.headers.authorization', 'req.headers.cookie', 'headers.authorization', 'headers.cookie',
          '*.password', '*.new_password', '*.current_password', '*.refresh_token', '*.access_token', '*.ticket', '*.mt',
        ],
        censor: '<redacted>',
      },
      serializers: {
        req: (req: { method: string; url: string; id?: string }) => ({ method: req.method, url: redactUrl(req.url), id: req.id }),
        res: (res: { statusCode: number }) => ({ statusCode: res.statusCode }),
      },
    },
    file ? destination({ dest: file, sync: true, mkdir: true }) : destination(1),
  );
}

export type { Logger };
