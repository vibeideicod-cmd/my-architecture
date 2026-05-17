# Backend Plan — CRM MVP «Моя база клиентов»

Дата: 2026-05-17  
Статус: план реализации перед кодом/деплоем  
Владелец: Systems + Director  
Связано: `karta-rosta.html`, `inna/crm/schema.md`, `inna/crm/api-contract.md`

## Цель

Сделать минимальную CRM, которая принимает лиды из «Карты точек роста» и даёт Инне понятный список людей для ручного follow-up.

## Не цель

Не строим полноценную amoCRM/Битрикс. Не строим платформу. Не делаем личный кабинет клиента. Не подключаем оплату.

## Варианты реализации

### Вариант A — простой собственный backend на Model Zarek

**Суть:** маленькое приложение на Node.js/SQLite или Node.js/PostgreSQL, плюс простая админ-страница.

Плюсы:
- соответствует архитектуре: `crm.*` на Model Zarek;
- минимум внешних зависимостей;
- можно быстро подключить `karta-rosta.html`;
- легко расширить под AI/n8n.

Минусы:
- нужно самим поддерживать авторизацию, бэкапы, обновления;
- админка сначала будет простой.

### Вариант B — Baserow

**Суть:** self-hosted таблицы/CRM на VPS.

Плюсы:
- быстро получить визуальную таблицу;
- удобно смотреть лиды;
- есть API.

Минусы:
- тяжёлый для текущего Model Zarek 2GB RAM;
- старый план был под Cheerful Marik, а актуальная инфраструктура требует Model Zarek;
- больше Docker/ресурсов/обновлений ради первой таблицы.

### Вариант C — Google Sheets / Notion временно

Плюсы:
- самый быстрый старт.

Минусы:
- противоречит стратегическому решению “своя CRM”;
- ПД и ФЗ-152 слабее контролируются;
- потом всё равно миграция.

## Рекомендация

Для Client Zero выбрать **Вариант A**:

```text
crm.ideidlyabiznesa1913.ru
  ├── /api/leads       принимает лиды
  ├── /admin           список лидов
  ├── /admin/leads/:id карточка лида
  └── SQLite/PostgreSQL на Model Zarek
```

На первом шаге достаточно SQLite, если:
- лидов мало;
- доступ только у Инны;
- есть ежедневный backup файла БД.

При росте — миграция на PostgreSQL без изменения API-контракта.

## Архитектура MVP

```text
karta-rosta.html
  ↓ fetch POST
crm.ideidlyabiznesa1913.ru/api/leads
  ↓ validate
SQLite/PostgreSQL
  ↓
/admin показывает новые лиды
```

## Файлы будущего приложения

Рекомендуемая папка:

```text
apps/crm/
  package.json
  .env.example
  .gitignore
  src/
    server.js
    db.js
    schema.sql
    views/
      admin.html
```

Если решим не заводить `apps/`, можно разместить в `inna/crm/app/`, но лучше отделить документы от кода.

## Переменные окружения

```env
CRM_PORT=3005
CRM_DB_PATH=/var/lib/inna-crm/crm.sqlite
CRM_ADMIN_USER=inna
CRM_ADMIN_PASSWORD=<manual>
CRM_ALLOWED_ORIGINS=https://ideidlyabiznesa1913.ru,https://www.ideidlyabiznesa1913.ru
```

## Защита

- `/admin` — BasicAuth на старте.
- `/api/leads` — только POST, CORS whitelist.
- Не хранить секреты в git.
- Не логировать контактные данные в открытые логи.
- Nginx rate limit на `/api/`.
- Бэкап БД ежедневно.

## Этапы внедрения

### Этап 1 — локальный MVP

- [x] создать код приложения;
- [x] создать таблицу `leads`;
- [x] реализовать `POST /api/leads`;
- [x] реализовать `/admin` со списком лидов;
- [x] подключить `karta-rosta.html` к API с fallback на Telegram/VK/email/другой канал;
- [x] проверить локально: `/health`, `POST /api/leads`, `/admin`, смена статуса `new → contacted`.

### Этап 2 — сервер Model Zarek

- [x] проверить репозиторное состояние `deploy/zarek-nginx/crm.conf`: сейчас это 503-заглушка;
- [x] проверить фактическое состояние `crm.conf` на сервере: была 503-заглушка;
- [x] создать папку приложения на сервере: `/opt/inna-crm`;
- [x] завести `.env` на сервере без попадания секрета в git;
- [x] создать systemd-сервис `inna-crm.service`;
- [x] заменить 503-заглушку nginx на proxy `127.0.0.1:3005`;
- [x] проверить SSL/health: `https://crm.ideidlyabiznesa1913.ru/health`;
- [x] проверить POST с origin `https://ideidlyabiznesa1913.ru`;
- [x] проверить `/admin` и смену статуса `new → contacted`.

### Этап 3 — минимальная эксплуатация

- [x] ежедневный backup SQLite: `inna-crm-backup.timer`, `/var/backups/inna-crm`;
- [x] лог ошибок через systemd/journalctl + nginx logs;
- [x] ручной статус follow-up;
- [ ] экспорт CSV при необходимости.

## Критерии готовности

MVP готов, если:

- [x] лид из `karta-rosta.html` появляется в CRM;
- [x] в CRM видны имя, контакт, канал, ниша, боли, результат;
- [x] Инна может поменять статус;
- [x] если CRM недоступна, квиз показывает ручной fallback;
- [x] данные не уходят на зарубежные сервисы;
- [x] нет публичного доступа к `/admin` без пароля.

## Открытые решения

| Вопрос | Рекомендация |
|---|---|
| SQLite или PostgreSQL? | SQLite для первого Client Zero MVP, PostgreSQL при росте |
| Где код? | `apps/crm/`, чтобы отделить приложение от документов |
| Деплой сейчас? | После локального MVP и проверки фактического состояния Model Zarek |
| Нужен ли Baserow? | Не на первом шаге; вернуться, если нужна визуальная no-code таблица |
