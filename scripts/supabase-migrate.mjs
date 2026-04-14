// ============================================================
// supabase-migrate.mjs — запуск SQL-миграций в Supabase.
// Читает .env в корне репо, подключается к Postgres по SUPABASE_DB_URL
// и по очереди выполняет все файлы из clients/beauty/supabase/migrations/.
// ============================================================

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const __dirname  = path.dirname(fileURLToPath(import.meta.url));
const repoRoot   = path.resolve(__dirname, '..');
const envPath    = path.join(repoRoot, '.env');

// ── Какого клиента мигрируем ───────────────────────────
// По умолчанию beauty (исторически). Можно явно указать:
//   node scripts/supabase-migrate.mjs --client mastergroup
const clientArgIdx = process.argv.indexOf('--client');
const clientName = clientArgIdx !== -1 ? process.argv[clientArgIdx + 1] : 'beauty';
const migrations = path.join(repoRoot, `clients/${clientName}/supabase/migrations`);
console.log(`→ Клиент: ${clientName}`);

// ── Читаем .env без внешних зависимостей ───────────────
function loadEnv(file) {
  const out = {};
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

const env = loadEnv(envPath);
const dbUrl = env.SUPABASE_DB_URL;

if (!dbUrl || dbUrl.includes('[YOUR-PASSWORD]')) {
  console.error('❌ SUPABASE_DB_URL не заполнен или содержит [YOUR-PASSWORD].');
  process.exit(1);
}

// ── Парсим URL вручную, чтобы спецсимволы в пароле не ломали pg ──
let config;
try {
  const u = new URL(dbUrl);
  config = {
    host:     u.hostname,
    port:     parseInt(u.port || '5432'),
    user:     decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    database: u.pathname.replace(/^\//, '') || 'postgres',
    ssl:      { rejectUnauthorized: false },
  };
} catch (e) {
  console.error('❌ Не могу распарсить SUPABASE_DB_URL:', e.message);
  process.exit(1);
}

console.log(`→ Подключаюсь к ${config.host}:${config.port} / ${config.database} (пользователь ${config.user})`);

const client = new pg.Client(config);

try {
  await client.connect();
  console.log('✓ Соединение установлено');
} catch (e) {
  console.error('❌ Не удалось подключиться:', e.message);
  if (e.code === 'ENETUNREACH' || /ipv6|EHOSTUNREACH/i.test(e.message)) {
    console.error('');
    console.error('Подсказка: прямой db.*.supabase.co доступен только по IPv6.');
    console.error('Открой Supabase → Project Settings → Database → Connection pooling,');
    console.error('скопируй строку из раздела "Transaction" и положи её в .env как SUPABASE_DB_URL.');
    console.error('Это даст IPv4-совместимый pooler.');
  }
  process.exit(1);
}

// ── Таблица учёта применённых миграций ─────────────────
// Без неё каждый запуск пытается прогнать все .sql заново
// и идемпотентные миграции прокатывают, а сиды — падают.
await client.query(`
  create table if not exists schema_migrations (
    filename   text primary key,
    applied_at timestamptz default now()
  )
`);

const appliedRes = await client.query('select filename from schema_migrations');
const applied = new Set(appliedRes.rows.map(r => r.filename));

// ── Запускаем миграции по очереди ──────────────────────
const files = fs.readdirSync(migrations)
  .filter(f => f.endsWith('.sql'))
  .sort();

if (files.length === 0) {
  console.error(`❌ Нет .sql файлов в ${migrations}`);
  process.exit(1);
}

let ok = 0;
let skipped = 0;
let failed = false;

for (const file of files) {
  if (applied.has(file)) {
    console.log(`→ ${file} … (уже применён, пропускаю)`);
    skipped++;
    continue;
  }
  const full = path.join(migrations, file);
  const sql  = fs.readFileSync(full, 'utf8');
  process.stdout.write(`→ ${file} … `);
  try {
    await client.query('begin');
    await client.query(sql);
    await client.query(
      'insert into schema_migrations(filename) values($1)',
      [file]
    );
    await client.query('commit');
    console.log('✓');
    ok++;
  } catch (e) {
    await client.query('rollback').catch(() => {});
    console.log('❌');
    console.error(`   ${e.message}`);
    if (e.detail) console.error(`   detail: ${e.detail}`);
    if (e.hint)   console.error(`   hint:   ${e.hint}`);
    failed = true;
    break;
  }
}

// ── Быстрая проверка: что в базе есть ──────────────────
if (!failed) {
  console.log('');
  console.log('── Проверка содержимого ──');
  const checksByClient = {
    beauty: [
      { label: 'мастера',     sql: 'select count(*)::int as n from masters' },
      { label: 'категории',   sql: 'select count(*)::int as n from categories' },
      { label: 'услуги',      sql: 'select count(*)::int as n from services' },
      { label: 'расписание',  sql: 'select count(*)::int as n from schedules' },
      { label: 'брони',       sql: 'select count(*)::int as n from bookings' },
    ],
    mastergroup: [
      { label: 'мастера МГ',  sql: 'select count(*)::int as n from mg_masters' },
      { label: 'участники',   sql: 'select count(*)::int as n from mg_participants' },
      { label: 'материалы',   sql: 'select count(*)::int as n from mg_materials' },
      { label: 'задания',     sql: 'select count(*)::int as n from mg_tasks' },
      { label: 'сообщения',   sql: 'select count(*)::int as n from mg_messages' },
      { label: 'кейсы',       sql: 'select count(*)::int as n from mg_cases' },
    ],
  };
  const checks = checksByClient[clientName] || [];
  for (const c of checks) {
    try {
      const r = await client.query(c.sql);
      console.log(`  ${c.label.padEnd(12)} ${r.rows[0].n}`);
    } catch (e) {
      console.log(`  ${c.label.padEnd(12)} ошибка: ${e.message}`);
    }
  }
}

await client.end();

if (failed) {
  console.log('');
  console.log(`⚠ Остановлено после ${ok} миграций. Исправь ошибку и запусти снова.`);
  process.exit(1);
}

console.log('');
console.log(`✓ Все ${ok} миграций применены.`);
