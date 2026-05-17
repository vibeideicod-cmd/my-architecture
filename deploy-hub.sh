#!/bin/bash
# deploy-hub.sh — деплой production HUB и Карты точек роста на ideidlyabiznesa1913.ru
#
# Что нужно в .env:
#   BEGET_USER   — SSH-пользователь Beget (учётка `icepaeqw_*`)
#   BEGET_HOST   — SSH-хост Beget (тот же что используют другие deploy-скрипты)
#   HUB_PATH     — публичная папка домена (по умолчанию ~/ideidlyabiznesa1913.ru/public_html)
#
# Что льётся:
#   index.html         → ${HUB_PATH}/index.html
#   karta-rosta.html   → ${HUB_PATH}/karta-rosta.html
#
# Запуск: ./deploy-hub.sh

set -e

# ── Загрузка .env ───────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "❌ Файл .env не найден в текущей папке."
  echo "   Запускай из корня репозитория my-architecture/"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

# ── Проверка переменных ─────────────────────────────────────────────────────
: "${BEGET_USER:?❌ Укажи BEGET_USER в .env}"
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"

HUB_PATH="${HUB_PATH:-~/ideidlyabiznesa1913.ru/public_html}"
DOMAIN="${DOMAIN:-ideidlyabiznesa1913.ru}"

# ── Проверка локальных файлов ───────────────────────────────────────────────
LOCAL_INDEX="index.html"
LOCAL_KARTA="karta-rosta.html"

if [ ! -f "${LOCAL_INDEX}" ]; then
  echo "❌ ${LOCAL_INDEX} не найден в текущей папке"
  exit 1
fi

if [ ! -f "${LOCAL_KARTA}" ]; then
  echo "❌ ${LOCAL_KARTA} не найден в текущей папке"
  exit 1
fi

# ── Информация о деплое ─────────────────────────────────────────────────────
echo "🚀 Деплой HUB → https://${DOMAIN}"
echo "   Откуда: $(pwd)/${LOCAL_INDEX} + ${LOCAL_KARTA}"
echo "   Куда:   ${BEGET_USER}@${BEGET_HOST}:${HUB_PATH}/"
echo ""

# ── Создаём папку на сервере, если её ещё нет ───────────────────────────────
ssh "${BEGET_USER}@${BEGET_HOST}" "mkdir -p ${HUB_PATH}"

# ── Проверка на старый Beget-индекс, который перебивает index.html ──────────
if ssh "${BEGET_USER}@${BEGET_HOST}" "[ -f ${HUB_PATH}/index.php ]"; then
  echo "⚠️  В ${HUB_PATH}/ найден index.php — он перебьёт наш index.html."
  echo "    Удали вручную:  ssh ${BEGET_USER}@${BEGET_HOST} \"rm ${HUB_PATH}/index.php\""
  echo "    Или подтверди, что это твой файл и оставь как есть."
  echo ""
fi

# ── Заливаем файлы ──────────────────────────────────────────────────────────
echo "📤 Заливаю ${LOCAL_INDEX}..."
scp "${LOCAL_INDEX}" "${BEGET_USER}@${BEGET_HOST}:${HUB_PATH}/index.html"

echo "📤 Заливаю ${LOCAL_KARTA}..."
scp "${LOCAL_KARTA}" "${BEGET_USER}@${BEGET_HOST}:${HUB_PATH}/karta-rosta.html"

echo ""
echo "✅ Готово!"
echo ""
echo "   🏠 https://${DOMAIN}/"
echo "   🗺  https://${DOMAIN}/karta-rosta.html"
echo ""
echo "   Проверка:"
echo "     curl -sk https://${DOMAIN}/ | head -20"
echo ""
echo "   Если видишь «Домен не прилинкован» — проверь в панели Beget,"
echo "   что домен ${DOMAIN} привязан к сайту ${DOMAIN}/public_html."
echo "   Если видишь «Сайт работает на Beget» — удали ${HUB_PATH}/index.php."
