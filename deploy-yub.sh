#!/bin/bash
# deploy-yub.sh — деплой MVP Южнобережного
# URL после деплоя: https://demo.ideidlyabiznesa1913.ru/yub/
#
# Запуск: ./deploy-yub.sh

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_USER="icepaeqw_demo"
CLIENT_FOLDER="yub"
LOCAL_PATH="clients/yuzhnoberezhniy/mvp"

echo "🚀 Деплой Южнобережного → demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo ""

ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${CLIENT_FOLDER}"

scp \
  "${LOCAL_PATH}/index.html" \
  "${LOCAL_PATH}/ryukzak.html" \
  "${LOCAL_PATH}/quiz.html" \
  "${LOCAL_PATH}/tour.html" \
  "${LOCAL_PATH}/feedback.html" \
  "${LOCAL_PATH}/offer.html" \
  "${LOCAL_PATH}/logo.png" \
  "${LOCAL_PATH}/hero.png" \
  "${DEMO_USER}@${BEGET_HOST}:~/${CLIENT_FOLDER}/"

TG_FOLDER="yub-tg"
TG_LOCAL="clients/yuzhnoberezhniy/tg-app"

echo "📱 Деплой Telegram Mini App → demo.ideidlyabiznesa1913.ru/${TG_FOLDER}/"
ssh "${DEMO_USER}@${BEGET_HOST}" "mkdir -p ~/${TG_FOLDER}"
scp "${TG_LOCAL}/index.html" "${DEMO_USER}@${BEGET_HOST}:~/${TG_FOLDER}/"

echo ""
echo "✅ Готово!"
echo ""
echo "   🏠 Каталог:   https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/"
echo "   🎒 Чеклист:   https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/ryukzak.html"
echo "   ✅ Квиз:       https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/quiz.html"
echo "   🏖  Экскурсия: https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/tour.html"
echo "   📩 Правки:    https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/feedback.html"
echo "   💼 КП:         https://demo.ideidlyabiznesa1913.ru/${CLIENT_FOLDER}/offer.html"
echo "   📱 TG Mini App: https://demo.ideidlyabiznesa1913.ru/${TG_FOLDER}/"
