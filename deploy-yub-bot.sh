#!/bin/bash
# deploy-yub-bot.sh — деплой PHP-обработчика /start для @ryukzak_yub_bot
# Подставляет токен из .env в шаблон, выкладывает на Beget, регистрирует webhook.

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Файл .env не найден."
  exit 1
fi

: "${TG_BOT_TOKEN:?❌ Укажи TG_BOT_TOKEN в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

DEMO_USER="icepaeqw_demo"
TEMPLATE="clients/yuzhnoberezhniy/bot/webhook.php"
REMOTE_PATH="~/yub-webhook.php"
WEBHOOK_URL="https://demo.ideidlyabiznesa1913.ru/yub-webhook.php"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

sed "s|{{TG_BOT_TOKEN}}|${TG_BOT_TOKEN}|g" "$TEMPLATE" > "$TMP"

echo "🚀 Деплой webhook.php → ${REMOTE_PATH}"
scp -q "$TMP" "${DEMO_USER}@${BEGET_HOST}:${REMOTE_PATH}"

echo "🔗 Регистрирую webhook в Telegram Bot API → ${WEBHOOK_URL}"
curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/setWebhook" \
  --data-urlencode "url=${WEBHOOK_URL}" \
  --data-urlencode 'allowed_updates=["message"]' \
  | python3 -m json.tool

echo ""
echo "ℹ️  getWebhookInfo:"
curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/getWebhookInfo" | python3 -m json.tool

echo ""
echo "✅ Готово. Проверь: отправь /start в @ryukzak_yub_bot"
