# deploy/zarek-nginx/

**Источник правды для nginx-конфигов на сервере Model Zarek (`31.128.41.17`).**

Все конфиги в этой папке — это исходники. На сервере лежат копии, развёрнутые через `deploy/zarek-deploy.sh` (Этап 1+).

## Структура

```
deploy/zarek-nginx/
├── README.md             ← этот файл
├── nginx.conf            ← базовый nginx.conf (если правится; на старте — дефолт от пакета)
├── _503.html             ← страница «Скоро откроется» (тёмный фон + оранжевый акцент)
├── inna.conf             ← server-блок для inna.ideidlyabiznesa1913.ru
├── mini.conf             ← server-блок для mini.ideidlyabiznesa1913.ru
├── ai.conf               ← server-блок для ai.ideidlyabiznesa1913.ru
├── crm.conf              ← server-блок для crm.ideidlyabiznesa1913.ru
├── bz.conf               ← server-блок для bz.ideidlyabiznesa1913.ru
├── platforma.conf        ← server-блок для platforma.ideidlyabiznesa1913.ru
└── demo.conf             ← готовый шаблон для demo.* (НЕ активируется на Этапе 1, ждёт Этапа 6)
```

## Принцип работы

1. Конфиги пишутся в репо в этой папке
2. Через `deploy/zarek-deploy.sh` копируются на сервер в `/etc/nginx/sites-available/`
3. Симлинки в `/etc/nginx/sites-enabled/` создаёт скрипт (для активных)
4. `demo.conf` лежит без симлинка — активируется на Этапе 6 при переезде

## SSL

Wildcard-сертификат `*.ideidlyabiznesa1913.ru` через Let's Encrypt + Cloudflare DNS-01 challenge.
Получается на Этапе 1 (см. `inna/operational-infrastructure-2026-05-10.md` раздел 18.1).
Автообновление каждые 90 дней через `certbot.timer`.

## Связанные документы

- `inna/operational-infrastructure-2026-05-10.md` — источник правды операционной архитектуры
- `agents/devops-infra.md` — методология руководителя инфры
