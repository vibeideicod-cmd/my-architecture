#!/bin/bash
# deploy-mg.sh — деплой МГ-платформы на demo.ideidlyabiznesa1913.ru/mg/
#
# Запуск: ./deploy-mg.sh

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_USER="icepaeqw_demo"
CLIENT_FOLDER="mg"
LOCAL_PATH="clients/mastergroup/mvp"

echo "🚀 Деплой МГ-платформы → demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""

ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${CLIENT_FOLDER}"

scp \
  "${LOCAL_PATH}/index.html" \
  "${LOCAL_PATH}/vitrina.html" \
  "${LOCAL_PATH}/cabinet.html" \
  "${LOCAL_PATH}/admin.html" \
  "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/"

echo ""
echo "✅ Готово!"
echo ""
echo "   🏠 Лендинг:    https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo "   🎯 Витрина:    https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/vitrina.html?m=inna"
echo "   🎓 Кабинет:    https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/cabinet.html?m=inna&t=innademo2026"
echo "   📊 Админка:    https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/admin.html"
echo ""
echo "   🔑 Админ-ключ:  nbcccp-2026"
