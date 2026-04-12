// ============================================================
// data.js — Mock-данные для Beauty TMA (MVP без бэкенда)
// Источник: brief-beauty-tma.md, research-beauty.md
// ============================================================

'use strict';

// ── Профиль мастера ────────────────────────────────────────
const MASTER = {
  id:          'master_demo',
  name:        'Анна Смирнова',
  specialty:   'Бьюти-мастер',
  city:        'Москва',
  bio:         'Работаю с гель-лаком, акрилом и дизайном. Принимаю на Арбате.',
  avatar:      'img/avatar.jpg',
  accent:      '#b49fd4',
  status:      'Принимаю записи на май 🌸',
};

// ── Категории услуг ───────────────────────────────────────
// min_price — ценовой ориентир на главном экране
const CATEGORIES = [
  { id: 'manicure', name: 'Маникюр',  icon: '💅', min_price: 1200, count: 4 },
  { id: 'pedicure', name: 'Педикюр',  icon: '🦶', min_price: 1500, count: 3 },
  { id: 'design',   name: 'Дизайн',   icon: '✨', min_price: 500,  count: 6 },
  { id: 'care',     name: 'Уход',     icon: '🌿', min_price: 800,  count: 2 },
];

// ── Услуги по категориям ──────────────────────────────────
// price_exact: true — показываем без «от», false — «от X ₽»
const SERVICES = {
  manicure: [
    {
      id:          'svc_1',
      name:        'Маникюр классический',
      price_from:  1200,
      price_exact: true,
      duration:    60,
      description: 'Обработка кутикулы, придание формы, покрытие по желанию. Включает массаж рук.',
      tags:        ['Гель-лак', 'Классика'],
      photos:      ['img/svc/manicure-1.jpg', 'img/svc/manicure-2.jpg'],
    },
    {
      id:          'svc_2',
      name:        'Маникюр гель-лак',
      price_from:  1800,
      price_exact: true,
      duration:    90,
      description: 'Стойкое покрытие до 3 недель. Широкая палитра — более 200 оттенков.',
      tags:        ['Гель-лак', 'Стойкость'],
      photos:      ['img/svc/gel-1.jpg', 'img/svc/gel-2.jpg', 'img/svc/gel-3.jpg'],
    },
    {
      id:          'svc_3',
      name:        'Комби-маникюр',
      price_from:  2000,
      price_exact: false, // зависит от сложности кутикулы
      duration:    75,
      description: 'Аппаратная + классическая обработка. Идеально для плотной кутикулы.',
      tags:        ['Аппаратный', 'Комби'],
      photos:      ['img/svc/combi-1.jpg'],
    },
    {
      id:          'svc_4',
      name:        'Снятие + маникюр',
      price_from:  2200,
      price_exact: true,
      duration:    120,
      description: 'Бережное снятие старого покрытия + полный маникюр с новым гель-лаком.',
      tags:        ['Снятие', 'Гель-лак'],
      photos:      ['img/svc/removal-1.jpg'],
    },
  ],
  pedicure: [
    {
      id:          'svc_5',
      name:        'Педикюр классический',
      price_from:  2000,
      price_exact: true,
      duration:    90,
      description: 'Обработка стоп, ногтей и кутикулы. Завершается увлажняющим кремом.',
      tags:        ['Классика'],
      photos:      ['img/svc/ped-1.jpg'],
    },
    {
      id:          'svc_6',
      name:        'Педикюр гель-лак',
      price_from:  2500,
      price_exact: true,
      duration:    110,
      description: 'Педикюр + стойкое покрытие гель-лаком. Держится до 4 недель.',
      tags:        ['Гель-лак'],
      photos:      ['img/svc/ped-gel-1.jpg', 'img/svc/ped-gel-2.jpg'],
    },
    {
      id:          'svc_7',
      name:        'Аппаратный педикюр',
      price_from:  2800,
      price_exact: false,
      duration:    90,
      description: 'Аппаратная обработка — нет воды, нет порезов. Особенно эффективен при мозолях.',
      tags:        ['Аппаратный'],
      photos:      ['img/svc/ped-hw-1.jpg'],
    },
  ],
  design: [
    {
      id:          'svc_8',
      name:        'Простой дизайн',
      price_from:  500,
      price_exact: true,
      duration:    30,
      description: 'Французский маникюр, омбре, однотонный с декором. 1–2 пальца.',
      tags:        ['Дизайн', 'Омбре'],
      photos:      ['img/svc/design-simple-1.jpg'],
    },
    {
      id:          'svc_9',
      name:        'Сложный дизайн',
      price_from:  800,
      price_exact: false,
      duration:    60,
      description: 'Роспись, объёмный дизайн, nail-art. Цена зависит от сложности узора.',
      tags:        ['Nail-art', 'Роспись'],
      photos:      ['img/svc/design-hard-1.jpg', 'img/svc/design-hard-2.jpg'],
    },
  ],
  care: [
    {
      id:          'svc_10',
      name:        'SPA-маникюр',
      price_from:  2500,
      price_exact: true,
      duration:    90,
      description: 'Маникюр + ванночка + скраб + маска + массаж рук. Максимальное расслабление.',
      tags:        ['SPA', 'Уход'],
      photos:      ['img/svc/spa-1.jpg'],
    },
    {
      id:          'svc_11',
      name:        'Укрепление ногтей',
      price_from:  1500,
      price_exact: true,
      duration:    60,
      description: 'Укрепление биогелем или базой. Восстанавливает ломкие и слоящиеся ногти.',
      tags:        ['Укрепление'],
      photos:      ['img/svc/strengthen-1.jpg'],
    },
  ],
};

// ── Генератор слотов ──────────────────────────────────────
// Возвращаем только свободные слоты (занятые не показываем — снижает тревогу)
function getMockSlots(dateStr) {
  const d = new Date(dateStr);
  const day = d.getDay(); // 0 = вс, 6 = сб

  // Выходные — мастер не работает
  if (day === 0 || day === 6) return [];

  const ALL = ['10:00', '10:30', '11:30', '12:00', '12:30',
               '14:00', '14:30', '15:30', '16:00', '17:00'];

  // В MVP все слоты свободны — в реальном API будем запрашивать занятые
  return ALL.map(time => ({ time, available: true }));
}

// Следующий доступный день с открытыми слотами
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

// Генерируем 14 дней вперёд для DatePicker
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

// Форматируем цену с учётом price_exact
function formatPrice(service) {
  const p = service.price_from.toLocaleString('ru-RU');
  return service.price_exact ? `${p} ₽` : `от ${p} ₽`;
}

// Форматируем длительность
function formatDuration(minutes) {
  if (minutes < 60) return `${minutes} мин`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m ? `${h} ч ${m} мин` : `${h} ч`;
}
