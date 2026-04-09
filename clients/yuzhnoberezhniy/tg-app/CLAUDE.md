# Telegram Mini App — «Собери рюкзак» · Южнобережный

## Что это

Интерактивный чеклист сборов в лагерь «Республика ДОРИ», адаптированный под
Telegram Mini App. Открывается как в обычном браузере, так и прямо внутри Telegram.

---

## Структура файлов

```
tg-app/
├── index.html   — единственный файл приложения (CSS + HTML + JS всё внутри)
└── CLAUDE.md    — эта документация
```

Логика проекта: один самодостаточный HTML-файл, никаких внешних CSS/JS.

---

## Где что менять

### Контент чеклиста (пункты вещей)
Файл: `index.html`, секции `<!-- 📋 ДОКУМЕНТЫ -->`, `<!-- 👕 ОДЕЖДА -->` и т.д.

Каждый пункт — структура:
```html
<div class="item" onclick="toggleItem(this)" data-section="ИМЯ_СЕКЦИИ" data-art="EMOJI">
  <div class="checkbox"><svg class="check-svg" ...></svg></div>
  <div class="item-body">
    <div class="item-label">Текст пункта</div>
    <!-- опционально: -->
    <button class="tip-btn" onclick="showTip(event,this)">💡 Текст кнопки</button>
    <div class="tip-box">Текст подсказки</div>
    <div class="item-note">Мелкий пояснительный текст</div>
  </div>
</div>
```

- `data-section` — к какой секции относится: `docs | clothes | shoes | hygiene | backpack | extras`
- `data-art` — эмодзи-иллюстрация справа (любой emoji)
- Для пунктов только для девочек добавить класс `girl-only`

### Цвета бренда
Файл: `index.html`, секция `:root { ... }`:
```css
--c-green:  #179543;   /* здоровье */
--c-yellow: #e8960a;   /* радость */
--c-teal:   #33a5ad;   /* море */
--c-navy:   #3e3e86;   /* доверие */
```

### Цвет каждой секции
Ищи классы `.sec-docs`, `.sec-clothes` и т.д. — меняй `--sec-color` и `--sec-bg`.

### Контакты
- Телефон в шапке: `<a href="tel:+79787389618">`
- Телефон в блоке «Если забыли»: аналогично
- WhatsApp: `https://wa.me/79785500570`

### Блок «Санаторий обеспечивает»
Секция `<!-- САНАТОРИЙ ОБЕСПЕЧИВАЕТ -->` — редактируй `.provides-chip`.

### FAQ-подсказка (из brief.md)
Блок `.faq-hint` в конце страницы — напоминает о типовых вопросах родителей.

---

## Навигация / Экраны

Приложение однострановое. «Экраны» реализованы через аккордионы:

| Элемент | Класс | Поведение |
|---|---|---|
| Секция развёрнута | `.sec-card` | Показывает пункты |
| Секция свёрнута | `.sec-card.collapsed` | Скрывает `.sec-body` |
| Секция завершена | `.sec-card.done` | Граница + зелёный заголовок, автосворачивание |

---

## Telegram-специфичное

| Функция SDK | Где используется |
|---|---|
| `tg.ready()` | инициализация, говорит Telegram что app готово |
| `tg.expand()` | разворачивает на весь экран |
| `tg.setHeaderColor('#3e3e86')` | окрашивает шапку Telegram в navy |
| `tg.colorScheme` | автоматическое определение тёмной темы |
| `tg.MainButton` | зелёная кнопка «Закрыть» при 100% |
| `tg.BackButton` | кнопка «Назад» в шапке Telegram |
| `tg.HapticFeedback` | тактильная отдача на iOS при чекании |

---

## Хранение данных

Состояние чеклиста (галочки + пол) сохраняется в `localStorage`:
- Ключ: `yb-tg-checklist-v1`
- Формат: `{ checked: [0, 3, 7, ...], gender: 'boy' | 'girl' }`
- Сбрасывается кнопкой «↺ Сначала»

---

## Деплой

### Текущий хостинг (Beget)
Приложение нужно задеплоить в отдельную папку. Пример команд:
```bash
ssh icepaeqw_demo@<BEGET_HOST> "mkdir -p ~/yub-tg"
scp clients/yuzhnoberezhniy/tg-app/index.html \
    icepaeqw_demo@<BEGET_HOST>:~/yub-tg/
```

URL после деплоя: `https://demo.ideidlyabiznesa1913.ru/yub-tg/`

### Telegram Bot (когда будет готов)
1. @BotFather → `/newapp` → выбрать бота
2. Указать URL: `https://demo.ideidlyabiznesa1913.ru/yub-tg/`
3. Получить ссылку: `https://t.me/ИМЯ_БОТА/checklist`

---

## Тёмная тема

Автоматически применяется если:
- В Telegram: `tg.colorScheme === 'dark'`
- В браузере: `prefers-color-scheme: dark`

Управляется через `data-theme="dark"` на элементе `<html>`.
Все цвета адаптированы через CSS-переменные в `[data-theme="dark"]`.

---

## Связанные файлы проекта

| Файл | Роль |
|---|---|
| `clients/yuzhnoberezhniy/tg-app/index.html` | Этот Mini App |
| `clients/yuzhnoberezhniy/mvp/ryukzak.html` | Браузерная версия чеклиста |
| `clients/yuzhnoberezhniy/brand.md` | Бренд-стандарты и цвета |
| `clients/yuzhnoberezhniy/brief.md` | Бриф клиента |
| `deploy-yub.sh` | Деплой браузерной версии |
