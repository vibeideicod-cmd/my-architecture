#!/bin/bash
# deploy-hub.sh — деплой HUB (hub/) на ideidlyabiznesa1913.ru
#
# Запуск: ./deploy-hub.sh

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_USER:?❌ Укажи BEGET_USER в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"
: "${BEGET_PATH:?❌ Укажи BEGET_PATH в .env}"

echo "🚀 Деплой HUB на ${DOMAIN:-$BEGET_HOST}..."
echo "   Откуда: $(pwd)/hub/"
echo "   Куда:   ${BEGET_USER}@${BEGET_HOST}:${BEGET_PATH}"
echo ""

scp -r hub/index.html "${BEGET_USER}@${BEGET_HOST}:~/"

echo ""
echo "✅ Готово! Сайт: https://${DOMAIN:-$BEGET_HOST}"
