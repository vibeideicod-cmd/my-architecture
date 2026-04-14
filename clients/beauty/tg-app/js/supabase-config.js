// ============================================================
// supabase-config.js — конфиг подключения TMA к Supabase
// ============================================================
//
// Здесь лежат публичные параметры подключения к базе.
// Publishable key БЕЗОПАСНО держать в коде — он публичный
// по дизайну Supabase. Реальная защита данных — на стороне
// Row Level Security (RLS), который мы настроили миграцией 002.
//
// Инициализация SDK происходит после загрузки CDN-скрипта
// supabase-js (см. index.html — он подключается ДО этого файла).
// ============================================================

const BeautyDB = (() => {
  const SUPABASE_URL = 'https://qwoepdibvmwqgkkaabba.supabase.co';
  const SUPABASE_PUBLISHABLE_KEY =
    'sb_publishable_cbbjRN4EskeHOHy6pSCYLg_RCSH32fY';

  // ID мастера по умолчанию.
  // Когда подключим self-serve (Вариант Б) — будем читать из
  // tg.initDataUnsafe.start_param (deep link `?startapp=anna`).
  const DEFAULT_MASTER_ID = 'anna';

  // window.supabase появляется из CDN-скрипта в index.html
  if (typeof window === 'undefined' || !window.supabase) {
    console.error('[BeautyDB] supabase-js не загружен. Проверь <script> в index.html');
    return { client: null, MASTER_ID: DEFAULT_MASTER_ID };
  }

  const client = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY,
    {
      auth: { persistSession: false }, // у клиентов нет сессии
    }
  );

  // Master id из deep link, если есть, иначе дефолтный.
  function resolveMasterId() {
    try {
      const tg = window.Telegram?.WebApp;
      const fromTg = tg?.initDataUnsafe?.start_param;
      if (fromTg) return fromTg;
    } catch {}
    const url = new URL(window.location.href);
    return url.searchParams.get('master') || DEFAULT_MASTER_ID;
  }

  return {
    client,
    MASTER_ID: resolveMasterId(),
  };
})();
