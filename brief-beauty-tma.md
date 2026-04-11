# Технический бриф: Beauty TMA — Каталог-запись для бьюти-мастера

**Версия:** 1.0 MVP
**Дата:** апрель 2026
**Основа:** research-beauty.md (4 агента-исследователя + 3 эксперта)
**Тип продукта:** Telegram Mini App (TMA), SaaS по подписке
**Язык интерфейса:** Русский

---

## КОНЦЕПЦИЯ

Telegram Mini App, открывающийся внутри Telegram — не веб-сайт в браузере.
Выглядит и ощущается как нативное мобильное приложение.
Мастер получает персональный каталог по ссылке: `t.me/BotName/app?startapp=master_123`
Клиент открывает → видит каталог мастера → записывается → получает подтверждение.

---

## ДИЗАЙН-СИСТЕМА

### Цвета — Telegram Native

Не задаём цвета жёстко. Используем CSS-переменные темы Telegram:

```css
:root {
  --bg:          var(--tg-theme-bg-color);           /* фон страницы */
  --bg-secondary: var(--tg-theme-secondary-bg-color);/* фон карточек */
  --text:        var(--tg-theme-text-color);          /* основной текст */
  --text-hint:   var(--tg-theme-hint-color);          /* второстепенный текст */
  --link:        var(--tg-theme-link-color);          /* ссылки */
  --btn:         var(--tg-theme-button-color);        /* кнопки */
  --btn-text:    var(--tg-theme-button-text-color);   /* текст кнопок */
  --accent:      #b49fd4;                             /* акцент бренда мастера */
}
```

Акцентный цвет (`--accent`) загружается из профиля мастера и может быть разным для каждого.

### Типографика

```css
font-family: -apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif;

--text-xs:   12px;   /* микротекст — только теги/метки */
--text-sm:   14px;   /* второстепенные подписи */
--text-base: 16px;   /* основной текст */
--text-lg:   18px;   /* подзаголовки */
--text-xl:   22px;   /* заголовки экранов */
--text-2xl:  28px;   /* имя мастера на главной */
```

### Эргономика — правило большого пальца

```css
--tap-target:  44px;   /* минимальный размер нажимаемого элемента */
--safe-bottom: 80px;   /* отступ снизу под MainButton */
--padding-x:   16px;   /* горизонтальные отступы */
--radius-sm:   8px;
--radius-md:   12px;
--radius-lg:   16px;
```

Все кнопки, карточки, слоты — минимум 44px по высоте.
Зона под MainButton всегда зарезервирована (80px снизу).

---

## СТРУКТУРА ЭКРАНОВ (User Flow)

```
[Экран 1: Главная — Витрина]
        ↓ (выбор категории)
[Экран 2: Список услуг в категории]
        ↓ (нажал на услугу)
[Экран 3: Карточка услуги + Галерея]
        ↓ (MainButton "Выбрать время")
[Экран 4: Выбор даты и времени]
        ↓ (MainButton "Подтвердить")
[Экран 5: Подтверждение записи]
        ↓ (MainButton "Записаться")
[Экран 6: Успех — запись создана]
```

Навигация назад — через `Telegram.WebApp.BackButton` (нативная кнопка Telegram).
Закрытие — через `Telegram.WebApp.close()` на экране успеха.

---

## ЭКРАН 1: Главная — Витрина мастера

### Что видит пользователь

**Шапка (Hero):**
- Фото мастера — круглый аватар, 80×80px
- Имя мастера — `var(--text-2xl)`, жирный
- Специализация — "Мастер маникюра · Москва", `var(--text-hint)`
- Опционально: короткое статус-сообщение ("Принимаю записи на май")

**Плитка категорий:**
- Крупные карточки — 2 в ряд, соотношение ~1:1 или ~4:3
- Каждая карточка: фоновое фото + название категории поверх + количество услуг
- Категории: Маникюр / Педикюр / Ногтевой дизайн / Укрепление и т.д.
- Карточки заполняют экран — нет пустого пространства внизу

**Нижний бар:**
- Кнопка "Записаться" — `Telegram.WebApp.MainButton`
- MainButton неактивна пока категория не выбрана (показываем, но `disable`)

### Интерактив

| Элемент | Действие | Переход |
|---|---|---|
| Карточка категории | Tap | → Экран 2: Список услуг |
| MainButton "Записаться" | Tap (пока disabled) | — |
| Аватар мастера | — | Нет действия в MVP |

### Технические детали

```javascript
// Инициализация при открытии TMA
const tg = window.Telegram.WebApp;
tg.ready();
tg.expand(); // раскрыть на весь экран

// Получаем ID мастера из deep link
const masterId = tg.initDataUnsafe?.start_param; // "master_123"

// Загружаем профиль мастера
const master = await api.getMaster(masterId);

// Применяем брендинг
if (master.accent_color) {
  document.documentElement.style.setProperty('--accent', master.accent_color);
}

// Настраиваем MainButton
tg.MainButton.setText('Записаться');
tg.MainButton.disable();
tg.MainButton.show();
```

```css
/* Плитка категорий */
.categories-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  padding: 0 var(--padding-x);
}

.category-card {
  position: relative;
  border-radius: var(--radius-lg);
  overflow: hidden;
  aspect-ratio: 4/3;
  min-height: 44px;
  cursor: pointer;
}

.category-card img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.category-card__label {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 24px 12px 12px;
  background: linear-gradient(transparent, rgba(0,0,0,0.7));
  color: #fff;
  font-size: var(--text-base);
  font-weight: 600;
}
```

---

## ЭКРАН 2: Список услуг в категории

### Что видит пользователь

**Заголовок:**
- Название категории — `var(--text-xl)`, жирный
- BackButton активирован (нативная кнопка ← в шапке Telegram)

**Список карточек услуг (вертикальный скролл):**

Карточка услуги — горизонтальная, высота 80px:
- Слева: квадратное фото услуги, 72×72px, `border-radius: 8px`
- Справа: название услуги (жирный, `var(--text-base)`), цена (жирный, `var(--accent)`), длительность (`var(--text-hint)`, `var(--text-sm)`)
- Справа-край: иконка `›` — chevron, `var(--text-hint)`
- Вся карточка нажимаемая (не только кнопка)

**Нижний бар:**
- MainButton: "Выбрать услугу" (disabled пока услуга не выбрана)

### Интерактив

| Элемент | Действие | Переход |
|---|---|---|
| Карточка услуги | Tap | → Экран 3: Карточка услуги |
| BackButton (Telegram) | Tap | ← Экран 1: Главная |
| MainButton | Tap (disabled) | — |

### Технические детали

```javascript
// Активируем BackButton при входе на экран
tg.BackButton.show();
tg.BackButton.onClick(() => showScreen('main'));

// Загружаем услуги категории
const services = await api.getServices(masterId, categoryId);

// Skeleton-экран пока грузится
showSkeleton(3); // показать 3 плейсхолдера
renderServices(services);
hideSkeleton();
```

```css
.service-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px var(--padding-x);
  min-height: 80px;
  background: var(--bg);
  border-bottom: 1px solid var(--bg-secondary);
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
}

.service-card:active {
  background: var(--bg-secondary); /* нажатое состояние */
}

.service-card__photo {
  width: 72px;
  height: 72px;
  border-radius: var(--radius-sm);
  object-fit: cover;
  flex-shrink: 0;
  background: var(--bg-secondary); /* плейсхолдер */
}

.service-card__price {
  color: var(--accent);
  font-weight: 700;
  font-size: var(--text-base);
}

.service-card__duration {
  color: var(--text-hint);
  font-size: var(--text-sm);
}
```

---

## ЭКРАН 3: Карточка услуги + Галерея работ

### Что видит пользователь

**Галерея (верхняя часть, ~55% экрана):**
- Горизонтальный свайп-слайдер фотографий работ мастера по данной услуге
- Индикатор слайдера (точки внизу галереи)
- Если фото нет — красивый плейсхолдер с акцентным цветом мастера и иконкой

**Информация об услуге:**
- Название — `var(--text-xl)`, жирный
- Цена — крупно, `var(--accent)`, `var(--text-xl)`
- Длительность — иконка часов + текст, `var(--text-hint)`
- Описание — максимум 3 строки, `var(--text-sm)`, с кнопкой "Читать далее" если длиннее
- Теги (опционально): `[Гель-лак]` `[Дизайн]` — мелкие пилюли

**Нижний бар:**
- MainButton: "Выбрать время" — активна всегда на этом экране

### Интерактив

| Элемент | Действие | Переход |
|---|---|---|
| Свайп галереи | Swipe left/right | Следующее/предыдущее фото |
| Tap на фото | Tap | Открыть полноэкранный просмотр (зум) |
| "Читать далее" | Tap | Раскрыть полное описание |
| MainButton "Выбрать время" | Tap | → Экран 4: Выбор даты |
| BackButton | Tap | ← Экран 2: Список услуг |

### Полноэкранный просмотр фото (overlay)

- Тёмный overlay на весь экран
- Фото на весь экран с возможностью pinch-to-zoom
- Свайп для переключения фото
- Закрыть — крест в правом верхнем углу или свайп вниз
- MainButton и BackButton скрываются при открытии просмотра

```javascript
// Галерея — реализация без библиотек
let currentPhotoIndex = 0;
const photos = service.portfolio_photos;

function openFullscreen(index) {
  currentPhotoIndex = index;
  tg.MainButton.hide();
  tg.BackButton.hide();
  showOverlay(photos[index]);
}

function closeFullscreen() {
  hideOverlay();
  tg.MainButton.show();
  tg.BackButton.show();
}

// Pinch-to-zoom через CSS transform
// touch-action: manipulation на фото-элементе
```

```css
/* Слайдер галереи */
.gallery {
  position: relative;
  width: 100%;
  aspect-ratio: 4/3;
  overflow: hidden;
}

.gallery__track {
  display: flex;
  transition: transform 0.3s ease;
  height: 100%;
}

.gallery__slide {
  flex-shrink: 0;
  width: 100%;
  height: 100%;
}

.gallery__slide img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gallery__dots {
  position: absolute;
  bottom: 8px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 4px;
}

.gallery__dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: rgba(255,255,255,0.5);
}

.gallery__dot--active {
  background: #fff;
}
```

---

## ЭКРАН 4: Выбор даты и времени

### Что видит пользователь

**Выбор даты — горизонтальный скролл:**
- Показываем 14 дней вперёд
- Каждый день — вертикальная таблетка: название дня ("Пн"), число ("14")
- Недоступные дни (выходные мастера) — серые, нажать нельзя
- Сегодня — особая метка "Сегодня"
- Выбранный день — заливка `var(--accent)`, белый текст

**Доступные слоты — сетка:**
- После выбора дня появляется сетка временных слотов
- Слоты плитками: `[10:00]` `[11:30]` `[13:00]` и т.д.
- Высота слота — 44px минимум, ширина — примерно 4 в ряд
- Занятые слоты — серый фон, крест или текст "Занято", нельзя нажать (но видны — показывают что мастер работает)
- Свободные — `var(--bg-secondary)`, рамка `var(--accent)` при выборе

**Нижний бар:**
- MainButton: "Подтвердить время" — disabled пока слот не выбран

### Интерактив

| Элемент | Действие | Эффект |
|---|---|---|
| День в горизонтальном скролле | Tap | Загрузить слоты этого дня |
| Свободный слот | Tap | Выделить + HapticFeedback + активировать MainButton |
| Занятый слот | — | Не реагирует (cursor: not-allowed) |
| MainButton "Подтвердить время" | Tap | → Экран 5: Подтверждение |
| BackButton | Tap | ← Экран 3: Карточка услуги |

### Haptic Feedback при выборе слота

```javascript
function selectSlot(slotId) {
  // 1. Убрать выделение с предыдущего слота
  document.querySelectorAll('.slot--selected')
    .forEach(el => el.classList.remove('slot--selected'));

  // 2. Выделить новый
  document.getElementById(slotId).classList.add('slot--selected');

  // 3. Виброотклик — тактильное подтверждение выбора
  tg.HapticFeedback.selectionChanged();

  // 4. Активировать MainButton
  selectedSlot = slotId;
  tg.MainButton.enable();
  tg.MainButton.setText('Подтвердить время');
}

// При смене дня — сбросить выбор слота
function selectDay(date) {
  selectedSlot = null;
  tg.MainButton.disable();
  loadSlots(date);
}
```

```css
/* Горизонтальный скролл дат */
.dates-scroll {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 12px var(--padding-x);
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.dates-scroll::-webkit-scrollbar { display: none; }

.date-pill {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 14px;
  border-radius: 20px;
  background: var(--bg-secondary);
  min-width: 48px;
  min-height: 60px;
  cursor: pointer;
  flex-shrink: 0;
  gap: 2px;
}

.date-pill--selected {
  background: var(--accent);
  color: #fff;
}

.date-pill--disabled {
  opacity: 0.4;
  pointer-events: none;
}

/* Сетка слотов */
.slots-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  padding: 0 var(--padding-x);
}

.slot {
  height: 44px;
  border-radius: var(--radius-sm);
  background: var(--bg-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--text-base);
  font-weight: 500;
  cursor: pointer;
  transition: background 0.15s;
}

.slot--selected {
  background: var(--accent);
  color: #fff;
}

.slot--taken {
  opacity: 0.4;
  pointer-events: none;
  position: relative;
}
```

---

## ЭКРАН 5: Подтверждение записи

### Что видит пользователь

**Резюме записи — карточка:**
- Услуга: название + цена
- Дата и время: "Пятница, 16 мая · 14:00"
- Мастер: имя + мини-аватар
- Длительность: "Примерно 90 минут"

**Поле для контакта:**
- Заголовок: "Ваш номер телефона"
- Пояснение: "Мастер может написать, если потребуется перенос"
- Поле input, type="tel", prefilled если Telegram предоставил номер
- Ниже — чекбокс "Запомнить номер для следующего раза"

**Примечание:**
- Маленький текст: "Нажимая «Записаться», вы соглашаетесь с условиями использования"

**Нижний бар:**
- MainButton: "Записаться" — активна всегда (если номер заполнен)

### Интерактив

| Элемент | Действие | Эффект |
|---|---|---|
| Поле телефона | Input | Валидация формата +7XXXXXXXXXX |
| MainButton "Записаться" | Tap | Отправить запись → показать loader → Экран 6: Успех |
| BackButton | Tap | ← Экран 4: Выбор времени |

```javascript
// Попытаться получить контакт из Telegram
const tgUser = tg.initDataUnsafe?.user;
if (tgUser?.phone_number) {
  phoneInput.value = tgUser.phone_number; // не всегда доступно
}

// Отправка записи
tg.MainButton.onClick(async () => {
  if (!validatePhone(phoneInput.value)) {
    phoneInput.classList.add('input--error');
    tg.HapticFeedback.notificationOccurred('error');
    return;
  }

  tg.MainButton.showProgress(true); // крутилка вместо текста
  tg.MainButton.disable();

  try {
    const booking = await api.createBooking({
      masterId,
      serviceId: selectedService.id,
      slotId: selectedSlot,
      phone: phoneInput.value,
      telegramUserId: tgUser?.id,
      telegramUsername: tgUser?.username,
    });

    tg.HapticFeedback.notificationOccurred('success');
    showScreen('success', booking);
  } catch (err) {
    tg.HapticFeedback.notificationOccurred('error');
    tg.MainButton.hideProgress();
    tg.MainButton.enable();
    showError('Не удалось создать запись. Попробуйте ещё раз.');
  }
});
```

---

## ЭКРАН 6: Успех — Запись создана

### Что видит пользователь

- Анимация успеха: зелёная галочка в круге (CSS-анимация, без библиотек)
- Заголовок: "Вы записаны!"
- Краткое резюме: услуга, дата, время, мастер
- Текст: "Мастер получил уведомление о вашей записи. Напоминание придёт сюда, в Telegram, за 24 часа."
- Кнопка "Добавить в календарь" (открывает календарь устройства через deeplink)

**Нижний бар:**
- MainButton: "Закрыть" — вызывает `tg.close()`
- BackButton: скрыт

```javascript
// Показ экрана успеха
function showSuccess(booking) {
  tg.BackButton.hide();

  tg.MainButton.hideProgress();
  tg.MainButton.setText('Готово');
  tg.MainButton.enable();
  tg.MainButton.onClick(() => tg.close());

  // Анимация галочки
  animateSuccess();

  // Deeplink в Google Calendar
  const calUrl = buildCalendarUrl(booking);
  document.getElementById('add-to-calendar').href = calUrl;
}

function buildCalendarUrl(booking) {
  const start = booking.datetime.replace(/[-:]/g, '');
  const end = addMinutes(booking.datetime, booking.duration);
  return `https://calendar.google.com/calendar/render?action=TEMPLATE` +
    `&text=${encodeURIComponent('Запись к ' + booking.master_name)}` +
    `&dates=${start}/${end}` +
    `&details=${encodeURIComponent(booking.service_name)}`;
}
```

---

## ЭЛЕМЕНТЫ И ДЕЙСТВИЯ — СВОДНАЯ ТАБЛИЦА

| Экран | Статичные элементы | Интерактив | Переход |
|---|---|---|---|
| 1. Главная | Аватар, имя, специализация, плитка категорий | Tap категории | → Экран 2 |
| 2. Список услуг | Карточки услуг (фото, название, цена, длительность) | Tap карточки | → Экран 3 |
| 3. Карточка услуги | Галерея фото, название, цена, длительность, описание | Свайп галереи, Tap фото (zoom), MainButton | Zoom overlay / → Экран 4 |
| 4. Выбор времени | Скролл дат, сетка слотов | Tap даты, Tap слота (HF), MainButton | → Экран 5 |
| 5. Подтверждение | Резюме записи, поле телефона | Input телефона, MainButton | → Экран 6 |
| 6. Успех | Анимация, резюме, "добавить в календарь" | MainButton "Готово", ссылка на календарь | tg.close() |

**BackButton:**
- Экран 2 → Экран 1
- Экран 3 → Экран 2
- Экран 4 → Экран 3
- Экран 5 → Экран 4
- Экран 6 → скрыт

---

## ЧЕГО НЕ БУДЕТ В MVP (Exclusion List)

### Отложено на V1.1

| Функция | Причина отсрочки |
|---|---|
| Онлайн-оплата услуг клиентом | Требует подключения платёжного провайдера + правовой аспект |
| Личный кабинет клиента с историей записей | Нужна авторизация и хранение данных клиентов |
| Отмена записи клиентом | Требует бизнес-логики (депозит, штрафы, уведомления) |
| Отзывы и рейтинги | Требует модерации |
| Фильтрация услуг по цене / длительности | Мало смысла при малом каталоге |
| Чат клиент-мастер внутри TMA | Для этого есть Telegram-чат |

### Отложено на V2.0

| Функция | Причина |
|---|---|
| Программа лояльности | Сложная бизнес-логика |
| Групповые записи (например, брови + маникюр) | Конфликты слотов, сложный UX |
| Мультимастер (несколько сотрудников) | Архитектурные изменения |
| Встроенная реклама / промоакции | Не нужно для PMF |
| Собственный бот на каждого мастера | Дорого, только для Premium-тарифа |
| Виджет для Instagram / сайта | Вне экосистемы Telegram |

---

## UI/UX ФИШКИ ДЛЯ БЬЮТИ

### 1. Просмотр портфолио — зум без библиотек

```javascript
// Полноэкранный просмотр с pinch-to-zoom
class PhotoViewer {
  constructor(photos) {
    this.photos = photos;
    this.scale = 1;
    this.isDragging = false;
  }

  open(index) {
    this.currentIndex = index;
    this.overlay = this.createOverlay();
    document.body.appendChild(this.overlay);
    this.bindGestures();

    // Запретить скролл body
    document.body.style.overflow = 'hidden';

    // Скрыть кнопки Telegram
    window.Telegram.WebApp.MainButton.hide();
    window.Telegram.WebApp.BackButton.hide();
  }

  close() {
    this.overlay.remove();
    document.body.style.overflow = '';
    window.Telegram.WebApp.MainButton.show();
    window.Telegram.WebApp.BackButton.show();
  }

  bindGestures() {
    const img = this.overlay.querySelector('.viewer__img');

    // Swipe down — закрыть
    let startY = 0;
    img.addEventListener('touchstart', e => startY = e.touches[0].clientY);
    img.addEventListener('touchend', e => {
      if (e.changedTouches[0].clientY - startY > 80) this.close();
    });

    // Pinch-to-zoom
    img.style.touchAction = 'manipulation';
    img.addEventListener('gesturechange', e => {
      this.scale = Math.max(1, Math.min(4, e.scale));
      img.style.transform = `scale(${this.scale})`;
    });
  }
}
```

### 2. Сторис-формат для портфолио (прогресс-бар)

Вместо слайдера с точками — формат историй: автопрокрутка с прогресс-баром сверху. Пользователь может тапнуть для переключения или зажать для паузы.

```javascript
class StoryGallery {
  constructor(photos, duration = 3000) {
    this.photos = photos;
    this.duration = duration;
    this.timer = null;
    this.currentIndex = 0;
  }

  start() {
    this.showPhoto(0);
    this.startProgress();
  }

  startProgress() {
    clearTimeout(this.timer);
    this.resetProgressBar();

    this.animateProgressBar(this.duration);

    this.timer = setTimeout(() => {
      if (this.currentIndex < this.photos.length - 1) {
        this.showPhoto(this.currentIndex + 1);
        this.startProgress();
      } else {
        this.onEnd(); // все фото просмотрены
      }
    }, this.duration);
  }

  pause() {
    clearTimeout(this.timer);
    this.pauseProgressBar();
  }

  resume() {
    this.startProgress();
  }
}
```

```css
/* Прогресс-бары сверху галереи */
.story-progress {
  position: absolute;
  top: 8px;
  left: 8px;
  right: 8px;
  display: flex;
  gap: 4px;
  z-index: 10;
}

.story-progress__bar {
  flex: 1;
  height: 2px;
  background: rgba(255,255,255,0.4);
  border-radius: 2px;
  overflow: hidden;
}

.story-progress__fill {
  height: 100%;
  background: #fff;
  width: 0%;
  transition: width linear;
}

.story-progress__fill--done { width: 100%; }
.story-progress__fill--active { /* управляется JS */ }
```

### 3. Haptic Feedback — полная карта вибраций

```javascript
const HF = window.Telegram.WebApp.HapticFeedback;

// Лёгкий тап — выбор элемента из списка
HF.selectionChanged();           // при выборе категории, услуги

// Выбор временного слота — чуть сильнее
HF.impactOccurred('light');      // при выборе слота

// Подтверждение — успех
HF.notificationOccurred('success'); // запись создана

// Ошибка — неверный телефон или слот занят
HF.notificationOccurred('error');

// Предупреждение — слот почти закончился
HF.notificationOccurred('warning');

// Закрытие оверлея фото — средний импакт
HF.impactOccurred('medium');
```

### 4. Skeleton-экраны вместо спиннеров

```css
/* Плейсхолдер для загрузки — пульсирующая анимация */
@keyframes skeleton-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

.skeleton {
  background: var(--bg-secondary);
  border-radius: var(--radius-sm);
  animation: skeleton-pulse 1.5s ease-in-out infinite;
}

.skeleton-card {
  display: flex;
  gap: 12px;
  padding: 12px var(--padding-x);
  align-items: center;
}

.skeleton-photo {
  width: 72px;
  height: 72px;
  border-radius: var(--radius-sm);
}

.skeleton-text-lg {
  height: 18px;
  width: 60%;
  border-radius: 4px;
}

.skeleton-text-sm {
  height: 14px;
  width: 40%;
  border-radius: 4px;
  margin-top: 6px;
}
```

### 5. Автосохранение черновика

```javascript
// Сохраняем промежуточный выбор в CloudStorage Telegram
// Если пользователь случайно закрыл TMA — восстанавливаем

const DRAFT_KEY = 'booking_draft_v1';

async function saveDraft() {
  const draft = {
    serviceId: selectedService?.id,
    slotId: selectedSlot,
    phone: phoneInput?.value,
    savedAt: Date.now(),
  };
  await tg.CloudStorage.setItem(DRAFT_KEY, JSON.stringify(draft));
}

async function loadDraft() {
  return new Promise(resolve => {
    tg.CloudStorage.getItem(DRAFT_KEY, (err, value) => {
      if (!value) return resolve(null);
      const draft = JSON.parse(value);
      // Черновик актуален 30 минут
      if (Date.now() - draft.savedAt > 30 * 60 * 1000) return resolve(null);
      resolve(draft);
    });
  });
}

// При закрытии — очищаем черновик
tg.onEvent('viewportChanged', saveDraft);
```

---

## API — ЭНДПОИНТЫ MVP

```
GET  /api/master/:id              → профиль мастера, брендинг
GET  /api/master/:id/categories   → список категорий услуг
GET  /api/master/:id/services/:categoryId → список услуг категории
GET  /api/service/:id             → карточка услуги + фото портфолио
GET  /api/slots/:masterId/:date   → доступные слоты на дату (формат YYYY-MM-DD)
POST /api/bookings                → создать запись
```

**Заголовки всех запросов:**
```
Authorization: tma <initData>    ← обязательная валидация на сервере
Content-Type: application/json
```

**Пример запроса создания записи:**
```json
POST /api/bookings
{
  "master_id": "master_123",
  "service_id": "svc_456",
  "slot_id": "slot_789",
  "client_phone": "+79001234567",
  "client_telegram_id": 123456789,
  "client_telegram_username": "anna_nails"
}
```

**Ответ:**
```json
{
  "booking_id": "book_001",
  "status": "confirmed",
  "master_name": "Анна Смирнова",
  "service_name": "Маникюр гель-лак",
  "datetime": "2026-05-16T14:00:00",
  "duration_minutes": 90,
  "price": 2000
}
```

---

## БЕЗОПАСНОСТЬ — КРИТИЧНО

### Валидация initData на каждый запрос

```javascript
// server.js — middleware
import crypto from 'crypto';

function validateTelegramInitData(initData, botToken) {
  const params = new URLSearchParams(initData);
  const hash = params.get('hash');
  params.delete('hash');

  const dataCheckString = [...params.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}=${v}`)
    .join('\n');

  const secretKey = crypto.createHmac('sha256', 'WebAppData')
    .update(botToken).digest();

  const expectedHash = crypto.createHmac('sha256', secretKey)
    .update(dataCheckString).digest('hex');

  if (hash !== expectedHash) throw new Error('Invalid initData signature');

  const authDate = parseInt(params.get('auth_date'));
  if (Date.now() / 1000 - authDate > 300) throw new Error('initData expired');

  return JSON.parse(params.get('user'));
}

// Middleware для всех защищённых роутов
app.use('/api', (req, res, next) => {
  const initData = req.headers.authorization?.replace('tma ', '');
  if (!initData) return res.status(401).json({ error: 'No auth' });

  try {
    req.tgUser = validateTelegramInitData(initData, process.env.BOT_TOKEN);
    next();
  } catch {
    res.status(403).json({ error: 'Invalid auth' });
  }
});
```

---

## СТРУКТУРА ФАЙЛОВ ПРОЕКТА

```
beauty-tma/
├── index.html              ← единая точка входа
├── src/
│   ├── main.js             ← инициализация TMA, router
│   ├── api.js              ← все запросы к серверу
│   ├── screens/
│   │   ├── main.js         ← Экран 1: Главная
│   │   ├── services.js     ← Экран 2: Список услуг
│   │   ├── service.js      ← Экран 3: Карточка услуги
│   │   ├── slots.js        ← Экран 4: Выбор времени
│   │   ├── confirm.js      ← Экран 5: Подтверждение
│   │   └── success.js      ← Экран 6: Успех
│   ├── components/
│   │   ├── gallery.js      ← Слайдер + полноэкранный просмотр
│   │   ├── story.js        ← Сторис-формат портфолио
│   │   ├── skeleton.js     ← Skeleton-экраны
│   │   └── draft.js        ← Автосохранение черновика
│   └── styles/
│       ├── variables.css   ← CSS-переменные (тема + брендинг)
│       ├── base.css        ← Сброс + типографика + эргономика
│       ├── screens.css     ← Стили экранов
│       └── components.css  ← Галерея, слоты, карточки
└── server/
    ├── index.js            ← Express сервер
    ├── middleware/auth.js  ← Валидация initData
    ├── routes/
    │   ├── masters.js
    │   ├── services.js
    │   ├── slots.js
    │   └── bookings.js
    └── db/                 ← Модели и запросы к PostgreSQL
```

---

## ЧЕКЛИСТ ПЕРЕД ЗАПУСКОМ MVP

- [ ] `tg.ready()` и `tg.expand()` вызываются при старте
- [ ] Все цвета через CSS-переменные Telegram, не жёсткие hex
- [ ] `initData` валидируется на сервере для каждого API-запроса
- [ ] MainButton и BackButton управляются на каждом экране
- [ ] HapticFeedback подключён на все ключевые действия
- [ ] Skeleton-экраны на всех экранах с загрузкой данных
- [ ] Автосохранение черновика в CloudStorage
- [ ] Минимальный tap target 44px проверен на реальном телефоне
- [ ] Зарезервировано 80px снизу под MainButton на всех экранах
- [ ] Протестировано в тёмной теме Telegram
- [ ] `tg.close()` вызывается на экране успеха
