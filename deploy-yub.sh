#!/bin/bash
# deploy-yub.sh — деплой MVP Южнобережного на demo.ideidlyabiznesa1913.ru/yub/
#
# Запуск: ./deploy-yub.sh
#
# Требование: субдомен demo.ideidlyabiznesa1913.ru уже создан в панели Beget

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_USER:?❌ Укажи BEGET_USER в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_PATH="/home/icepaeqw/demo.ideidlyabiznesa1913.ru/public_html"
CLIENT_FOLDER="yub"
LOCAL_PATH="clients/yuzhnoberezhniy/mvp"

echo "🚀 Деплой Южнобережного → demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""

# Создать папку клиента на сервере если её нет
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
echo "   🏠 Каталог:   https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo "   🎒 Чеклист:   https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/ryukzak.html"
echo "   ✅ Квиз:       https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/quiz.html"
echo "   🏖  Экскурсия: https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/tour.html"
