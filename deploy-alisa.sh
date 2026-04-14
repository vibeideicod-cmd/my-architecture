#!/bin/bash
# deploy-alisa.sh — деплой визитки Алисы Лукьянович на demo.ideidlyabiznesa1913.ru/alisa/
#
# Запуск: ./deploy-alisa.sh

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_USER="icepaeqw_demo"
CLIENT_FOLDER="alisa"
LOCAL_PATH="clients/alisa"

echo "🚀 Деплой визитки Алисы → demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""

ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${CLIENT_FOLDER}"

scp \
  "${LOCAL_PATH}/index.html" \
  "${LOCAL_PATH}/alisa.jpg" \
  "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/"

echo ""
echo "✅ Готово!"
echo ""
echo "   🎸 Визитка: https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""
