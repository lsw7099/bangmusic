// 앱 통합 테스트용 로컬 서버 (L1, 05장 §9.4): 합성 음원으로 서버를 띄우고 첫 줄에 접속 정보를 JSON으로 출력한다.
// 테스트 계정은 server/test/helpers.ts의 시험용 값이다(실제 비밀번호가 아니다). 표준 입력이 닫히면 정리하고 끝난다.
//   node tools/e2e/app-test-server.mts
import { MEMBER, setup } from '../../server/test/helpers.ts';

const env = await setup();
await env.app.listen({ host: '127.0.0.1', port: 0 });
const addr = env.app.server.address();
if (addr === null || typeof addr === 'string') throw new Error('주소를 알 수 없음');
console.log(JSON.stringify({ base_url: `http://127.0.0.1:${addr.port}`, username: MEMBER.username, password: MEMBER.password }));

let closing = false;
async function stop() {
  if (closing) return;
  closing = true;
  await env.close();
  process.exit(0);
}
process.stdin.on('end', stop);
process.stdin.on('close', stop);
process.stdin.resume();
process.on('SIGTERM', stop);
process.on('SIGINT', stop);
