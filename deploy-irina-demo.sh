#!/bin/bash
# deploy-irina-demo.sh — preview-деплой визитки Ирины на demo.ideidlyabiznesa1913.ru/irina/
#
# Запуск из корня репо:
#   ./deploy-irina-demo.sh
#
# Льёт:
#   clients/irina/index.html → ~/irina/index.html
#   clients/irina/assets/    → ~/irina/assets/

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_USER="icepaeqw_demo"
CLIENT_FOLDER="irina"
LOCAL_HTML="clients/irina/index.html"
LOCAL_ASSETS="clients/irina/assets"

if [ ! -f "${LOCAL_HTML}" ]; then
  echo "❌ ${LOCAL_HTML} не найден"
  exit 1
fi

if [ ! -d "${LOCAL_ASSETS}" ]; then
  echo "❌ Папка ${LOCAL_ASSETS} не найдена"
  exit 1
fi

echo "🚀 Деплой визитки Ирины → demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""

ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${CLIENT_FOLDER}/assets"

echo "📤 index.html..."
scp "${LOCAL_HTML}" "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/index.html"

echo "📤 assets/..."
scp -r "${LOCAL_ASSETS}/" "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/"

echo ""
echo "✅ Готово!"
echo ""
echo "   🔗 https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""
