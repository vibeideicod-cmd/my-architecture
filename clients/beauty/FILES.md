# FILES — карта папки clients/beauty/

Дата обновления: 2026-05-16

Beauty Визитка — внутренний продукт «Нейро Бабки СССР». Multi-tenant TMA + лендинг + Supabase backend для бьюти-мастеров.

## Источники правды

| Файл | Статус | Для чего |
|---|---|---|
| [CLAUDE.md](CLAUDE.md) | ⭐ источник правды | Контекст клиента и правила работы в папке |
| [PLAN.md](PLAN.md) | ⭐ источник правды | Текущая фаза и задачи |
| [brief.md](brief.md) | ⭐ источник правды | Чистый бриф продукта (35KB) |
| [SAAS-ARCHITECTURE.md](SAAS-ARCHITECTURE.md) | ⭐ источник правды | Архитектура multi-tenant SaaS v2 (3 роли, web-first) |
| [BACKEND-PLAN.md](BACKEND-PLAN.md) | ⭐ источник правды | Backend-план для Systems-агента (Supabase, deep links) |
| [project-log.md](project-log.md) | ⭐ источник правды | История работы и решений |

## Активные технические документы

| Файл | Статус | Для чего |
|---|---|---|
| [tma-roadmap.md](tma-roadmap.md) | активный | Дорожная карта разработки TMA |
| [tma-spec.md](tma-spec.md) | активный | Технические спеки для кодеров (45KB) |
| [research.md](research.md) | активный | Маркет-ресёрч (48KB) |

## Production-папки

| Папка | Статус | Что внутри |
|---|---|---|
| [tg-app/](tg-app/) | ✅ активный production | Telegram Mini App: `index.html`, `js/`, `css/`, `CLAUDE.md`, `TESTING.md` |
| [web/](web/) | ✅ активный production | Веб-страницы: `landing.html`, `apply.html`, `status.html` |
| [supabase/](supabase/) | ✅ активный production | Backend: миграции БД + README |

## Что использовать дальше

Для разработки TMA: `tma-spec.md` + `tma-roadmap.md` + `BACKEND-PLAN.md` + `tg-app/CLAUDE.md`.

Для бизнес-контекста: `brief.md` + `research.md` + `SAAS-ARCHITECTURE.md`.

Для деплоя: `tg-app/` + `web/` + `supabase/migrations/`.

## Связь с другими проектами

- Паттерн 3 ролей взят из [clients/mastergroup/](../mastergroup/) и адаптирован под бьюти-специфику (см. `SAAS-ARCHITECTURE.md`).
