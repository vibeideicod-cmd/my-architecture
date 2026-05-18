# Runbook: первичная настройка CRM Студии на Cheerful Marik

Сервер: **Cheerful Marik** (Beget Cloud VPS, 45.9.41.80, РФ).
Конечная цель: `https://crm.stydiyatsi.ru` работает, лиды принимаются, бэкап крутится.

Используется **один раз** при первом разворачивании. Дальше обновления — через `deploy-irina-crm.sh`.

---

## 0. Pre-flight (на Mac)

```bash
# Из корня my-architecture/
cd ~/Documents/Projects/my-architecture
```

Проверь что в `.env` есть:
```
MARIK_HOST=45.9.41.80
MARIK_USER=root
```

---

## 1. SSH-проверка ресурсов сервера

```bash
ssh cheerful-marik 'free -h && df -h / && docker ps && ss -tulpn | grep -E ":(3015|80|443)\b"'
```

Что должно быть:
- RAM свободно ≥ 200 МБ (после остановки Baserow освободится больше)
- Диск свободно ≥ 2 ГБ
- Порт 3015 не занят
- Порты 80/443 заняты nginx (это нормально)

---

## 2. Остановка Baserow (без удаления)

⚠️ ДО этого шага — спросить Инну ещё раз: «Останавливаем Baserow?»

```bash
ssh cheerful-marik 'cd /opt/baserow && docker compose stop'
ssh cheerful-marik 'docker ps -a | grep baserow'   # должен быть Exited, не Up
```

Откатить за секунду если что:
```bash
ssh cheerful-marik 'cd /opt/baserow && docker compose start'
```

---

## 3. Создание пользователя, папок, БД

```bash
ssh cheerful-marik <<'BASH'
set -e

# Пользователь
id -u irina-crm &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin irina-crm

# Папки
mkdir -p /opt/irina-crm /var/lib/irina-crm /var/backups/irina-crm
chown irina-crm:irina-crm /var/lib/irina-crm /var/backups/irina-crm
chmod 750 /var/lib/irina-crm /var/backups/irina-crm

echo "OK: user irina-crm, dirs /opt/irina-crm + /var/lib/irina-crm + /var/backups/irina-crm"
BASH
```

---

## 4. Первый rsync кода + .env

```bash
# С Mac: код
rsync -avz \
  --exclude '.env' --exclude 'data/' --exclude 'backups/' \
  --exclude '__pycache__/' --exclude '.DS_Store' \
  apps/irina-crm/ root@45.9.41.80:/opt/irina-crm/

# С Mac: создать .env прямо на сервере (пароль придумай длинный)
ssh cheerful-marik 'cat > /opt/irina-crm/.env' <<EOF
CRM_HOST=127.0.0.1
CRM_PORT=3015
CRM_DB_PATH=/var/lib/irina-crm/crm.sqlite
CRM_ADMIN_USER=irina
CRM_ADMIN_PASSWORD=ЗАМЕНИ_НА_ДЛИННЫЙ_ПАРОЛЬ
CRM_ALLOWED_ORIGINS=https://stydiyatsi.ru,https://www.stydiyatsi.ru
CRM_BACKUP_DIR=/var/backups/irina-crm
CRM_BACKUP_KEEP_DAYS=14
EOF

# Права
ssh cheerful-marik 'chown -R irina-crm:irina-crm /opt/irina-crm && chmod 600 /opt/irina-crm/.env'
```

⚠️ Пароль придумай и подмени в `EOF`-блоке **до запуска**. Не коммить.

---

## 5. systemd-юниты

С Mac:
```bash
scp deploy/irina-crm.service \
    deploy/irina-crm-backup.service \
    deploy/irina-crm-backup.timer \
    root@45.9.41.80:/etc/systemd/system/
```

Поднимаем:
```bash
ssh cheerful-marik <<'BASH'
set -e
systemctl daemon-reload
systemctl enable --now irina-crm.service
systemctl status --no-pager irina-crm.service | head -8
curl -fsS http://127.0.0.1:3015/health && echo " ← OK"

# Backup
systemctl enable --now irina-crm-backup.timer
systemctl list-timers --all | grep irina-crm
BASH
```

---

## 6. nginx + Let's Encrypt

```bash
# DNS: A-запись crm.stydiyatsi.ru → 45.9.41.80 — сделай в панели Beget ДО certbot

# С Mac: конфиг
scp deploy/marik-nginx/crm-stydiyatsi.conf \
    root@45.9.41.80:/etc/nginx/sites-available/crm.stydiyatsi.ru.conf

ssh cheerful-marik <<'BASH'
set -e
ln -sf /etc/nginx/sites-available/crm.stydiyatsi.ru.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Certbot выпускает SSL и переписывает блок под 443
certbot --nginx -d crm.stydiyatsi.ru -m inirstudiy@gmail.com --agree-tos --no-eff-email --redirect

nginx -t && systemctl reload nginx
BASH
```

---

## 7. End-to-end check

```bash
# Public health
curl -fsS https://crm.stydiyatsi.ru/health

# Admin (BasicAuth)
curl -fsS -u irina:ТВОЙ_ПАРОЛЬ https://crm.stydiyatsi.ru/admin | head -20

# POST лида (валидный JSON)
curl -fsS -X POST https://crm.stydiyatsi.ru/api/leads \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://stydiyatsi.ru' \
  -d '{
    "source":"manual",
    "name":"Тест Иринин",
    "channel":"telegram",
    "contact":"@test_user",
    "consent_given_at":"2026-05-18T12:00:00Z",
    "consent_text_version":"v1.0",
    "answers":{}
  }'

# Бэкап вручную (проверить что timer работает корректно)
ssh cheerful-marik 'systemctl start irina-crm-backup.service && ls -la /var/backups/irina-crm/'
```

Если все 4 шага PASS — открыть в браузере `https://crm.stydiyatsi.ru/admin`, увидеть тестовую запись, удалить её или поменять статус.

---

## Откат всех изменений (если что-то сломалось)

```bash
ssh cheerful-marik <<'BASH'
systemctl stop irina-crm.service irina-crm-backup.timer 2>/dev/null || true
systemctl disable irina-crm.service irina-crm-backup.timer 2>/dev/null || true
rm -f /etc/systemd/system/irina-crm*.service /etc/systemd/system/irina-crm-backup.timer
rm -f /etc/nginx/sites-enabled/crm.stydiyatsi.ru.conf
rm -f /etc/nginx/sites-available/crm.stydiyatsi.ru.conf
systemctl daemon-reload
nginx -t && systemctl reload nginx
# Baserow обратно (если останавливали)
cd /opt/baserow && docker compose start
BASH
```

Это откатывает деплой Иринины CRM. Папки `/opt/irina-crm/`, `/var/lib/irina-crm/`, `/var/backups/irina-crm/` оставляем — удалить только после явного подтверждения от Инны.
