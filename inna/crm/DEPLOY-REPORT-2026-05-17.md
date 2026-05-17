# Deploy Report — CRM MVP

Дата: 2026-05-17  
Статус: production MVP развёрнут на Model Zarek

## Что развернуто

| Узел | Статус |
|---|---|
| Домен | `https://crm.ideidlyabiznesa1913.ru` |
| Сервер | Model Zarek, Beget Cloud VPS, РФ |
| Приложение | `/opt/inna-crm/server.py` |
| База | `/var/lib/inna-crm/crm.sqlite` |
| systemd | `inna-crm.service` active/enabled |
| nginx | `crm.conf` заменён с 503-заглушки на proxy `127.0.0.1:3005` |
| Админка | `/admin`, BasicAuth |
| Backup | `inna-crm-backup.timer`, ежедневно 03:20 UTC, `/var/backups/inna-crm` |

## Проверки

| Проверка | Результат |
|---|---|
| Локальный `/health` на сервере | PASS |
| Публичный `/health` | PASS |
| CORS preflight с `https://ideidlyabiznesa1913.ru` | PASS |
| `POST /api/leads` | PASS |
| Лид виден в `/admin` | PASS |
| Смена статуса `new → contacted` | PASS |
| Ежедневный backup SQLite | PASS |

Тестовый production lead:

```text
lead_20260517_124725_cee639
```

## Что важно

- Секрет админки хранится только на сервере в `/opt/inna-crm/.env`.
- Секрет не записан в git.
- Приложение слушает только `127.0.0.1:3005`, наружу смотрит nginx.
- Данные Карты точек роста идут в собственную CRM на российском VPS.
- Backup уже создан вручную и включён по timer.

## Осталось

| Задача | Почему |
|---|---|
| Улучшить админку | Сейчас это минимальный список и смена статуса |
| Добавить экспорт CSV | Для ручной работы и резервной выгрузки |
| Провести end-to-end тест с опубликованного `karta-rosta.html` | После деплоя HUB/карты на production |
