# CRM Студии

Минимальная CRM для приёма и ведения лидов Студии (Ирины Цепаевой).
Полная копия структуры «Моей базы клиентов» Инны — отличается брендом, владельцем, портом и доменом.

Стек MVP:
- Python standard library;
- SQLite;
- BasicAuth для `/admin`;
- `POST /api/leads` для приёма заявок.

## Локальный запуск

```bash
cd apps/irina-crm
cp .env.example .env
python3 server.py
```

Админка:

`http://127.0.0.1:3015/admin`

API:

`POST http://127.0.0.1:3015/api/leads`

Ручной backup локальной базы:

```bash
python3 backup.py
```

## Production

Production-цель:

`https://crm.stydiyatsi.ru`

Сервер: **Cheerful Marik** (Beget Cloud VPS, 45.9.41.80, РФ).

Перед деплоем:
- заменить `CRM_ADMIN_PASSWORD`;
- убрать локальные origins из `CRM_ALLOWED_ORIGINS`;
- вынести БД в `/var/lib/irina-crm/crm.sqlite`;
- поставить systemd-сервис `irina-crm.service`;
- поставить systemd timer `irina-crm-backup.timer`;
- настроить nginx-блок `crm.stydiyatsi.ru` + Let's Encrypt.

## Порты и пути на сервере

| Что | Где |
|---|---|
| App | `/opt/irina-crm/server.py` |
| База | `/var/lib/irina-crm/crm.sqlite` |
| Backup | `/var/backups/irina-crm/` |
| Port | `127.0.0.1:3015` (только loopback) |
| systemd | `irina-crm.service`, `irina-crm-backup.timer` |
| nginx | `/etc/nginx/sites-enabled/crm.stydiyatsi.ru.conf` |
| Пользователь | `irina-crm` (systemd user) |

## Не путать с «Моей базой клиентов» Инны

| | Инна | Ирина |
|---|---|---|
| Имя | Моя база клиентов | CRM Студии |
| Домен | `crm.ideidlyabiznesa1913.ru` | `crm.stydiyatsi.ru` |
| Сервер | Model Zarek | Cheerful Marik |
| Порт | 3005 | 3015 |
| Палитра | Deep Forest + Gold | Сосновая хвоя + Ваниль + Коралл |
| App | `/opt/inna-crm/` | `/opt/irina-crm/` |
| База | `/var/lib/inna-crm/` | `/var/lib/irina-crm/` |
