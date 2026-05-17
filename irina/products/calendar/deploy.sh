#!/usr/bin/env bash
# ============================================================
# П3 · Деплой бэкенда календаря Ирины (РФ-стек, 152-ФЗ)
# ------------------------------------------------------------
# Что делает:
#   1. rsync-ит три подпапки (tg-bot, vk-bot, notify-email) на VPS
#      Cheerful Marik в /root/irina-calendar/
#   2. Ставит npm-зависимости
#   3. Перезапускает все три процесса PM2
#   4. Деплоит admin/admin.html на Beget shared (рядом с Mini App)
#   5. Делает быстрый health-check каждого бота
#
# Mini App-фронт (index.html) и admin.html отдельно деплоит Кодыч /
# скрипт deploy-irina-demo.sh — здесь подхватываем admin.html
# в `cal/admin.html` если он лежит в этой папке (Кодыч его туда положит).
#
# Baserow на VPS уже стоит — туда ничего не деплоим, только читаем
# через REST API.
#
# Запуск:
#   chmod +x deploy.sh
#   ./deploy.sh
# ============================================================

set -euo pipefail

VPS_HOST="root@45.9.41.80"      # Cheerful Marik
REMOTE_DIR="/root/irina-calendar"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Beget shared — для admin.html (только если он есть)
BEGET_HOST="${BEGET_HOST:-icepaeqw.beget.tech}"
BEGET_USER="${BEGET_USER:-icepaeqw_hub}"
BEGET_REMOTE="public_html/cal"

echo ""
echo "============================================================"
echo " Деплой календаря Ирины"
echo "  → VPS Cheerful Marik (${VPS_HOST}:${REMOTE_DIR}) — боты"
echo "  → Beget (${BEGET_USER}@${BEGET_HOST}:${BEGET_REMOTE}) — admin.html"
echo "============================================================"

# 0. Sanity-check: на локалке должны быть .env файлы (ботов)
for sub in tg-bot notify-email; do
  if [ ! -f "${LOCAL_DIR}/${sub}/.env" ]; then
    echo ""
    echo "  Нет файла ${sub}/.env"
    echo "   Скопируй ${sub}/.env.example → ${sub}/.env и заполни значения."
    echo "   (не делай это автоматически — токены вставляются руками)"
    exit 1
  fi
done

# vk-bot/.env — необязательный, если VK-канал не запускаем
DEPLOY_VK=1
if [ ! -f "${LOCAL_DIR}/vk-bot/.env" ]; then
  echo ""
  echo "  vk-bot/.env не найден — VK-бот пропускаем"
  echo "   (если нужен VK — скопируй .env.example → .env и заполни)"
  DEPLOY_VK=0
fi

# 1. Папка на VPS
echo ""
echo "[1/6] Создаём ${REMOTE_DIR} на VPS…"
ssh "${VPS_HOST}" "mkdir -p ${REMOTE_DIR} && mkdir -p /var/log/pm2"

# 2. rsync кода ботов
echo ""
echo "[2/6] rsync кода ботов…"
rsync -avz --delete \
  --exclude 'node_modules/' \
  --exclude '.DS_Store' \
  --exclude '*.log' \
  --exclude 'seen.json' \
  "${LOCAL_DIR}/tg-bot/" "${VPS_HOST}:${REMOTE_DIR}/tg-bot/"

if [ "$DEPLOY_VK" = "1" ]; then
  rsync -avz --delete \
    --exclude 'node_modules/' \
    --exclude '.DS_Store' \
    --exclude '*.log' \
    "${LOCAL_DIR}/vk-bot/" "${VPS_HOST}:${REMOTE_DIR}/vk-bot/"
fi

rsync -avz --delete \
  --exclude 'node_modules/' \
  --exclude '.DS_Store' \
  --exclude '*.log' \
  "${LOCAL_DIR}/notify-email/" "${VPS_HOST}:${REMOTE_DIR}/notify-email/"

# Документы кладём рядом — на случай если понадобятся на VPS
rsync -avz "${LOCAL_DIR}/BASEROW-SETUP.md" "${VPS_HOST}:${REMOTE_DIR}/BASEROW-SETUP.md"

# 3. npm install в каждом сервисе
echo ""
echo "[3/6] npm install…"
ssh "${VPS_HOST}" bash -lc "
  set -e
  command -v node >/dev/null || { echo 'Node.js не установлен на VPS'; exit 1; }
  command -v pm2  >/dev/null || npm install -g pm2
  for sub in tg-bot notify-email${DEPLOY_VK:+ vk-bot}; do
    echo ' — npm install в '\$sub
    cd ${REMOTE_DIR}/\$sub
    npm install --omit=dev --no-audit --no-fund
  done
"

# 4. PM2: запускаем по ecosystem (или перезапускаем, если уже)
echo ""
echo "[4/6] PM2 reload…"
ssh "${VPS_HOST}" bash -lc "
  set -e
  cd ${REMOTE_DIR}/tg-bot
  if pm2 describe irina-cal-tg >/dev/null 2>&1; then
    pm2 reload ecosystem.config.js
  else
    pm2 start ecosystem.config.js
  fi
  pm2 save
"

# 5. Health-check
echo ""
echo "[5/6] Health-check ботов…"
sleep 2
ssh "${VPS_HOST}" bash -lc "
  for port in 3010 3012${DEPLOY_VK:+ 3011}; do
    code=\$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:\$port/health || echo '000')
    echo \"  :\$port → HTTP \$code\"
  done
  pm2 status
"

# 6. Деплой admin.html на Beget shared (если файл есть)
echo ""
echo "[6/6] Деплой admin.html на Beget…"
if [ -f "${LOCAL_DIR}/admin/admin.html" ]; then
  rsync -avz \
    "${LOCAL_DIR}/admin/admin.html" \
    "${BEGET_USER}@${BEGET_HOST}:${BEGET_REMOTE}/admin.html"
  echo "  → https://demo.ideidlyabiznesa1913.ru/cal/admin.html"
else
  echo "  admin/admin.html не найден — пропуск (Кодыч ещё не сделал вёрстку)"
fi

echo ""
echo "============================================================"
echo " Готово."
echo ""
echo " Что осталось руками:"
echo " 1. Настроить nginx-проксирование на VPS (если ещё не):"
echo "      location /irina-cal/notify {"
echo "        proxy_pass http://127.0.0.1:3010/notify;"
echo "        proxy_set_header Host \$host;"
echo "      }"
echo " 2. В Baserow (на VPS) создать webhook на таблице bookings"
echo "    с URL https://<vps-домен>/irina-cal/notify (опционально —"
echo "    бот всё равно опрашивает Baserow раз в 60 сек)."
echo " 3. Привязать Mini App к боту в @BotFather → Menu Button."
echo " 4. Открыть admin.html в браузере, ввести Baserow API-токен."
echo "============================================================"
