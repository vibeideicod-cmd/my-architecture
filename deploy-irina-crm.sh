#!/bin/bash
# deploy-irina-crm.sh — деплой «CRM Студии» на Cheerful Marik (Beget Cloud VPS).
#
# Что делает:
#   1. Синхронизирует код из apps/irina-crm/ → root@cheerful-marik:/opt/irina-crm/
#   2. Перезапускает systemd-сервис irina-crm.service
#   3. Показывает короткий статус-чек
#
# Запуск из корня репо:
#   ./deploy-irina-crm.sh
#
# Что НЕ делает:
#   - не создаёт системного пользователя irina-crm (это первичная настройка)
#   - не ставит systemd-юниты (это первичная настройка)
#   - не выпускает SSL (это первичная настройка)
#   - не трогает БД и бэкапы (они на сервере)
#   - не трогает .env (он на сервере)
#
# Первичная настройка — см. apps/irina-crm/RUNBOOK.md.
#
# Требования в .env:
#   MARIK_HOST              — IP или hostname Cheerful Marik (например 45.9.41.80)
#   MARIK_USER              — SSH-пользователь (обычно root)

set -e

# ── Загрузка .env ───────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "❌ Файл .env не найден в текущей папке."
  echo "   Запускай из корня репозитория my-architecture/"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

: "${MARIK_HOST:?❌ Укажи MARIK_HOST в .env (IP или hostname Cheerful Marik)}"
: "${MARIK_USER:?❌ Укажи MARIK_USER в .env (обычно root)}"

LOCAL_DIR="apps/irina-crm"
REMOTE_DIR="/opt/irina-crm"

if [ ! -f "${LOCAL_DIR}/server.py" ]; then
  echo "❌ ${LOCAL_DIR}/server.py не найден"
  exit 1
fi

echo "🚀 Деплой CRM Студии на Cheerful Marik"
echo "   Откуда: ${LOCAL_DIR}/"
echo "   Куда:   ${MARIK_USER}@${MARIK_HOST}:${REMOTE_DIR}/"
echo ""

# ── Sync кода (исключаем локальные dev-файлы) ───────────────────────────────
rsync -avz --delete \
  --exclude '.env' \
  --exclude 'data/' \
  --exclude 'backups/' \
  --exclude '__pycache__/' \
  --exclude '.DS_Store' \
  "${LOCAL_DIR}/" \
  "${MARIK_USER}@${MARIK_HOST}:${REMOTE_DIR}/"

# ── Перезапуск сервиса ──────────────────────────────────────────────────────
echo ""
echo "🔄 Перезапускаю irina-crm.service"
ssh "${MARIK_USER}@${MARIK_HOST}" "systemctl restart irina-crm.service && sleep 1 && systemctl is-active irina-crm.service"

# ── Статус ──────────────────────────────────────────────────────────────────
echo ""
echo "📋 Статус:"
ssh "${MARIK_USER}@${MARIK_HOST}" "systemctl --no-pager status irina-crm.service | head -10"

echo ""
echo "🌐 Health-check:"
ssh "${MARIK_USER}@${MARIK_HOST}" "curl -fsS http://127.0.0.1:3015/health || echo '❌ health failed'"

echo ""
echo "✅ Готово!"
echo ""
echo "   Публичный URL:    https://crm.stydiyatsi.ru"
echo "   Админка:          https://crm.stydiyatsi.ru/admin"
echo "   API лидов:        POST https://crm.stydiyatsi.ru/api/leads"
