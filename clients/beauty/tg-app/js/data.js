// ============================================================
// data.js — Загрузка данных мастера + утилиты
// Источник данных: Supabase (см. supabase-config.js)
// До bootstrapData() глобалы MASTER/CATEGORIES/SERVICES = null/{}.
// ============================================================

'use strict';

// ── Глобальные данные (заполняются в bootstrapData) ─────
let MASTER     = null;   // профиль мастера
let CATEGORIES = [];     // [{id, name, icon, min_price, count}]
let SERVICES   = {};     // { [category_id]: [{id, name, price_from, ...}] }

// ── Загрузка данных мастера из Supabase ─────────────────
// Тянет master, categories, services параллельно. Считает
// min_price и count для каждой категории на клиенте.
// Возвращает true при успехе, бросает ошибку при провале.
async function bootstrapData(masterId) {
  if (!BeautyDB?.client) {
    throw new Error('Supabase client не инициализирован');
  }
  const id = masterId || BeautyDB.MASTER_ID;

  const [masterRes, catRes, svcRes] = await Promise.all([
    BeautyDB.client
      .from('masters')
      .select('id,name,specialty,city,bio,avatar_url,accent_color,status_text')
      .eq('id', id)
      .single(),
    BeautyDB.client
      .from('categories')
      .select('id,slug,name,icon,position')
      .eq('master_id', id)
      .eq('is_active', true)
      .order('position', { ascending: true }),
    BeautyDB.client
      .from('services')
      .select('id,category_id,name,description,price_from,price_exact,duration,tags,position')
      .eq('master_id', id)
      .eq('is_active', true)
      .order('position', { ascending: true }),
  ]);

  if (masterRes.error) throw new Error('masters: ' + masterRes.error.message);
  if (catRes.error)    throw new Error('categories: ' + catRes.error.message);
  if (svcRes.error)    throw new Error('services: ' + svcRes.error.message);
  if (!masterRes.data) throw new Error('Мастер «' + id + '» не найден');

  // Маппим master → форма, которую ожидает app.js
  MASTER = {
    id:        masterRes.data.id,
    name:      masterRes.data.name,
    specialty: masterRes.data.specialty || '',
    city:      masterRes.data.city || '',
    bio:       masterRes.data.bio || '',
    avatar:    masterRes.data.avatar_url || '',
    accent:    masterRes.data.accent_color || '#b49fd4',
    status:    masterRes.data.status_text || '',
  };

  // Группируем услуги по category_id
  SERVICES = {};
  for (const s of svcRes.data) {
    const k = s.category_id;
    if (!SERVICES[k]) SERVICES[k] = [];
    SERVICES[k].push({
      id:          'svc_' + s.id,
      name:        s.name,
      description: s.description || '',
      price_from:  s.price_from,
      price_exact: s.price_exact,
      duration:    s.duration,
      tags:        s.tags || [],
      photos:      [], // фото пока не подключены — фолбэк на emoji в галерее
    });
  }

  // Категории с расчётом min_price и count из services
  CATEGORIES = catRes.data.map(c => {
    const svcs = SERVICES[c.id] || [];
    const minPrice = svcs.length
      ? Math.min(...svcs.map(s => s.price_from))
      : 0;
    return {
      id:        c.id,
      slug:      c.slug || null,
      name:      c.name,
      icon:      c.icon || '✨',
      min_price: minPrice,
      count:     svcs.length,
    };
  });

  return true;
}

// ── Генератор слотов (пока mock) ────────────────────────
// TODO: заменить на чтение schedules + bookings из Supabase.
// Возвращаем только свободные слоты (занятые не показываем).
function getMockSlots(dateStr) {
  const d = new Date(dateStr);
  const day = d.getDay(); // 0 = вс, 6 = сб

  // Выходные — мастер не работает
  if (day === 0 || day === 6) return [];

  const ALL = ['10:00', '10:30', '11:30', '12:00', '12:30',
               '14:00', '14:30', '15:30', '16:00', '17:00'];

  return ALL.map(time => ({ time, available: true }));
}

// Следующий доступный день со слотами
function getNextAvailableSlot(fromDateStr) {
  const d = new Date(fromDateStr);
  for (let i = 1; i <= 14; i++) {
    d.setDate(d.getDate() + 1);
    const slots = getMockSlots(d.toISOString().slice(0, 10));
    if (slots.length > 0) {
      return {
        date: d.toISOString().slice(0, 10),
        time: slots[0].time,
        label: formatDate(d) + ' · ' + slots[0].time,
      };
    }
  }
  return null;
}

// ── Утилиты дат ──────────────────────────────────────────
const RU_DAYS  = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
const RU_MONTHS = ['января','февраля','марта','апреля','мая','июня',
                   'июля','августа','сентября','октября','ноября','декабря'];
const RU_MONTHS_SHORT = ['янв','фев','мар','апр','май','июн',
                          'июл','авг','сен','окт','ноя','дек'];

function formatDate(d) {
  const day = typeof d === 'string' ? new Date(d) : d;
  return `${day.getDate()} ${RU_MONTHS[day.getMonth()]}`;
}

function formatDateFull(dateStr, timeStr) {
  const d = new Date(dateStr);
  const dayName = ['Воскресенье','Понедельник','Вторник','Среда',
                   'Четверг','Пятница','Суббота'][d.getDay()];
  return `${dayName}, ${d.getDate()} ${RU_MONTHS[d.getMonth()]} · ${timeStr}`;
}

// 14 дней вперёд для DatePicker
function getNext14Days() {
  const days = [];
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let i = 0; i < 14; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    const dateStr = d.toISOString().slice(0, 10);
    days.push({
      dateStr,
      dayName: i === 0 ? 'Сегодня' : RU_DAYS[d.getDay()],
      dayNum:  d.getDate(),
      month:   RU_MONTHS_SHORT[d.getMonth()],
      isToday: i === 0,
      disabled: d.getDay() === 0 || d.getDay() === 6,
    });
  }
  return days;
}

// Цена с учётом price_exact
function formatPrice(service) {
  const p = service.price_from.toLocaleString('ru-RU');
  return service.price_exact ? `${p} ₽` : `от ${p} ₽`;
}

// Длительность
function formatDuration(minutes) {
  if (minutes < 60) return `${minutes} мин`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m ? `${h} ч ${m} мин` : `${h} ч`;
}
