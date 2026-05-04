# Спецификация админ-страницы календаря Ирины

> **Для кого:** Кодыч (Websites) — будет верстать единственный файл `admin.html`.
> **Связано с:** `BASEROW-SETUP.md` (поля таблиц), `legal/PD-AUDIT.md` (что нельзя забывать).

## Что это

Один HTML-файл (`admin/admin.html`) для Ирины. Открывается в браузере, читает Baserow REST API напрямую через её API-токен. Без бэкенда, без сборки, без фреймворков — чистый HTML+CSS+JS, тёмная палитра Ирины (хвоя/коралл/ваниль).

Хостится на Beget shared рядом с Mini App: `https://demo.ideidlyabiznesa1913.ru/cal/admin.html`.

## Защита

Простая, без бэкенда:

1. При первой загрузке — модалка «Введите API-токен Baserow». Поле + кнопка «Сохранить».
2. Токен пишется в `localStorage` под ключом `irina_calendar_admin_token`. Также сохраняем `BASEROW_URL`, `BASEROW_TABLE_BOOKINGS`, `BASEROW_TABLE_CLIENTS` в localStorage (или захардкодить в HTML — на выбор Кодыча, проще через localStorage).
3. Кнопка «Выйти» в правом верхнем углу — чистит localStorage.
4. Никакой OAuth, никакого «логин-пароль»: ввод API-токена = вход.

⚠️ HTTPS обязателен (Beget shared даёт SSL по умолчанию). По HTTP не открывать.

## Раскладка экранов

Один экран, четыре блока сверху вниз:

### Блок 1. Шапка
- Слева: «Календарь · админка»
- Справа: счётчик «новых» (заявки со status=new) и кнопка «Выйти»
- Палитра: фон ваниль `#FCFAE1`, заголовок хвоя `#306654`, акцент коралл `#FF935E`

### Блок 2. Фильтры
Строка с кнопками-табами (radio-буттоны на CSS):
- Все · Новые (default) · Подтверждённые · Завершённые · Отменённые

Дополнительно — выбор даты (`<input type="date">`, опционально, фильтрует по `slot_date`).

Кнопка «Закрыть слот вручную» — открывает модалку (Блок 4).

### Блок 3. Список заявок (карточки)

Каждая карточка — одна строка из `bookings`. Сортировка: новые сверху (по `created_at` desc).

Содержимое карточки:
- **Дата + время** крупно: `2026-05-10 · 14:00 (30 мин)`
- **Имя:** `Иван Иванов`
- **Контакт:** `Telegram: @ivan_ivanov`
- **Сообщение:** (свёрнуто, разворачивается по клику)
- **Источник:** `с сайта` / `из Telegram` / `из VK`
- **Статус-плашка:** new (коралл) / confirmed (хвоя) / done (серый) / cancelled (бледный)
- **Доп.строка** — «История клиента»: если по `contact_value` есть другие записи в `bookings` — показываем «у клиента N записей всего, последняя 2026-04-12». Считается **на фронте** одним отдельным запросом по фильтру `filter__contact_value__equal=...`.

Кнопки внизу карточки (видимость зависит от status):
- new → «Подтвердить» (станет confirmed) · «Отменить» (cancelled)
- confirmed → «Завершить» (done) · «Отменить» (cancelled)
- done / cancelled → только «Удалить» (с подтверждением)

При нажатии на кнопку — `PATCH /api/database/rows/table/<TABLE_BOOKINGS>/<rowId>/?user_field_names=true` с `{ "status": "<новый>" }`. Шапка `Authorization: Token <BASEROW_TOKEN>`.

### Блок 4. Модалка «Закрыть слот вручную»

Поля:
- Дата (date input)
- Время (text input, формат HH:MM)
- Длительность (number, default 30)
- Причина (text, опционально)

При сохранении — `POST /api/database/rows/table/<TABLE_BOOKINGS>/?user_field_names=true` с телом:
```json
{
  "slot_date": "2026-05-10",
  "slot_time": "14:00",
  "duration_min": 30,
  "name": "[блок]",
  "contact_method": "phone",
  "contact_value": "—",
  "message": "<причина>",
  "source": "website",
  "status": "blocked",
  "consent_given": true,
  "consent_text_version": "v1.0",
  "consent_timestamp": "<сейчас в ISO>",
  "consent_ip": "127.0.0.1"
}
```

`consent_given=true` ставим, чтобы обойти фильтр бота (это служебная запись Ирины, не клиент). `status=blocked` — фронт Mini App видит этот слот как занятый, бот не отправляет уведомление.

## API-вызовы (для Кодыча — копия в шпаргалку)

Все запросы к `${BASEROW_URL}/api/database/rows/table/${TABLE_BOOKINGS}/`:

| Действие | Метод | URL-suffix | Тело |
|---|---|---|---|
| Список (по фильтру) | GET | `?user_field_names=true&size=100&order_by=-created_at&filter__status__equal=new` | — |
| История клиента | GET | `?user_field_names=true&filter__contact_value__equal=<encoded>` | — |
| Сменить статус | PATCH | `<rowId>/?user_field_names=true` | `{ "status": "confirmed" }` |
| Удалить | DELETE | `<rowId>/` | — |
| Создать blocked-слот | POST | `?user_field_names=true` | см. выше |

Заголовок во всех: `Authorization: Token ${BASEROW_TOKEN}`.

## Поведение ошибок

- 401/403 → «Токен не подходит» + кнопка «Перевводи токен» (чистит localStorage).
- 429 → «Слишком часто, подожди 30 сек» + автоматический retry через 30 сек.
- network error → красная плашка «Нет связи с Baserow» + кнопка «Повторить».

## Что НЕ делать

- Не показывать `consent_ip` и `consent_*` поля в карточке — это служебные данные. Их видно только в Baserow.
- Не давать кнопку «Massовое удаление» — слишком опасно.
- Не выводить `BASEROW_TOKEN` нигде в DOM — только использовать в `fetch`.
- Не подключать никаких внешних библиотек / CDN — всё инлайн (политика проекта).

## Размер

Одна страница. ~600–800 строк HTML+CSS+JS. Адаптив: на телефоне Ирина тоже должна открывать.
