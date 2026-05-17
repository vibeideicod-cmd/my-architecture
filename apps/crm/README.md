# CRM MVP

Минимальная CRM «Моя база клиентов» для приёма лидов из `karta-rosta.html`.

Стек MVP:
- Python standard library;
- SQLite;
- BasicAuth для `/admin`;
- `POST /api/leads` для квиза.

## Локальный запуск

```bash
cd apps/crm
cp .env.example .env
python3 server.py
```

Админка:

`http://127.0.0.1:3005/admin`

API:

`POST http://127.0.0.1:3005/api/leads`

Ручной backup локальной базы:

```bash
python3 backup.py
```

## Production

Production-цель:

`https://crm.ideidlyabiznesa1913.ru`

Перед деплоем:
- заменить `CRM_ADMIN_PASSWORD`;
- убрать локальные origins из `CRM_ALLOWED_ORIGINS`;
- вынести БД в `/var/lib/inna-crm/crm.sqlite`;
- поставить systemd-сервис;
- поставить systemd timer для backup;
- заменить nginx 503-заглушку на proxy.
