#!/bin/bash
# deploy-stydiyatsi.sh — деплой визитки Ирины на stydiyatsi.ru через Beget SSH
#
# Запуск из корня репо:
#   ./deploy-stydiyatsi.sh
#
# Что нужно в .env:
#   BEGET_HOST              — хост Beget (уже есть, используется другими скриптами)
#   STYDIYATSI_USER         — SSH-пользователь Beget для stydiyatsi.ru (обычно icepaeqw)
#   STYDIYATSI_PATH         — папка на сервере (обычно ~/stydiyatsi.ru/public_html или /home/i/icepaeqw/stydiyatsi.ru/public_html)
#
# Что льётся:
#   clients/irina/index.html → корень public_html/
#   clients/irina/assets/    → public_html/assets/

set -e

# ── Загрузка .env ───────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "❌ Файл .env не найден в текущей папке."
  echo "   Запускай из корня репозитория my-architecture/"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

# ── Проверка переменных ─────────────────────────────────────────────────────
: "${BEGET_HOST:?❌ Укажи BEGET_HOST в .env}"
: "${STYDIYATSI_USER:?❌ Добавь STYDIYATSI_USER в .env (обычно icepaeqw)}"
: "${STYDIYATSI_PATH:?❌ Добавь STYDIYATSI_PATH в .env (обычно stydiyatsi.ru/public_html)}"

# ── Проверка локальных файлов ───────────────────────────────────────────────
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

# ── Информация о деплое ─────────────────────────────────────────────────────
echo "🚀 Деплой визитки Ирины"
echo "   Откуда: ${LOCAL_HTML} + ${LOCAL_ASSETS}/"
echo "   Куда:   ${STYDIYATSI_USER}@${BEGET_HOST}:${STYDIYATSI_PATH}/"
echo "   URL:    https://stydiyatsi.ru"
echo ""

# ── Создаём папку assets на сервере (если не было) ──────────────────────────
ssh "${STYDIYATSI_USER}@${BEGET_HOST}" "mkdir -p ${STYDIYATSI_PATH}/assets"

# ── Заливаем index.html ─────────────────────────────────────────────────────
echo "📤 Заливаю index.html..."
scp "${LOCAL_HTML}" "${STYDIYATSI_USER}@${BEGET_HOST}:${STYDIYATSI_PATH}/index.html"

# ── Заливаем assets/ ────────────────────────────────────────────────────────
echo "📤 Заливаю assets/..."
scp -r "${LOCAL_ASSETS}/" "${STYDIYATSI_USER}@${BEGET_HOST}:${STYDIYATSI_PATH}/"

echo ""
echo "✅ Готово!"
echo ""
echo "   🏠 https://stydiyatsi.ru"
echo ""
echo "   Если открывается старая Apache 403 — проверь в панели Beget,"
echo "   что DocumentRoot домена stydiyatsi.ru указывает на ${STYDIYATSI_PATH}/"
