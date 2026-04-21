#!/bin/bash
# deploy-inna.sh — preview-деплой посадочной «Инна Архитектор» на demo.ideidlyabiznesa1913.ru/inna/
#
# Запуск: ./deploy-inna.sh
#
# Для production-домена без маркеров НБ нужно отдельное решение (см. brief.md раздел 8).
# Этот скрипт выкатывает превью-версию на demo-сервер для локального тестирования в браузере.

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_USER="icepaeqw_demo"
CLIENT_FOLDER="inna"
LOCAL_FILE="inna-arhitektor/output/browser/index.html"

if [ ! -f "${LOCAL_FILE}" ]; then
  echo "❌ Файл ${LOCAL_FILE} не найден."
  echo "   Сначала сгенерируй: cd inna-arhitektor/skills/inna-architect && python3 scripts/generate.py browser < scripts/test-input.json > ../../output/browser/index.html"
  exit 1
fi

echo "🚀 Деплой Инны Архитектор → demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""

ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${CLIENT_FOLDER}"

scp "${LOCAL_FILE}" "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/index.html"

echo ""
echo "✅ Готово!"
echo ""
echo "   🏠 Preview: https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""
echo "   Это демо-URL. Для production без маркеров НБ нужен отдельный домен —"
echo "   решим утром (см. brief.md раздел 8)."
