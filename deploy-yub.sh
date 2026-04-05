#!/bin/bash
# deploy-yub.sh — деплой MVP Южнобережного
# URL после деплоя: https://ideidlyabiznesa1913.ru/demo/yub/
#
# Запуск: ./deploy-yub.sh

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_USER:?❌ Укажи BEGET_USER в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_PATH="~/demo"
CLIENT_FOLDER="yub"
LOCAL_PATH="clients/yuzhnoberezhniy/mvp"

echo "🚀 Деплой Южнобережного → ideidlyabiznesa1913.ru/demo/${CLIENT_FOLDER}/"
echo ""

# Создать папку demo/yub на сервере если её нет
ssh "${BEGET_USER}@${BEGET_HOST}" "mkdir -p ${DEMO_PATH}/${CLIENT_FOLDER}"

# Скопировать файлы
scp \
  "${LOCAL_PATH}/index.html" \
  "${LOCAL_PATH}/ryukzak.html" \
  "${LOCAL_PATH}/quiz.html" \
  "${LOCAL_PATH}/tour.html" \
  "${BEGET_USER}@${BEGET_HOST}:${DEMO_PATH}/${CLIENT_FOLDER}/"

echo ""
echo "✅ Готово!"
echo ""
echo "   🏠 Каталог:   https://ideidlyabiznesa1913.ru/demo/${CLIENT_FOLDER}/"
echo "   🎒 Чеклист:   https://ideidlyabiznesa1913.ru/demo/${CLIENT_FOLDER}/ryukzak.html"
echo "   ✅ Квиз:       https://ideidlyabiznesa1913.ru/demo/${CLIENT_FOLDER}/quiz.html"
echo "   🏖  Экскурсия: https://ideidlyabiznesa1913.ru/demo/${CLIENT_FOLDER}/tour.html"
