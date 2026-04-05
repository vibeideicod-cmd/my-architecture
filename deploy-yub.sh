#!/bin/bash
# deploy-yub.sh — деплой MVP Южнобережного на yub.ideidlyabiznesa1913.ru
#
# Запуск: ./deploy-yub.sh
#
# Перед запуском: создай сайт yub.ideidlyabiznesa1913.ru в панели Beget
# Хостинг → Сайты → Создать сайт → yub.ideidlyabiznesa1913.ru

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_USER:?❌ Укажи BEGET_USER в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

YUB_SUBDOMAIN="yub.ideidlyabiznesa1913.ru"
YUB_PATH="/home/icepaeqw/${YUB_SUBDOMAIN}/public_html"
LOCAL_PATH="clients/yuzhnoberezhniy/mvp"

echo "🚀 Деплой Южнобережного на ${YUB_SUBDOMAIN}..."
echo "   Откуда: $(pwd)/${LOCAL_PATH}/"
echo "   Куда:   ${BEGET_USER}@${BEGET_HOST}:${YUB_PATH}"
echo ""

scp -r \
  "${LOCAL_PATH}/index.html" \
  "${LOCAL_PATH}/ryukzak.html" \
  "${LOCAL_PATH}/quiz.html" \
  "${LOCAL_PATH}/tour.html" \
  "${BEGET_USER}@${BEGET_HOST}:${YUB_PATH}/"

echo ""
echo "✅ Готово! Сайт: https://${YUB_SUBDOMAIN}"
echo ""
echo "   📋 Чеклист:   https://${YUB_SUBDOMAIN}/ryukzak.html"
echo "   ✅ Квиз:       https://${YUB_SUBDOMAIN}/quiz.html"
echo "   🏖  Экскурсия: https://${YUB_SUBDOMAIN}/tour.html"
