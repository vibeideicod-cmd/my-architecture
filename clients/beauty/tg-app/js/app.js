// ============================================================
// app.js — Логика Beauty TMA
// Стек: vanilla JS, без фреймворков
// Источник: brief-beauty-tma.md, tma-spec.md (UX-фиксы)
// ============================================================

'use strict';

// ── Telegram WebApp SDK ──────────────────────────────────
const tg = window.Telegram?.WebApp;

// Инициализация Telegram
function initTelegram() {
  if (!tg) return;
  tg.ready();
  tg.expand(); // на весь экран
}

// Обёртки над MainButton
const MainButton = {
  show(text, onClick) {
    if (!tg) return;
    tg.MainButton.setText(text);
    tg.MainButton.show();
    if (onClick) {
      tg.MainButton.offClick(state.mainButtonHandler);
      state.mainButtonHandler = onClick;
      tg.MainButton.onClick(state.mainButtonHandler);
    }
  },
  hide() {
    if (!tg) return;
    tg.MainButton.hide();
  },
  enable() {
    if (!tg) return;
    tg.MainButton.enable();
  },
  disable() {
    if (!tg) return;
    tg.MainButton.disable();
  },
  showProgress() {
    if (!tg) return;
    tg.MainButton.showProgress(true);
  },
  hideProgress() {
    if (!tg) return;
    tg.MainButton.hideProgress();
  },
};

// Обёртки над BackButton
const BackButton = {
  show(onClick) {
    if (!tg) return;
    tg.BackButton.show();
    tg.BackButton.offClick(state.backButtonHandler);
    state.backButtonHandler = onClick;
    tg.BackButton.onClick(state.backButtonHandler);
  },
  hide() {
    if (!tg) return;
    tg.BackButton.hide();
  },
};

// Haptic Feedback
const Haptic = {
  select() { tg?.HapticFeedback?.selectionChanged(); },
  success() { tg?.HapticFeedback?.notificationOccurred('success'); },
  error()   { tg?.HapticFeedback?.notificationOccurred('error'); },
  tap()     { tg?.HapticFeedback?.impactOccurred('light'); },
};

// ── State ────────────────────────────────────────────────
const state = {
  currentScreen:    'loading',
  mainButtonHandler: null,
  backButtonHandler: null,

  // Данные сессии
  selectedCategory: null,  // { id, name, icon }
  selectedService:  null,  // объект услуги
  selectedDate:     null,  // '2026-04-14'
  selectedSlot:     null,  // '14:00'
  bookingResult:    null,  // объект после создания записи
};

// ── Навигация ────────────────────────────────────────────
// Переход между экранами с fade-анимацией
function navigate(screenId) {
  const current = document.querySelector('.screen.is-active');
  const next = document.getElementById(`screen-${screenId}`);

  if (!next) { console.warn('Экран не найден:', screenId); return; }

  if (current) {
    current.classList.add('is-exiting');
    current.classList.remove('is-active');
    setTimeout(() => current.classList.remove('is-exiting'), 250);
  }

  // requestAnimationFrame для плавности
  requestAnimationFrame(() => {
    next.classList.add('is-active');
    next.scrollTop = 0;
  });

  state.currentScreen = screenId;
}

// ── ─────────────────────────────────────────────────────
// ЭКРАН 1: Главная
// ─────────────────────────────────────────────────────── */
function initScreen_index() {
  // Применяем брендинг мастера
  applyBranding(MASTER.accent);

  // Заполняем шапку
  document.getElementById('master-name').textContent = MASTER.name;
  document.getElementById('master-specialty').textContent =
    MASTER.specialty + ' · ' + MASTER.city;
  document.getElementById('master-status').textContent = MASTER.status;

  // Bio с кнопкой "Читать далее"
  const bioEl  = document.getElementById('master-bio');
  const bioBtn = document.getElementById('master-bio-expand-btn');
  if (MASTER.bio) {
    bioEl.textContent = MASTER.bio;
    // Показываем кнопку только если текст обрезан (больше 2 строк)
    requestAnimationFrame(() => {
      if (bioEl.scrollHeight > bioEl.clientHeight + 2) {
        bioBtn.style.display = 'block';
      } else {
        bioBtn.style.display = 'none';
      }
    });
    bioBtn.onclick = () => {
      bioEl.classList.toggle('is-expanded');
      bioBtn.textContent = bioEl.classList.contains('is-expanded')
        ? 'Свернуть ↑' : 'Читать далее ↓';
    };
  } else {
    document.getElementById('master-bio-wrap').style.display = 'none';
  }

  // "Мои записи" — показываем если есть сохранённая запись
  const lastBooking = loadLastBooking();
  const myBookingsRow = document.getElementById('my-bookings-row');
  const myBookingsBtn = document.getElementById('my-bookings-btn');
  if (lastBooking) {
    myBookingsRow.style.display = 'block';
    myBookingsBtn.querySelector('.my-bookings-chevron').textContent = '›';
    // Обновляем текст кнопки
    myBookingsBtn.firstChild.textContent = `📋 ${lastBooking.service} — ${lastBooking.date.split('·')[1]?.trim() || ''}  `;
    myBookingsBtn.onclick = () => {
      Haptic.tap();
      state.bookingResult = lastBooking;
      navigate('success');
      initScreen_success();
    };
  } else {
    myBookingsRow.style.display = 'none';
  }

  // Рендерим плитку категорий
  const grid = document.getElementById('categories-grid');
  grid.innerHTML = '';
  CATEGORIES.forEach(cat => {
    const card = createCategoryCard(cat);
    card.addEventListener('click', () => {
      Haptic.tap();
      state.selectedCategory = cat;
      navigate('services');
      initScreen_services();
    });
    grid.appendChild(card);
  });

  // MainButton скрыта на главной
  MainButton.hide();
  BackButton.hide();

  navigate('index');
}

// Сохраняем/читаем последнюю запись в localStorage
const BOOKING_KEY = 'beauty-tma-last-booking-v1';
function saveLastBooking(booking) {
  try { localStorage.setItem(BOOKING_KEY, JSON.stringify(booking)); } catch {}
}
function loadLastBooking() {
  try {
    const raw = localStorage.getItem(BOOKING_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
}

function createCategoryCard(cat) {
  const div = document.createElement('div');
  div.className = 'category-card';
  div.setAttribute('role', 'button');
  div.setAttribute('aria-label', cat.name);
  div.setAttribute('data-cat', cat.id);

  const price = cat.min_price.toLocaleString('ru-RU');
  const meta  = `от ${price} ₽ · ${cat.count} услуг`;

  // Фон с emoji-иконкой вместо фото (для MVP без изображений)
  div.innerHTML = `
    <div class="category-card__bg">${cat.icon}</div>
    <div class="category-card__label">
      <div class="category-card__name">${cat.name}</div>
      <div class="category-card__meta">${meta}</div>
    </div>
  `;
  return div;
}

function applyBranding(color) {
  if (!color) return;
  document.documentElement.style.setProperty('--accent', color);
  // Пересчитываем RGB для rgba()-свойств
  const rgb = hexToRgb(color);
  if (rgb) {
    document.documentElement.style.setProperty(
      '--accent-rgb', `${rgb.r}, ${rgb.g}, ${rgb.b}`
    );
  }
}

function hexToRgb(hex) {
  const m = hex.replace('#', '').match(/.{2}/g);
  if (!m) return null;
  return { r: parseInt(m[0], 16), g: parseInt(m[1], 16), b: parseInt(m[2], 16) };
}

// ── ─────────────────────────────────────────────────────
// ЭКРАН 2: Список услуг
// ─────────────────────────────────────────────────────── */
function initScreen_services() {
  const cat = state.selectedCategory;

  // Заголовок
  document.getElementById('services-title').textContent = cat.name;

  // Скелетон пока "грузится"
  const list = document.getElementById('services-list');
  list.innerHTML = renderSkeletons(3);

  // Имитируем задержку загрузки (в реальном API — fetch)
  setTimeout(() => {
    const services = SERVICES[cat.id] || [];
    list.innerHTML = '';

    if (services.length === 0) {
      list.innerHTML = `<li style="padding:32px 16px;text-align:center;color:var(--tg-hint)">
        Услуги скоро появятся
      </li>`;
    } else {
      services.forEach(svc => {
        const li = createServiceCard(svc);
        li.addEventListener('click', () => {
          Haptic.tap();
          state.selectedService = svc;
          navigate('details');
          initScreen_details();
        });
        list.appendChild(li);
      });
    }
  }, 350);

  // MainButton — выключена пока не выбрана услуга
  MainButton.show('Выбрать услугу', null);
  MainButton.disable();

  // BackButton → главная
  BackButton.show(() => {
    navigate('index');
    MainButton.disable();
  });
}

function createServiceCard(svc) {
  const li = document.createElement('li');
  li.className = 'service-card';

  const price    = formatPrice(svc);
  const duration = formatDuration(svc.duration);

  li.innerHTML = `
    <div class="service-card__thumb">${svc.icon || '💅'}</div>
    <div class="service-card__body">
      <div class="service-card__name">${svc.name}</div>
      <div class="service-card__price">${price}</div>
      <div class="service-card__duration">⏱ ${duration}</div>
    </div>
    <div class="service-card__chevron">›</div>
  `;
  return li;
}

function renderSkeletons(n) {
  return Array.from({ length: n }, () => `
    <li class="skeleton-service">
      <div class="skeleton skeleton-thumb"></div>
      <div class="skeleton-lines">
        <div class="skeleton skeleton-line"></div>
        <div class="skeleton skeleton-line"></div>
        <div class="skeleton skeleton-line"></div>
      </div>
    </li>
  `).join('');
}

// ── ─────────────────────────────────────────────────────
// ЭКРАН 3: Карточка услуги + галерея
// ─────────────────────────────────────────────────────── */
function initScreen_details() {
  const svc = state.selectedService;

  // Галерея
  const photos = (svc.photos && svc.photos.length > 0) ? svc.photos : null;
  initGallery(photos);

  // Детали
  document.getElementById('detail-name').textContent     = svc.name;
  document.getElementById('detail-price').textContent    = formatPrice(svc);
  document.getElementById('detail-duration').textContent = '⏱ ' + formatDuration(svc.duration);
  document.getElementById('detail-desc').textContent     = svc.description;

  // Описание с кнопкой "Читать полностью"
  const descEl  = document.getElementById('detail-desc');
  const descBtn = document.getElementById('detail-desc-expand');
  descEl.classList.remove('is-expanded');
  descBtn.style.display = 'none';
  descBtn.textContent = 'Читать полностью ↓';

  requestAnimationFrame(() => {
    if (descEl.scrollHeight > descEl.clientHeight + 2) {
      descBtn.style.display = 'block';
    }
  });

  descBtn.onclick = () => {
    descEl.classList.toggle('is-expanded');
    descBtn.textContent = descEl.classList.contains('is-expanded')
      ? 'Свернуть ↑' : 'Читать полностью ↓';
  };

  // Теги
  const tagsEl = document.getElementById('detail-tags');
  tagsEl.innerHTML = '';
  (svc.tags || []).forEach(tag => {
    const span = document.createElement('span');
    span.className = 'tag';
    span.textContent = tag;
    tagsEl.appendChild(span);
  });

  // MainButton — всегда активна на деталях
  MainButton.show('Выбрать время', () => {
    Haptic.tap();
    navigate('booking');
    initScreen_booking();
  });
  MainButton.enable();

  // BackButton → список услуг
  BackButton.show(() => {
    navigate('services');
    MainButton.show('Выбрать услугу', null);
    MainButton.disable();
  });
}

// ── Галерея (без библиотек) ──────────────────────────────
let galleryState = { photos: [], current: 0, startX: 0, isDragging: false };

function initGallery(photos) {
  const track  = document.getElementById('gallery-track');
  const dots   = document.getElementById('gallery-dots');
  const counter = document.getElementById('gallery-counter');

  // Если фото нет — эмодзи-заглушка
  if (!photos || photos.length === 0) {
    galleryState.photos = [];
    track.innerHTML = `<div class="gallery__slide">${state.selectedService?.icon || '💅'}</div>`;
    dots.innerHTML  = '';
    counter.style.display = 'none';
    return;
  }

  galleryState.photos  = photos;
  galleryState.current = 0;

  // Слайды
  track.innerHTML = photos.map((src, i) => `
    <div class="gallery__slide">
      <img src="${src}" alt="Работа ${i + 1}" loading="lazy"
           onerror="this.parentNode.innerHTML='${state.selectedService?.icon || '💅'}'">
    </div>
  `).join('');

  // Точки
  dots.innerHTML = photos.map((_, i) =>
    `<div class="gallery__dot${i === 0 ? ' is-active' : ''}"></div>`
  ).join('');

  // Счётчик
  counter.textContent   = `1 / ${photos.length}`;
  counter.style.display = photos.length > 1 ? 'block' : 'none';

  // Touch-события
  const gallery = document.getElementById('gallery');
  gallery.addEventListener('touchstart', onGalleryTouchStart, { passive: true });
  gallery.addEventListener('touchend',   onGalleryTouchEnd,   { passive: true });
  gallery.addEventListener('click', () => openFullscreen(galleryState.current));
}

function onGalleryTouchStart(e) {
  galleryState.startX = e.touches[0].clientX;
}

function onGalleryTouchEnd(e) {
  const dx = e.changedTouches[0].clientX - galleryState.startX;
  if (Math.abs(dx) > 40) {
    if (dx < 0) moveGallery(1);
    else moveGallery(-1);
  }
}

function moveGallery(dir) {
  const n = galleryState.photos.length;
  if (n === 0) return;
  galleryState.current = (galleryState.current + dir + n) % n;
  updateGalleryUI();
  Haptic.select();
}

function updateGalleryUI() {
  const i = galleryState.current;
  const track  = document.getElementById('gallery-track');
  const dots   = document.querySelectorAll('.gallery__dot');
  const counter = document.getElementById('gallery-counter');

  track.style.transform = `translateX(-${i * 100}%)`;

  dots.forEach((d, idx) => {
    d.classList.toggle('is-active', idx === i);
  });

  counter.textContent = `${i + 1} / ${galleryState.photos.length}`;
}

// Fullscreen просмотр
function openFullscreen(index) {
  const photos = galleryState.photos;
  if (!photos.length) return;

  const overlay = document.getElementById('fullscreen-overlay');
  const img     = document.getElementById('fullscreen-img');

  img.src = photos[index];
  overlay.classList.add('is-open');

  MainButton.hide();
  BackButton.hide();
}

function closeFullscreen() {
  const overlay = document.getElementById('fullscreen-overlay');
  overlay.classList.remove('is-open');

  MainButton.show('Выбрать время', () => {
    navigate('booking');
    initScreen_booking();
  });
  MainButton.enable();

  BackButton.show(() => {
    navigate('services');
    MainButton.show('Выбрать услугу', null);
    MainButton.disable();
  });
}

// ── ─────────────────────────────────────────────────────
// ЭКРАН 4: Выбор даты и времени
// ─────────────────────────────────────────────────────── */
function initScreen_booking() {
  state.selectedDate = null;
  state.selectedSlot = null;

  renderDates();
  document.getElementById('slots-container').innerHTML =
    `<p style="color:var(--tg-hint);font-size:14px;text-align:center;padding:20px">
      Выберите дату
    </p>`;

  MainButton.show('Подтвердить время', null);
  MainButton.disable();

  BackButton.show(() => {
    navigate('details');
    MainButton.show('Выбрать время', () => {
      navigate('booking');
      initScreen_booking();
    });
    MainButton.enable();
  });
}

function renderDates() {
  const scroll = document.getElementById('dates-scroll');
  scroll.innerHTML = '';
  const days = getNext14Days();

  days.forEach(day => {
    const pill = document.createElement('div');
    pill.className = 'date-pill' +
      (day.isToday  ? ' is-today'    : '') +
      (day.disabled ? ' is-disabled' : '');

    pill.innerHTML = `
      <span class="date-pill__day">${day.dayName}</span>
      <span class="date-pill__num">${day.dayNum}</span>
      <span class="date-pill__month">${day.month}</span>
    `;

    if (!day.disabled) {
      pill.addEventListener('click', () => {
        Haptic.select();
        document.querySelectorAll('.date-pill').forEach(p =>
          p.classList.remove('is-selected'));
        pill.classList.add('is-selected');

        state.selectedDate = day.dateStr;
        state.selectedSlot = null;
        MainButton.disable();

        renderSlots(day.dateStr);
      });
    }

    scroll.appendChild(pill);
  });
}

function renderSlots(dateStr) {
  const container = document.getElementById('slots-container');
  const slots = getMockSlots(dateStr);

  if (slots.length === 0) {
    // Пустой день — показываем ближайший свободный
    const next = getNextAvailableSlot(dateStr);
    if (next) {
      container.innerHTML = `
        <div class="empty-slots">
          <div class="empty-slots__icon">📅</div>
          <p class="empty-slots__text">На этот день нет свободных мест</p>
          <button class="empty-slots__next" id="next-slot-btn">
            ближайшее: ${next.label} →
          </button>
        </div>
      `;
      document.getElementById('next-slot-btn').addEventListener('click', () => {
        Haptic.tap();
        jumpToDate(next.date, next.time);
      });
    } else {
      container.innerHTML = `
        <div class="empty-slots">
          <div class="empty-slots__icon">😔</div>
          <p class="empty-slots__text">Ближайших свободных мест нет</p>
        </div>
      `;
    }
    return;
  }

  container.innerHTML = `<div class="slots-grid" id="slots-grid"></div>`;
  const grid = document.getElementById('slots-grid');

  slots.forEach(s => {
    const slot = document.createElement('div');
    slot.className = 'slot';
    slot.textContent = s.time;
    slot.addEventListener('click', () => {
      Haptic.select();
      document.querySelectorAll('.slot').forEach(el => el.classList.remove('is-selected'));
      slot.classList.add('is-selected');

      state.selectedSlot = s.time;
      MainButton.show('Подтвердить время', () => {
        Haptic.tap();
        navigate('confirm');
        initScreen_confirm();
      });
      MainButton.enable();
    });
    grid.appendChild(slot);
  });
}

// Прыжок к конкретной дате (из next-available)
function jumpToDate(dateStr, timeStr) {
  const pills = document.querySelectorAll('.date-pill');
  const days  = getNext14Days();

  const idx = days.findIndex(d => d.dateStr === dateStr);
  if (idx >= 0 && !days[idx].disabled) {
    pills.forEach(p => p.classList.remove('is-selected'));
    if (pills[idx]) pills[idx].classList.add('is-selected');
  }

  state.selectedDate = dateStr;
  state.selectedSlot = null;
  MainButton.disable();
  renderSlots(dateStr);

  // После рендера слотов — выбираем нужный
  setTimeout(() => {
    const slotEls = document.querySelectorAll('.slot');
    slotEls.forEach(el => {
      if (el.textContent === timeStr) el.click();
    });
  }, 50);
}

// ── ─────────────────────────────────────────────────────
// ЭКРАН 5: Подтверждение
// ─────────────────────────────────────────────────────── */
function initScreen_confirm() {
  const svc  = state.selectedService;
  const date = formatDateFull(state.selectedDate, state.selectedSlot);

  // Заполняем резюме
  document.getElementById('confirm-service').textContent  = svc.name;
  document.getElementById('confirm-price').textContent    = formatPrice(svc);
  document.getElementById('confirm-datetime').textContent = date;
  document.getElementById('confirm-master').textContent   = MASTER.name;
  document.getElementById('confirm-duration').textContent = formatDuration(svc.duration);

  // Телефон — пытаемся prefill из TG
  const phoneInput = document.getElementById('phone-input');
  phoneInput.value = '';
  const tgPhone = tg?.initDataUnsafe?.user?.phone_number;
  if (tgPhone) phoneInput.value = tgPhone;

  // Слушатель ввода телефона
  phoneInput.removeEventListener('input', onPhoneInput);
  phoneInput.addEventListener('input', onPhoneInput);

  // MainButton
  const hasPhone = phoneInput.value.trim().length > 5;
  if (hasPhone) MainButton.enable();
  else          MainButton.disable();

  MainButton.show('Записаться', handleConfirmSubmit);

  BackButton.show(() => {
    navigate('booking');
    initScreen_booking();
  });
}

function onPhoneInput() {
  const val = document.getElementById('phone-input').value.trim();
  if (val.length > 5) MainButton.enable();
  else                MainButton.disable();
}

async function handleConfirmSubmit() {
  const phone = document.getElementById('phone-input').value.trim();
  const phoneInput = document.getElementById('phone-input');

  if (!validatePhone(phone)) {
    phoneInput.classList.add('is-error');
    Haptic.error();
    return;
  }

  phoneInput.classList.remove('is-error');
  MainButton.showProgress();
  MainButton.disable();

  // Имитируем запрос к API
  await delay(900);

  Haptic.success();

  // Формируем объект записи
  state.bookingResult = {
    service:    state.selectedService.name,
    price:      formatPrice(state.selectedService),
    date:       formatDateFull(state.selectedDate, state.selectedSlot),
    master:     MASTER.name,
    duration:   formatDuration(state.selectedService.duration),
    datetime:   state.selectedDate + 'T' + state.selectedSlot + ':00',
    phone,
  };

  // Сохраняем для «Мои записи» на главной
  saveLastBooking(state.bookingResult);

  navigate('success');
  initScreen_success();
}

function validatePhone(val) {
  // Принимаем: +7XXXXXXXXXX, 8XXXXXXXXXX, или просто 10+ цифр
  const clean = val.replace(/[\s\-()]/g, '');
  return /^(\+7|8)\d{10}$/.test(clean) || /^\d{10,}$/.test(clean);
}

// ── ─────────────────────────────────────────────────────
// ЭКРАН 6: Успех
// ─────────────────────────────────────────────────────── */
function initScreen_success() {
  const b = state.bookingResult;

  // Карточка записи
  document.getElementById('success-service').textContent  = b.service;
  document.getElementById('success-datetime').textContent = b.date;
  document.getElementById('success-master').textContent   = b.master;
  document.getElementById('success-duration').textContent = b.duration;

  // Ссылка "добавить в Google Calendar"
  const calBtn = document.getElementById('btn-calendar');
  calBtn.href  = buildCalendarUrl(b);

  // MainButton — закрыть
  MainButton.hideProgress();
  MainButton.show('Готово', () => {
    Haptic.tap();
    if (tg) tg.close();
  });
  MainButton.enable();

  // Кнопка "назад в каталог"
  document.getElementById('btn-back-catalog').addEventListener('click', () => {
    Haptic.tap();
    state.selectedCategory = null;
    state.selectedService  = null;
    state.selectedDate     = null;
    state.selectedSlot     = null;
    state.bookingResult    = null;
    initScreen_index();
  });

  // BackButton скрыт на экране успеха
  BackButton.hide();

  // Анимация галочки запустится через CSS (stroke-dashoffset)
  // Перезапускаем анимацию
  const svg = document.getElementById('success-svg');
  if (svg) {
    svg.style.animation = 'none';
    svg.querySelectorAll('[class*="check"]').forEach(el => {
      el.style.animation = 'none';
      // Trigger reflow
      void el.offsetWidth;
      el.style.animation = '';
    });
  }
}

function buildCalendarUrl(booking) {
  const dt    = booking.datetime.replace(/[-:]/g, '').split('T');
  const start = dt[0] + 'T' + dt[1].replace(/\D/g, '').slice(0, 4) + '00Z';
  return 'https://calendar.google.com/calendar/render?action=TEMPLATE' +
    `&text=${encodeURIComponent('Запись к ' + booking.master)}` +
    `&dates=${start}/${start}` +
    `&details=${encodeURIComponent(booking.service)}`;
}

// ── Утилиты ──────────────────────────────────────────────
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ── Онбординг ────────────────────────────────────────────
const ONBOARDING_KEY = 'beauty-tma-onboarding-v1';

function isFirstRun() {
  try { return !localStorage.getItem(ONBOARDING_KEY); }
  catch { return false; }
}

function markOnboardingDone() {
  try { localStorage.setItem(ONBOARDING_KEY, '1'); } catch {}
}

function initScreen_onboarding() {
  // Подставляем имя пользователя из Telegram
  // first_name может содержать «Имя|Компания» — берём только до разделителя
  const user = tg?.initDataUnsafe?.user;
  const rawName = (user?.first_name || '').split('|')[0].trim();
  const firstName = rawName || 'дорогой гость';
  const nameEl = document.getElementById('onboarding-name');
  if (nameEl) nameEl.textContent = firstName;

  // Кнопка "Начать"
  const btn = document.getElementById('onboarding-start-btn');
  if (btn) {
    btn.addEventListener('click', () => {
      Haptic.tap();
      markOnboardingDone();
      initScreen_index();
    });
  }

  // MainButton и BackButton скрыты на онбординге
  MainButton.hide();
  BackButton.hide();

  navigate('onboarding');
}

// ── Запуск ───────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  initTelegram();

  // Закрытие fullscreen
  document.getElementById('fullscreen-close')
    ?.addEventListener('click', closeFullscreen);

  // Клик по overlay (вне фото) — тоже закрывает
  document.getElementById('fullscreen-overlay')
    ?.addEventListener('click', e => {
      if (e.target === e.currentTarget) closeFullscreen();
    });

  // Убираем is-error при фокусе на input
  document.getElementById('phone-input')
    ?.addEventListener('focus', () => {
      document.getElementById('phone-input').classList.remove('is-error');
    });

  // Кнопка "Поделиться с подругой"
  document.getElementById('btn-share')?.addEventListener('click', () => {
    Haptic.tap();
    const botUrl = 'https://t.me/beauty_vizitka_bot';
    const text   = 'Нашла классную штуку — Beauty Визитка, запись к мастеру прямо в Telegram, без звонков! Попробуй 💅';
    if (tg) {
      // Нативный шаринг через Telegram
      tg.openTelegramLink(
        `https://t.me/share/url?url=${encodeURIComponent(botUrl)}&text=${encodeURIComponent(text)}`
      );
    } else {
      // Фолбэк в браузере
      if (navigator.share) {
        navigator.share({ title: 'Бьюти Визитка', text, url: botUrl });
      } else {
        window.open(`https://t.me/share/url?url=${encodeURIComponent(botUrl)}&text=${encodeURIComponent(text)}`);
      }
    }
  });

  // Первый запуск — онбординг, иначе сразу главная
  if (isFirstRun()) {
    initScreen_onboarding();
  } else {
    initScreen_index();
  }
});
