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

ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${CLIENT_FOLDER} ~/${CLIENT_FOLDER}/_archive ~/${CLIENT_FOLDER}/js"

# Архивируем legacy v1 файлы — публично недоступны, но живы для внутреннего использования
ssh "${DEMO_USER}@${BEGET_HOST}" "cd ~/${CLIENT_FOLDER} && for f in vitrina.html cabinet.html; do [ -f \"\$f\" ] && mv \"\$f\" _archive/ 2>/dev/null || true; done"

# Деплой актуальных файлов + .htaccess с чистыми URL
scp \
  "${LOCAL_PATH}/.htaccess" \
  "${LOCAL_PATH}/index.html" \
  "${LOCAL_PATH}/admin.html" \
  "${LOCAL_PATH}/apply.html" \
  "${LOCAL_PATH}/status.html" \
  "${LOCAL_PATH}/build.html" \
  "${LOCAL_PATH}/master-page.html" \
  "${LOCAL_PATH}/guide-master.html" \
  "${LOCAL_PATH}/guide-admin.html" \
  "${LOCAL_PATH}/test-checklist.html" \
  "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/"

# JS (Telegram Mini App SDK-инициализация и другие разделяемые скрипты)
scp \
  "${LOCAL_PATH}/js/tma-init.js" \
  "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/js/"

echo ""
echo "✅ Готово!"
echo ""
echo "   Чистые URL (через .htaccess):"
echo ""
echo "   🏠 Лендинг:        https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo "   📝 Стать мастером: https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/join"
echo "   📘 Гайд для мастера: https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/guide"
echo ""
echo "   Внутреннее (для команды):"
echo "   📊 Админка:          https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/admin"
echo "   📕 Моя инструкция:   https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/help"
echo "   🧪 Тест-чеклист:    https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/test"
echo "   🔑 Админ-ключ:       nbcccp-2026"
echo ""
echo "   Legacy v1 перенесены в _archive/ — публично недоступны"
