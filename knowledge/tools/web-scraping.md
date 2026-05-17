# Получение веб-контента — иерархия инструментов

Когда нужен текст / структура / данные с веб-страницы — иди по этой иерархии от простого к сложному. Не превентивно усложняй — переходи на следующий уровень только когда текущий не справился.

## Уровень 1 — WebFetch (встроенный инструмент Claude Code)

**Когда подходит:**
- Статичные HTML-страницы
- API-эндпоинты с JSON-ответом
- RSS-ленты
- Документация

**Как:** просто `WebFetch <url> "что вытащить"` через мою встроенную команду.

**Когда не подходит:**
- Сайт рендерится через JavaScript (SPA — React/Vue/Next.js)
- Нужны заголовки авторизации с особыми требованиями
- Нужны сессионные cookies

## Уровень 2 — curl через Bash

**Когда подходит:**
- Нужны headers (User-Agent, Authorization)
- Нужна аутентификация (Bearer-токен, basic auth)
- Нужен конкретный HTTP-метод (POST/PUT/DELETE)
- Нужно сохранить ответ как файл

**Как:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
     -H "User-Agent: Mozilla/5.0" \
     "https://api.example.com/data" \
     -o /tmp/response.json
```

**Связка с api-patterns.md:** все наши API-сервисы (Telegram, Supabase, Anthropic, и т.д.) — в [knowledge/tools/api-patterns.md](api-patterns.md) с готовыми curl-примерами.

## Уровень 3 — Google Docs / Sheets export URL (критический трюк)

**Когда подходит:**
- Инна или клиент дал ссылку на Google Doc / Sheet / Slides
- Нужен текст / данные / структура из документа

**Почему не WebFetch:** Google Docs страница — это JavaScript-приложение, WebFetch вернёт пустой HTML без содержимого.

**Решение — export URL:**

```
# Google Docs → HTML (предпочтительно — сохраняет структуру)
https://docs.google.com/document/d/<DOC_ID>/export?format=html

# Google Docs → TXT (только plain text, без форматирования)
https://docs.google.com/document/d/<DOC_ID>/export?format=txt

# Google Sheets → CSV
https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=csv

# Google Sheets → конкретный лист (gid)
https://docs.google.com/spreadsheets/d/<SHEET_ID>/export?format=csv&gid=<GID>

# Google Slides → PDF
https://docs.google.com/presentation/d/<PRESENTATION_ID>/export?format=pdf

# Где взять <ID>:
# https://docs.google.com/document/d/[ВОТ ЭТА СТРОКА]/edit
```

**Через WebFetch:** просто подсунь export-URL вместо обычной ссылки на документ.

**Условие:** документ должен быть открыт «по ссылке кто угодно может смотреть» — если приватный, экспорт не сработает.

**Применение у нас:** документы Инны в Google Drive, материалы клиентов в Google Docs, таблицы клиентов в Sheets. Каждый раз когда в чате появляется `docs.google.com/...` ссылка — иди через export URL, не через основную страницу.

## Уровень 4 — Playwright (headless браузер)

**Когда подходит:**
- Сайт через JavaScript-рендеринг (React/Vue/Next.js без SSR)
- Нужны скриншоты страниц для дизайн-аудита
- Нужно эмулировать действия пользователя (клик, скролл, форма)

**Когда устанавливать:** только при первом реальном случае с SPA-сайтом клиента/конкурента, не превентивно. Установка:
```bash
npx playwright install chromium
```

**Как использовать:** через Bash + Node.js скрипт. Сложнее предыдущих уровней — переходи только когда WebFetch и curl не справились.

## Уровень 5 — Supadata MCP (когда регулярно)

**Когда подходит:**
- Скиллы `/competitor-research`, `/digital-audit` начнут регулярно работать с сайтами клиентов
- Нужен карты-сайт целиком (`supadata_map`) или серия страниц (`supadata_crawl`)
- Нужен markdown из веб-страницы (`supadata_scrape`) с очисткой от шума

**Сейчас не подключён.** Подключение — через `/settings → 🔑` в Claude Code, после чего MCP-tools `supadata_*` становятся доступны.

**Стоимость:** Free 100 credits/мес, 1 req/sec. Платный $5+/мес.

## Принцип выбора

```
Статичный HTML / API / RSS → Уровень 1 (WebFetch)
Нужна аутентификация / headers → Уровень 2 (curl)
Google Docs / Sheets / Slides → Уровень 3 (export URL — обязательно!)
SPA-сайт через JS → Уровень 4 (Playwright)
Регулярная работа с веб-аналитикой → Уровень 5 (Supadata MCP)
```

## Связки

- [knowledge/tools/api-patterns.md](api-patterns.md) — паттерны аутентификации для curl-запросов к нашим API
- [agents/analyst.md](../../agents/analyst.md) — Research Фазы 2 (анализ сайтов конкурентов через WebFetch / Google Docs)
- [agents/analytics-rukovoditel.md](../../agents/analytics-rukovoditel.md) — стратегическая аналитика трендов (включая видео — см. [video-transcripts.md](../methodology/video-transcripts.md))
- [agents/audience-researcher.md](../../agents/audience-researcher.md) — исследование ЦА в открытых источниках (форумы, Reddit, отзывы)
- `.claude/skills/digital-audit/SKILL.md` — анализ цифрового присутствия клиента
- `.claude/skills/competitor-research/SKILL.md` — анализ конкурентов
