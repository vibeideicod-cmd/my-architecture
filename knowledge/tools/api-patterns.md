# API-паттерны под наш стек

Справочник по аутентификации и работе с внешними API. Под наш конкретный набор сервисов: AI-провайдеры, Telegram, Beget, Supabase, российские платёжки и облака.

Дополняет:
- [agents/director.md](../../agents/director.md) — раздел «Работа с секретами»
- [agents/devops-infra.md](../../agents/devops-infra.md) — раздел «Управление ключами на серверах»

## Универсальные правила

- **Проверка наличия переменной:** `printenv ИМЯ` (без вывода значения в чат). НЕ используй `echo $VAR | grep ...` — pipe всегда возвращает пустоту, переменная при этом реально работает
- **Никогда не цитируй значения** ключей в чате, коммитах или auto-memory
- **Где у нас лежат env vars:**
  - Серверный `.env` (Cheerful Marik / Model Zarek): `/home/<user>/<project>/.env` chmod 600
  - Связка ключей macOS на маке Инны: `security find-generic-password -a <name> -w`
  - `.claude/settings.json` (для ключей Claude Code)
  - Beget shared: переменные через панель cp.beget.com → Настройки сайта

## Коды ответов — расшифровка

- **401 Unauthorized** — ключ неверный или истёк. Сначала проверь `printenv`, потом перевыпусти
- **403 Forbidden** — ключ есть, но прав не хватает. Проверь скоупы токена (особенно для GitHub Fine-grained)
- **429 Too Many Requests** — rate limit. **Критично для Telegram** — может быть блокировка на 14+ часов (см. правило «один токен = один процесс» в [agents/systems.md](../../agents/systems.md))
- **5xx** — проблема на стороне сервиса, повтор через 30 сек

## Сервисы

### Anthropic (Claude API)

- **Где взять:** `console.anthropic.com` → Settings → API Keys
- **Стоимость:** pay-as-you-go, кредиты прибавляются на счёт. Sonnet 4.6 ~$3/1M input
- **Куда у нас:** `.claude/settings.json` (для Claude Code) + серверный `.env` для AI-консультантов клиентов (`ANTHROPIC_API_KEY`)
- **curl-пример:**
  ```bash
  curl https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-sonnet-4-6","max_tokens":1024,"messages":[{"role":"user","content":"Привет"}]}'
  ```

### OpenAI (запасной AI-провайдер)

- **Где взять:** `platform.openai.com` → API Keys
- **Стоимость:** pay-as-you-go, GPT-4o ~$2.50/1M input
- **Куда у нас:** серверный `.env` (`OPENAI_API_KEY`) только для конкретных задач где Claude не подходит
- **Заголовок:** `Authorization: Bearer $OPENAI_API_KEY`

### Telegram Bot API

- **Где взять:** `@BotFather` в Telegram → `/newbot` → получаешь токен формата `<bot_id>:<secret>`
- **Стоимость:** бесплатно
- **Куда у нас:** серверный `.env` ботов на Cheerful Marik / Model Zarek (`BOT_TOKEN`)
- **URL базовый:** `https://api.telegram.org/bot$BOT_TOKEN/<method>`
- **Проверка живости бота:**
  ```bash
  curl https://api.telegram.org/bot$BOT_TOKEN/getMe
  ```
- **КРИТИЧНО:** один токен = один процесс. Запуск второго процесса с тем же токеном → блокировка на 14+ часов с 429. См. [agents/systems.md](../../agents/systems.md) раздел «Перед запуском бота — `ps aux`»

### Supabase

- **Где взять:** `supabase.com` → Project → Settings → API. У каждого проекта 4 ключа
- **Стоимость:** Free tier 500 МБ БД + 1 ГБ Storage + 50K MAU
- **4 ключа:**
  - `SUPABASE_URL` — публичный URL проекта
  - `SUPABASE_ANON_KEY` — для клиентского кода (RLS защищает)
  - `SUPABASE_SERVICE_KEY` — серверный ключ (всё может, в .env только)
  - `SUPABASE_ACCESS_TOKEN` — для CLI и миграций
- **Куда у нас:** серверный `.env` бэкенда + клиентский `.env.example` для anon key
- **PostgREST-фильтры (curl):**
  ```bash
  # eq, neq, gt, gte, lt, lte
  curl "$SUPABASE_URL/rest/v1/clients?status=eq.active&age=gt.18" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY"

  # like (поиск подстроки)
  curl "$SUPABASE_URL/rest/v1/clients?name=like.*Анна*" -H "apikey: ..."

  # in (IN-список)
  curl "$SUPABASE_URL/rest/v1/clients?status=in.(active,pending)" -H "apikey: ..."
  ```

### Beget API

- **Где взять:** `cp.beget.com` → API → создать токен
- **Стоимость:** бесплатно (входит в хостинг)
- **Куда у нас:** в основном через панель + ssh, API — для автоматизации деплоя если будет нужно
- **Документация:** `beget.com/ru/kb/api/api-funkcii`

### Yandex Cloud (для российских интеграций)

- **Где взять:** `cloud.yandex.ru` → IAM → Service accounts → API key
- **Стоимость:** SpeechKit ~120₽ за 1 час распознавания, Object Storage от 2₽/ГБ-мес
- **Куда у нас:** серверный `.env` (`YC_TOKEN`, `YC_FOLDER_ID`) — для клиентов с требованием локализации в РФ
- **Use cases:** SpeechKit (транскрибация голосовых клиента), Object Storage (хранение медиа), YandexGPT (российская LLM для клиентских AI)

### Сбер API (платежи в Воронке 1 и других продуктах)

- **Где взять:** `developer.sber.ru` → личный кабинет → подключение Сбер Онлайн / Сбер Бизнес
- **Стоимость:** комиссия за транзакцию ~1.7-3% (зависит от тарифа)
- **Куда у нас:** серверный `.env` платёжного шлюза для Воронки 1 (`SBER_CLIENT_ID`, `SBER_SECRET`)
- **Документация:** `developer.sber.ru/docs`

### ЮMoney (альтернативная платёжка)

- **Где взять:** `yoomoney.ru` → бизнес-кабинет → API
- **Стоимость:** комиссия за транзакцию ~3-6%
- **Куда у нас:** запасной вариант если Сбер не подходит клиенту
- **Документация:** `yoomoney.ru/docs/payment-buttons`

### amoCRM (если интегрируем чужие CRM клиентов)

- **Где взять:** в учётке клиента → Интеграции → API → создать интеграцию
- **Стоимость:** входит в подписку amoCRM (от 499₽/мес/пользователь у клиента)
- **Куда у нас:** для клиентов с amoCRM, которым делаем интеграцию через n8n или webhook
- **OAuth 2.0:** `Authorization: Bearer $AMOCRM_ACCESS_TOKEN`

## Сервисы которые НЕ наш стек

- **Vercel/Railway/Heroku** — мы на Beget, Vercel используется только как Этап 1 двухступенчатого деплоя ([deploy-stages.md](../methodology/deploy-stages.md))
- **GitHub API** — есть `knowledge/tools/github-access.md` со своим разделом, не дублируем

## Связки

- [agents/systems.md](../../agents/systems.md) (раздел «Внешние API» в работе с бэкендом ботов и Mini App)
- [agents/devops-infra.md](../../agents/devops-infra.md) (раздел «Управление ключами на серверах»)
- [agents/ai-builder.md](../../agents/ai-builder.md) (раздел «Технический стек» при подключении Claude/GPT API к ботам клиентов)
- [knowledge/methodology/deploy-stages.md](../methodology/deploy-stages.md) (двухступенчатый деплой)
- [agents/director.md](../../agents/director.md) (раздел «Работа с секретами»)
