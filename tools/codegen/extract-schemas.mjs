// openapi.yaml의 components.schemas를 서버(Fastify) 검증용 JSON으로 뽑아낸다.
// 각 스키마에 $id를 붙이고 내부 참조를 "<Name>#" 형태로 바꿔
// fastify.addSchema()로 등록한 뒤 { $ref: 'Track#' }처럼 쓸 수 있게 한다.
// 출력: server/src/generated/schemas.json (손으로 고치지 않는다)
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse } from 'yaml';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const specPath = resolve(root, 'docs/design/openapi.yaml');
const outPath = resolve(root, 'server/src/generated/schemas.json');

const spec = parse(readFileSync(specPath, 'utf8'));
const schemas = spec?.components?.schemas;
if (!schemas || typeof schemas !== 'object') {
  throw new Error('components.schemas가 없다');
}

const REF_PREFIX = '#/components/schemas/';

function rewriteRefs(node) {
  if (Array.isArray(node)) return node.map(rewriteRefs);
  if (node && typeof node === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(node)) {
      if (k === '$ref' && typeof v === 'string') {
        if (!v.startsWith(REF_PREFIX)) {
          throw new Error(`스키마 밖을 가리키는 참조는 지원하지 않는다: ${v}`);
        }
        out.$ref = `${v.slice(REF_PREFIX.length)}#`;
      } else {
        out[k] = rewriteRefs(v);
      }
    }
    return out;
  }
  return node;
}

const result = Object.keys(schemas)
  .sort()
  .map((name) => ({ $id: name, ...rewriteRefs(schemas[name]) }));

// 참조 대상이 모두 존재하는지 확인한다.
const names = new Set(Object.keys(schemas));
const text = JSON.stringify(result);
for (const m of text.matchAll(/"\$ref":"([^"#]+)#"/g)) {
  if (!names.has(m[1])) throw new Error(`없는 스키마 참조: ${m[1]}`);
}

// 동작별 요청 스키마. 서버가 라우트를 등록할 때 이 값으로 검증한다(계약과 구현의 스키마를 한 곳에서 관리).
const METHODS = ['get', 'head', 'post', 'put', 'patch', 'delete'];
const PARAM_PREFIX = '#/components/parameters/';
function resolveParam(p) {
  if (!p.$ref) return p;
  const name = p.$ref.slice(PARAM_PREFIX.length);
  const found = spec.components.parameters?.[name];
  if (!found) throw new Error(`없는 매개변수 참조: ${p.$ref}`);
  return found;
}
function objectSchema(params) {
  if (params.length === 0) return null;
  const properties = {};
  const required = [];
  for (const p of params) {
    const key = p.in === 'header' ? p.name.toLowerCase() : p.name;
    properties[key] = rewriteRefs(p.schema ?? {});
    if (p.required) required.push(key);
  }
  return { type: 'object', properties, ...(required.length ? { required } : {}) };
}
const operations = [];
for (const [path, item] of Object.entries(spec.paths)) {
  const common = item.parameters ?? [];
  for (const method of METHODS) {
    const op = item[method];
    if (!op) continue;
    const params = [...common, ...(op.parameters ?? [])].map(resolveParam);
    const json = op.requestBody?.content?.['application/json']?.schema;
    operations.push({
      operationId: op.operationId,
      method: method.toUpperCase(),
      path: `/v1${path}`,
      url: `/v1${path.replace(/\{(\w+)\}/g, ':$1')}`,
      security: (op.security ?? spec.security ?? []).flatMap((s) => Object.keys(s)),
      params: objectSchema(params.filter((p) => p.in === 'path')),
      querystring: objectSchema(params.filter((p) => p.in === 'query')),
      headers: objectSchema(params.filter((p) => p.in === 'header')),
      body: json ? rewriteRefs(json) : null,
      body_required: Boolean(op.requestBody?.required),
      responses: Object.keys(op.responses ?? {}),
    });
  }
}
const opText = JSON.stringify(operations);
for (const m of opText.matchAll(/"\$ref":"([^"#]+)#"/g)) {
  if (!names.has(m[1])) throw new Error(`없는 스키마 참조: ${m[1]}`);
}

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(
  outPath,
  JSON.stringify(
    {
      $comment: 'docs/design/openapi.yaml에서 생성. 직접 수정 금지. npm run gen:server',
      openapi_version: spec.info?.version,
      schemas: result,
      operations,
    },
    null,
    2,
  ) + '\n',
);
console.log(`schemas.json: 스키마 ${result.length}개, 동작 ${operations.length}개`);
