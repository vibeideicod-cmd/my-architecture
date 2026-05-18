# marik-nginx — nginx-конфиги для Cheerful Marik

Сервер: **Cheerful Marik** (Beget Cloud VPS, 45.9.41.80, РФ).
Параллельно `deploy/zarek-nginx/` (Model Zarek).

## Что здесь

| Файл | Домен | Назначение |
|---|---|---|
| `crm-stydiyatsi.conf` | `crm.stydiyatsi.ru` | CRM Студии (Иринина), proxy на 127.0.0.1:3015 |

## Деплой нового домена

1. Скопировать `*.conf` в `/etc/nginx/sites-available/` на сервере.
2. `ln -s /etc/nginx/sites-available/<file>.conf /etc/nginx/sites-enabled/`.
3. `nginx -t && systemctl reload nginx`.
4. Создать A-запись на 45.9.41.80, дождаться DNS-резолва.
5. `certbot --nginx -d <домен> -m inirstudiy@gmail.com --agree-tos --no-eff-email`.
6. `nginx -t && systemctl reload nginx`.
