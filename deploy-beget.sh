#!/bin/bash
# deploy-beget.sh — деплой статического сайта на Beget через SSH/rsync
#
# Первый запуск:
#   1. Скопируй .env.example в .env и заполни данными
#   2. chmod +x deploy-beget.sh
#   3. ./deploy-beget.sh
#
# Для другого проекта: скопируй этот скрипт, поправь .env

set -e

# ── Загрузка конфига ────────────────────────────────────────────────────────
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден. Скопируй .env.example в .env и заполни данными."
  exit 1
fi

# ── Проверка обязательных переменных ───────────────────────────────────────
: "${BEGET_USER:?❌ Укажи BEGET_USER в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"
: "${BEGET_PATH:?❌ Укажи BEGET_PATH в .env}"

# ── Деплой через rsync ─────────────────────────────────────────────────────
echo "🚀 Деплой на ${BEGET_HOST}..."
echo "   Откуда: $(pwd)"
echo "   Куда:   ${BEGET_USER}@${BEGET_HOST}:${BEGET_PATH}"
echo ""

rsync -avz --delete \
  --exclude='.git/' \
  --exclude='.env' \
  --exclude='.env.example' \
  --exclude='*.sh' \
  --exclude='*.md' \
  --exclude='*.py' \
  --exclude='agents/' \
  --exclude='knowledge/' \
  --exclude='ideas/' \
  --exclude='.claude/' \
  --exclude='.DS_Store' \
  --exclude='node_modules/' \
  ./ "${BEGET_USER}@${BEGET_HOST}:${BEGET_PATH}/"

echo ""
echo "✅ Готово! Сайт доступен по адресу: https://${DOMAIN:-$BEGET_HOST}"
