# FILES — карта папки clients/yuzhnoberezhniy/

Дата обновления: 2026-05-16

Санаторий «Южнобережный» (ГБУ РК СДДР) — коммерческий клиент. Пакет цифровых инструментов: лендинг, квиз, бот лидогенерации, TMA.

## Источники правды

| Файл | Статус | Для чего |
|---|---|---|
| [CLAUDE.md](CLAUDE.md) | ⭐ источник правды | Контекст клиента и правила работы в папке |
| [PLAN.md](PLAN.md) | ⭐ источник правды | Текущая фаза и задачи |
| [brief.md](brief.md) | ⭐ источник правды | Чистый бриф клиента |
| [brand.md](brand.md) | ⭐ источник правды | Бренд-стандарты ЮБ (палитра, шрифты, тон) |
| [project-log.md](project-log.md) | ⭐ источник правды | История работы и решений |

## Production-папки

| Папка | Статус | Что внутри |
|---|---|---|
| [mvp/](mvp/) | ✅ активный production | Веб-инструменты: `index.html`, `offer.html`, `quiz.html`, `feedback.html`, `ryukzak.html`, `tour.html` + `hero.png`, `logo.png` |
| [tg-app/](tg-app/) | ✅ активный production | Telegram Mini App: `index.html` + `CLAUDE.md` |
| [bot/](bot/) | ⚠️ production-like | `webhook.php` — серверный код бота. Изменения только через `/superpowers` full + DevOps/Infra |

## Что использовать дальше

Для развития продукта: `PLAN.md` + `brief.md` + `brand.md`.

Для правок бота: `bot/webhook.php` через Superpowers full (это production-код, осторожный режим).

Для правок MVP-страниц: соответствующий `.html` в `mvp/` через Superpowers mini (или просто smoke test для статики).

## Контур работы

**Коммерческий клиент** (Контур 3). Платный проект, любые изменения в production-коде требуют QA до деплоя.
