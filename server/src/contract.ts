// OpenAPI에서 생성한 타입을 서버 코드에 노출하는 진입점.
// 생성물(src/generated/)은 직접 고치지 않는다. npm run gen:server로 다시 만든다.
import type { components, operations, paths } from './generated/api.js';

export type Schemas = components['schemas'];
export type Operations = operations;
export type Paths = paths;
