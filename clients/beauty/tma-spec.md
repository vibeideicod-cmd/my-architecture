# Beauty TMA — Technical Specification & Implementation Roadmap

> **Для кого:** AI-агенты и кодеры, которые будут писать код.
> **Как читать:** сверху вниз. Каждый раздел — прямая инструкция. Не интерпретировать, не добавлять от себя.
> **Связанные документы:** `research-beauty.md` (исследование), `brief-beauty-tma.md` (UX-детали), `tma-roadmap.md` (этапы)

---

## 0. КОНТЕКСТ ПРОДУКТА

```
Что строим:  Telegram Mini App — витрина-каталог бьюти-мастера
Кто видит:   Клиенты мастера (конечные потребители услуг)
Открытие:    t.me/BotName/app?startapp=master_abc123
MVP-данные:  Mock (constants.js) — без бэкенда в первой итерации
Язык:        Русский, только русский
```

---

## 1. ТЕХНОЛОГИЧЕСКИЙ СТЕК

### Жёсткие требования — не менять

| Слой | Технология | Версия |
|---|---|---|
| Фреймворк | **Vite + React** | React 18+ |
| Стили | **Tailwind CSS** + CSS Variables | Tailwind 3+ |
| TG SDK | **@twa-dev/sdk** | latest |
| Анимации | **framer-motion** | 11+ |
| Иконки | **lucide-react** | latest |

### Что НЕ использовать

- ❌ Next.js (лишний оверхед для TMA)
- ❌ React Router (навигация через state machine, не URL)
- ❌ date-fns / moment.js (пишем легковесные утилиты сами)
- ❌ Lottie (анимация успеха — чистый CSS/SVG)
- ❌ Swiper.js / любые слайдер-библиотеки (touch events сами)
- ❌ axios (только нативный fetch)
- ❌ UI-kit библиотеки (shadcn, MUI, Chakra — стилизуем сами)

### Инициализация проекта

```bash
npm create vite@latest beauty-tma -- --template react
cd beauty-tma
npm install tailwindcss @tailwindcss/vite @twa-dev/sdk framer-motion lucide-react
```

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: './',   // обязательно для TMA — относительные пути
})
```

---

## 2. ТЕМА И CSS-ПЕРЕМЕННЫЕ

### Правило: ни одного жёсткого цвета в компонентах

Все цвета — только через переменные. Tailwind настроен под них.

```css
/* src/styles/globals.css */
:root {
  /* Telegram Native Variables — подставляются автоматически */
  --tg-bg:          var(--tg-theme-bg-color, #ffffff);
  --tg-bg-sec:      var(--tg-theme-secondary-bg-color, #f4f4f5);
  --tg-text:        var(--tg-theme-text-color, #000000);
  --tg-hint:        var(--tg-theme-hint-color, #8e8e93);
  --tg-link:        var(--tg-theme-link-color, #007aff);
  --tg-btn:         var(--tg-theme-button-color, #007aff);
  --tg-btn-text:    var(--tg-theme-button-text-color, #ffffff);

  /* Брендинг мастера — перезаписывается из JS при инициализации */
  --accent:         #b49fd4;
  --accent-light:   #d4c4ee;

  /* Эргономика */
  --tap-min:        44px;
  --radius-sm:      8px;
  --radius-md:      12px;
  --radius-lg:      16px;
  --radius-xl:      20px;
  --px:             16px;
  --safe-bottom:    calc(80px + env(safe-area-inset-bottom));
}
```

```javascript
// tailwind.config.js
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        'tg-bg':      'var(--tg-bg)',
        'tg-bg-sec':  'var(--tg-bg-sec)',
        'tg-text':    'var(--tg-text)',
        'tg-hint':    'var(--tg-hint)',
        'tg-btn':     'var(--tg-btn)',
        'tg-btn-text':'var(--tg-btn-text)',
        'accent':     'var(--accent)',
      },
      minHeight: { tap: 'var(--tap-min)' },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
      },
    },
  },
}
```

### Инициализация темы

```javascript
// src/lib/telegram.js
import WebApp from '@twa-dev/sdk'

export function initTelegram() {
  WebApp.ready()
  WebApp.expand()

  // Применить брендинг мастера (загружается из mock/API)
  // вызывается после получения данных мастера
}

export function applyMasterBranding(accentColor) {
  if (accentColor) {
    document.documentElement.style.setProperty('--accent', accentColor)
  }
}

export const tg = WebApp
```

---

## 3. СТРУКТУРА ФАЙЛОВ

Создать точно такую структуру — не отклоняться:

```
beauty-tma/
├── index.html
├── vite.config.js
├── tailwind.config.js
├── src/
│   ├── main.jsx                  ← точка входа
│   ├── App.jsx                   ← State machine навигации
│   │
│   ├── screens/
│   │   ├── IndexScreen.jsx       ← Экран 1: Витрина
│   │   ├── ServicesScreen.jsx    ← Экран 2: Список услуг
│   │   ├── DetailsScreen.jsx     ← Экран 3: Карточка услуги
│   │   ├── BookingScreen.jsx     ← Экран 4: Запись (дата + время)
│   │   └── SuccessScreen.jsx     ← Экран 5: Успех
│   │
│   ├── components/
│   │   ├── Layout.jsx            ← Обёртка: тема + safe areas + padding
│   │   ├── PhotoSlider.jsx       ← Слайдер без библиотек
│   │   ├── DatePicker.jsx        ← Горизонтальный выбор даты
│   │   ├── TimeGrid.jsx          ← Сетка слотов
│   │   ├── ServiceCard.jsx       ← Карточка услуги в списке
│   │   ├── CategoryCard.jsx      ← Карточка категории (плитка)
│   │   ├── SkeletonCard.jsx      ← Skeleton-заглушка
│   │   └── SuccessAnimation.jsx  ← SVG-галочка с анимацией
│   │
│   ├── lib/
│   │   ├── telegram.js           ← Инициализация TG SDK, хелперы
│   │   ├── haptics.js            ← Обёртки над HapticFeedback
│   │   └── calendar.js           ← Утилиты для дат (без date-fns)
│   │
│   ├── data/
│   │   └── constants.js          ← Mock-данные (замена API для MVP)
│   │
│   └── styles/
│       └── globals.css           ← CSS Variables + сброс стилей
```

---

## 4. НАВИГАЦИЯ (State Machine)

Навигация — через React state. Никаких URL-роутеров.

```jsx
// src/App.jsx
import { useState } from 'react'
import { AnimatePresence } from 'framer-motion'
import IndexScreen    from './screens/IndexScreen'
import ServicesScreen from './screens/ServicesScreen'
import DetailsScreen  from './screens/DetailsScreen'
import BookingScreen  from './screens/BookingScreen'
import SuccessScreen  from './screens/SuccessScreen'
import { initTelegram } from './lib/telegram'

// Инициализация один раз
initTelegram()

const SCREENS = {
  index:    IndexScreen,
  services: ServicesScreen,
  details:  DetailsScreen,
  booking:  BookingScreen,
  success:  SuccessScreen,
}

export default function App() {
  const [screen, setScreen] = useState('index')
  const [params, setParams] = useState({}) // данные между экранами

  function navigate(to, data = {}) {
    setParams(data)
    setScreen(to)
  }

  const Screen = SCREENS[screen]

  return (
    <AnimatePresence mode="wait">
      <Screen
        key={screen}
        params={params}
        navigate={navigate}
      />
    </AnimatePresence>
  )
}
```

### Анимация перехода между экранами

```jsx
// src/components/Layout.jsx
import { motion } from 'framer-motion'

const pageVariants = {
  initial:  { opacity: 0, x: 20 },
  animate:  { opacity: 1, x: 0 },
  exit:     { opacity: 0, x: -20 },
}

const pageTransition = { duration: 0.2, ease: 'easeInOut' }

export default function Layout({ children }) {
  return (
    <motion.div
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
      transition={pageTransition}
      className="min-h-screen bg-tg-bg text-tg-text overflow-x-hidden"
      style={{ paddingBottom: 'var(--safe-bottom)' }}
    >
      {children}
    </motion.div>
  )
}
```

---

## 5. MOCK-ДАННЫЕ (constants.js)

Весь MVP работает на этих данных. API подключается позже.

```javascript
// src/data/constants.js

export const MASTER = {
  id:           'master_demo',
  name:         'Анна Смирнова',
  specialty:    'Мастер маникюра',
  city:         'Москва',
  bio:          'Работаю с гель-лаком, акрилом и дизайном. Принимаю на Арбате.',
  avatar:       '/demo/avatar.jpg',
  accent_color: '#b49fd4',
}

export const CATEGORIES = [
  // UX fix #1: добавлено min_price — показываем ценовой уровень на главной
  { id: 'manicure', name: 'Маникюр', photo: '/demo/cat-manicure.jpg', count: 4, min_price: 1200 },
  { id: 'pedicure', name: 'Педикюр', photo: '/demo/cat-pedicure.jpg', count: 3, min_price: 1500 },
  { id: 'design',   name: 'Дизайн',  photo: '/demo/cat-design.jpg',   count: 6, min_price: 500  },
  { id: 'care',     name: 'Уход',    photo: '/demo/cat-care.jpg',     count: 2, min_price: 800  },
]

export const SERVICES = {
  manicure: [
    {
      id: 'svc_1',
      name:        'Маникюр классический',
      price_from:  1200,
      price_exact: true,   // UX fix #5: точная цена — показывать без "от"
      duration:    60,
      preview:     '/demo/svc1-preview.jpg',
      photos:      ['/demo/svc1-1.jpg', '/demo/svc1-2.jpg', '/demo/svc1-3.jpg'],
      description: 'Обработка кутикулы, придание формы, покрытие по желанию. Включает массаж рук.',
    },
    {
      id: 'svc_2',
      name:        'Маникюр гель-лак',
      price_from:  1800,
      price_exact: true,
      duration:    90,
      preview:     '/demo/svc2-preview.jpg',
      photos:      ['/demo/svc2-1.jpg', '/demo/svc2-2.jpg'],
      description: 'Стойкое покрытие до 3 недель. Широкая палитра цветов.',
    },
    {
      id: 'svc_3',
      name:        'Комби-маникюр',
      price_from:  2000,
      price_exact: false,  // цена зависит от сложности — показываем "от"
      duration:    75,
      preview:     '/demo/svc3-preview.jpg',
      photos:      ['/demo/svc3-1.jpg'],
      description: 'Аппаратная + классическая обработка. Идеально для плотной кутикулы.',
    },
  ],
  // остальные категории аналогично
}

// Генератор слотов для демо
// UX fix #4: возвращаем ТОЛЬКО свободные слоты — занятые не показываем
export function getMockSlots(dateStr) {
  const ALL = ['10:00','10:30','11:30','12:00','12:30',
               '14:00','14:30','15:30','16:00','17:00']
  // Занятые просто исключены из массива — клиент видит только доступные
  return ALL.map(time => ({ time, available: true }))
}

// UX fix #4: поиск ближайшего дня с доступными слотами
export function getNextAvailableSlot(fromDateStr) {
  // В MVP — возвращаем захардкоженный ближайший слот
  // В реальном API — запрос к серверу
  const d = new Date(fromDateStr)
  d.setDate(d.getDate() + 1)
  return {
    date: d.toISOString().slice(0, 10),
    time: '10:00',
  }
}
```

---

## 6. КОМПОНЕНТЫ — ДЕТАЛЬНЫЕ ДИРЕКТИВЫ

### 6.1 Экран 1 — IndexScreen (Витрина)

```jsx
// src/screens/IndexScreen.jsx
// ДИРЕКТИВЫ ДЛЯ КОДЕРА:
// - tg.MainButton.hide() при монтировании
// - tg.BackButton.hide() при монтировании
// - Grid 2 колонки для CategoryCard
// - Tap на карточку → navigate('services', { categoryId })
// - HapticFeedback.selectionChanged() при tap
// - Skeleton пока MASTER и CATEGORIES не загружены

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import Layout from '../components/Layout'
import CategoryCard from '../components/CategoryCard'
import SkeletonCard from '../components/SkeletonCard'
import { tg } from '../lib/telegram'
import { haptic } from '../lib/haptics'
import { MASTER, CATEGORIES } from '../data/constants'

export default function IndexScreen({ navigate }) {
  useEffect(() => {
    tg.MainButton.hide()
    tg.BackButton.hide()
  }, [])

  function handleCategoryTap(category) {
    haptic.select()
    navigate('services', { category })
  }

  return (
    <Layout>
      {/* Hero */}
      <div className="flex flex-col items-center pt-6 pb-4 px-4">
        <img
          src={MASTER.avatar}
          alt={MASTER.name}
          className="w-20 h-20 rounded-full object-cover mb-3"
        />
        <h1 className="text-xl font-bold text-tg-text">{MASTER.name}</h1>
        <p className="text-sm text-tg-hint mt-0.5">
          {MASTER.specialty} · {MASTER.city}
        </p>
        <p className="text-sm text-tg-text text-center mt-2 line-clamp-2">
          {MASTER.bio}
        </p>
      </div>

      {/* Категории */}
      <div className="px-4">
        <h2 className="text-base font-semibold text-tg-hint uppercase tracking-wide mb-3">
          Услуги
        </h2>
        <div className="grid grid-cols-2 gap-3">
          {CATEGORIES.map((cat, i) => (
            <motion.div
              key={cat.id}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
            >
              <CategoryCard
                category={cat}
                onTap={() => handleCategoryTap(cat)}
              />
            </motion.div>
          ))}
        </div>
      </div>
    </Layout>
  )
}
```

### 6.2 CategoryCard

```jsx
// src/components/CategoryCard.jsx
// Карточка категории: фото на весь блок, текст поверх gradient overlay
// Соотношение сторон: 4/3
// Минимальная высота нажимаемой зоны: 44px (гарантировано aspect-ratio)

export default function CategoryCard({ category, onTap }) {
  return (
    <button
      onClick={onTap}
      className="relative w-full rounded-lg overflow-hidden active:scale-95 transition-transform"
      style={{ aspectRatio: '4/3' }}
    >
      <img
        src={category.photo}
        alt={category.name}
        className="absolute inset-0 w-full h-full object-cover"
        loading="lazy"
      />
      {/* Gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent" />
      <div className="absolute bottom-0 left-0 right-0 p-2.5">
        <p className="text-white font-semibold text-sm leading-tight">
          {category.name}
        </p>
        {/* UX fix #1: цена в карточке категории — пользователь сразу видит уровень */}
        <p className="text-white/60 text-xs mt-0.5">
          от {category.min_price.toLocaleString('ru-RU')} ₽ · {category.count} услуг
        </p>
      </div>
    </button>
  )
}
```

### 6.3 Экран 2 — ServicesScreen

```jsx
// src/screens/ServicesScreen.jsx
// ДИРЕКТИВЫ:
// - BackButton.show() + onClick → navigate('index')
// - MainButton.hide()
// - Список услуг в iOS-стиле: разделители, высота карточки 80px+
// - Tap на карточку → navigate('details', { service })
// - HapticFeedback.selectionChanged() при tap

import { useEffect } from 'react'
import Layout from '../components/Layout'
import ServiceCard from '../components/ServiceCard'
import { tg } from '../lib/telegram'
import { haptic } from '../lib/haptics'
import { SERVICES } from '../data/constants'

export default function ServicesScreen({ params, navigate }) {
  const { category } = params
  const services = SERVICES[category.id] || []

  useEffect(() => {
    tg.MainButton.hide()
    tg.BackButton.show()
    tg.BackButton.onClick(() => navigate('index'))
    return () => tg.BackButton.offClick()
  }, [])

  return (
    <Layout>
      <div className="px-4 pt-4 pb-3">
        <h1 className="text-xl font-bold text-tg-text">{category.name}</h1>
      </div>

      <div className="divide-y divide-tg-bg-sec">
        {services.map(service => (
          <ServiceCard
            key={service.id}
            service={service}
            onTap={() => {
              haptic.select()
              navigate('details', { service, category })
            }}
          />
        ))}
      </div>
    </Layout>
  )
}
```

### 6.4 ServiceCard

```jsx
// src/components/ServiceCard.jsx
// Горизонтальная карточка: фото слева, текст справа, chevron в конце
// Минимальная высота: 80px

import { ChevronRight } from 'lucide-react'

export default function ServiceCard({ service, onTap }) {
  return (
    <button
      onClick={onTap}
      className="flex items-center gap-3 w-full px-4 py-3 bg-tg-bg
                 active:bg-tg-bg-sec transition-colors min-h-[80px] text-left"
    >
      <img
        src={service.preview}
        alt={service.name}
        className="w-[72px] h-[72px] rounded-md object-cover flex-shrink-0 bg-tg-bg-sec"
        loading="lazy"
      />
      <div className="flex-1 min-w-0">
        <p className="font-semibold text-tg-text text-base leading-snug">
          {service.name}
        </p>
        {/* UX fix #5: точная цена без "от" если price_exact === true */}
        <p className="text-accent font-bold text-base mt-0.5">
          {service.price_exact
            ? `${service.price_from.toLocaleString('ru-RU')} ₽`
            : `от ${service.price_from.toLocaleString('ru-RU')} ₽`
          }
        </p>
        <p className="text-tg-hint text-sm mt-0.5">{service.duration} мин</p>
      </div>
      <ChevronRight className="text-tg-hint w-5 h-5 flex-shrink-0" />
    </button>
  )
}
```

### 6.5 Экран 3 — DetailsScreen

```jsx
// src/screens/DetailsScreen.jsx
// ДИРЕКТИВЫ:
// - BackButton → navigate('services', { category })
// - MainButton.show(), setText('Выбрать время'), enable()
// - MainButton.onClick → navigate('booking', { service })
// - Слайдер: PhotoSlider (свой компонент, без библиотек)
// - Описание: первые 3 строки + кнопка "Читать далее"
// - При открытии fullscreen-фото: MainButton.hide() + BackButton.hide()
// - При закрытии fullscreen: вернуть обе кнопки

import { useEffect, useState } from 'react'
import Layout from '../components/Layout'
import PhotoSlider from '../components/PhotoSlider'
import { tg } from '../lib/telegram'
import { haptic } from '../lib/haptics'
import { Clock } from 'lucide-react'

export default function DetailsScreen({ params, navigate }) {
  const { service, category } = params
  const [expanded, setExpanded] = useState(false)

  useEffect(() => {
    tg.BackButton.show()
    tg.BackButton.onClick(() => navigate('services', { category }))

    tg.MainButton.setText('Выбрать время')
    tg.MainButton.enable()
    tg.MainButton.show()
    tg.MainButton.onClick(() => {
      haptic.impact('medium')
      navigate('booking', { service })
    })

    return () => {
      tg.BackButton.offClick()
      tg.MainButton.offClick()
    }
  }, [])

  return (
    <Layout>
      {/* Слайдер галереи */}
      <PhotoSlider photos={service.photos} />

      {/* Контент */}
      <div className="px-4 pt-4 space-y-3">
        <h1 className="text-xl font-bold text-tg-text">{service.name}</h1>

        <div className="flex items-center gap-4">
          {/* UX fix #5: точная цена на экране деталей */}
          <span className="text-accent font-bold text-xl">
            {service.price_exact
              ? `${service.price_from.toLocaleString('ru-RU')} ₽`
              : `от ${service.price_from.toLocaleString('ru-RU')} ₽`
            }
          </span>
          <span className="flex items-center gap-1 text-tg-hint text-sm">
            <Clock className="w-4 h-4" />
            {service.duration} мин
          </span>
        </div>

        {/* Описание с разворотом */}
        <div>
          <p className={`text-tg-text text-base leading-relaxed
            ${!expanded ? 'line-clamp-3' : ''}`}>
            {service.description}
          </p>
          {!expanded && (
            <button
              onClick={() => setExpanded(true)}
              className="text-accent text-sm mt-1 min-h-[var(--tap-min)]
                         flex items-center"
            >
              Читать полностью ↓
            </button>
          )}
        </div>
      </div>
    </Layout>
  )
}
```

### 6.6 PhotoSlider (без библиотек)

```jsx
// src/components/PhotoSlider.jsx
// Touch-слайдер: touchstart + touchmove + touchend
// Fullscreen: overlay на весь экран, pinch-to-zoom через CSS
// Dots-индикатор снизу

import { useState, useRef } from 'react'
import { tg } from '../lib/telegram'
import { haptic } from '../lib/haptics'

export default function PhotoSlider({ photos }) {
  const [current, setCurrent] = useState(0)
  const [fullscreen, setFullscreen] = useState(false)
  const startX = useRef(0)
  const trackRef = useRef(null)

  function handleTouchStart(e) {
    startX.current = e.touches[0].clientX
  }

  function handleTouchEnd(e) {
    const diff = startX.current - e.changedTouches[0].clientX
    if (Math.abs(diff) < 40) return // tap, not swipe
    if (diff > 0 && current < photos.length - 1) {
      setCurrent(c => c + 1)
      haptic.select()
    } else if (diff < 0 && current > 0) {
      setCurrent(c => c - 1)
      haptic.select()
    }
  }

  function openFullscreen(index) {
    setCurrent(index)
    setFullscreen(true)
    tg.MainButton.hide()
    tg.BackButton.hide()
    haptic.impact('light')
  }

  function closeFullscreen() {
    setFullscreen(false)
    tg.MainButton.show()
    tg.BackButton.show()
    haptic.impact('light')
  }

  return (
    <>
      {/* Слайдер */}
      <div
        className="relative w-full overflow-hidden bg-tg-bg-sec"
        style={{ aspectRatio: '4/3' }}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
        onClick={() => openFullscreen(current)}
      >
        <div
          ref={trackRef}
          className="flex h-full transition-transform duration-300 ease-out"
          style={{ transform: `translateX(-${current * 100}%)` }}
        >
          {photos.map((src, i) => (
            <img
              key={i}
              src={src}
              alt=""
              className="flex-shrink-0 w-full h-full object-cover"
              loading={i === 0 ? 'eager' : 'lazy'}
            />
          ))}
        </div>

        {/* Dots */}
        <div className="absolute bottom-2 left-0 right-0 flex justify-center gap-1.5">
          {photos.map((_, i) => (
            <div
              key={i}
              className={`rounded-full transition-all duration-200
                ${i === current
                  ? 'w-4 h-1.5 bg-white'
                  : 'w-1.5 h-1.5 bg-white/50'
                }`}
            />
          ))}
        </div>
      </div>

      {/* Fullscreen overlay */}
      {fullscreen && (
        <div
          className="fixed inset-0 z-50 bg-black flex items-center justify-center"
          onClick={closeFullscreen}
        >
          <img
            src={photos[current]}
            alt=""
            className="max-w-full max-h-full object-contain"
            style={{ touchAction: 'pinch-zoom' }}
          />
          <button
            className="absolute top-4 right-4 text-white/80 text-3xl
                       w-11 h-11 flex items-center justify-center"
            onClick={closeFullscreen}
          >
            ×
          </button>
        </div>
      )}
    </>
  )
}
```

### 6.7 Экран 4 — BookingScreen

```jsx
// src/screens/BookingScreen.jsx
// ДИРЕКТИВЫ:
// - BackButton → navigate('details', { service, category })
// - MainButton: disabled пока слот не выбран
// - MainButton.onClick → navigate('success', { booking })
// - DatePicker: горизонтальный скролл, 14 дней вперёд
// - TimeGrid: 4 колонки, высота слота 44px — ТОЛЬКО свободные слоты
// - HapticFeedback.selectionChanged() при выборе слота
// - UX fix #2: телефон НЕ запрашиваем — мастер видит Telegram username клиента
// - UX fix #4: TimeGrid получает onDateJump для перехода к ближайшему слоту

import { useEffect, useState } from 'react'
import Layout from '../components/Layout'
import DatePicker from '../components/DatePicker'
import TimeGrid from '../components/TimeGrid'
import { tg } from '../lib/telegram'
import { haptic } from '../lib/haptics'
import { getMockSlots } from '../data/constants'
import { formatDateRu } from '../lib/calendar'

export default function BookingScreen({ params, navigate }) {
  const { service } = params
  const [selectedDate, setSelectedDate] = useState(null)
  const [selectedSlot, setSelectedSlot] = useState(null)
  const [slots, setSlots] = useState([])

  useEffect(() => {
    tg.BackButton.show()
    tg.BackButton.onClick(() => navigate('details', params))

    tg.MainButton.setText('Выбрать время')
    tg.MainButton.disable()
    tg.MainButton.show()

    return () => {
      tg.BackButton.offClick()
      tg.MainButton.offClick()
    }
  }, [])

  function handleDateSelect(date) {
    setSelectedDate(date)
    setSelectedSlot(null)
    tg.MainButton.disable()
    setSlots(getMockSlots(date))
    haptic.select()
  }

  function handleSlotSelect(slot) {
    setSelectedSlot(slot)
    haptic.select()
    haptic.impact('light')

    tg.MainButton.setText(`Записаться на ${slot.time}`)
    tg.MainButton.enable()
    tg.MainButton.onClick(() => {
      haptic.impact('medium')
      navigate('success', {
        booking: {
          service,
          date: selectedDate,
          time: slot.time,
        }
      })
    })
  }

  return (
    <Layout>
      <div className="px-4 pt-4 pb-3">
        <h1 className="text-xl font-bold text-tg-text">Выберите время</h1>
        <p className="text-tg-hint text-sm mt-0.5">{service.name}</p>
      </div>

      <DatePicker onSelect={handleDateSelect} selected={selectedDate} />

      {selectedDate && (
        <div className="px-4 mt-4">
          <p className="text-tg-hint text-sm mb-3">
            {formatDateRu(selectedDate)}
          </p>
          {/* UX fix #4: передаём onDateJump для кнопки "Ближайшее свободное" */}
          <TimeGrid
            slots={slots}
            selected={selectedSlot}
            onSelect={handleSlotSelect}
            selectedDate={selectedDate}
            onDateJump={({ date, time }) => {
              handleDateSelect(date)
              // после загрузки слотов автовыбор нужного времени
              setTimeout(() => handleSlotSelect({ time, available: true }), 50)
            }}
          />
        </div>
      )}
    </Layout>
  )
}
```

### 6.8 DatePicker

```jsx
// src/components/DatePicker.jsx
// Горизонтальный скролл, 14 дней вперёд
// Выбранный день: bg-accent text-white
// Сегодня: особая метка

import { getDatesRange, getDayName, isToday } from '../lib/calendar'

export default function DatePicker({ selected, onSelect }) {
  const dates = getDatesRange(14)

  return (
    <div className="flex gap-2 overflow-x-auto px-4 py-2 scrollbar-none">
      {dates.map(date => {
        const active = selected === date.str
        const today = isToday(date.date)

        return (
          <button
            key={date.str}
            onClick={() => onSelect(date.str)}
            className={`flex-shrink-0 flex flex-col items-center justify-center
                        rounded-xl px-3.5 py-2 min-h-[60px] min-w-[48px]
                        transition-colors duration-150
                        ${active
                          ? 'bg-accent text-white'
                          : 'bg-tg-bg-sec text-tg-text'
                        }`}
          >
            <span className={`text-xs font-medium
              ${active ? 'text-white/80' : 'text-tg-hint'}`}>
              {today ? 'Сег.' : getDayName(date.date)}
            </span>
            <span className="text-lg font-bold leading-tight">
              {date.day}
            </span>
          </button>
        )
      })}
    </div>
  )
}
```

### 6.9 TimeGrid

```jsx
// src/components/TimeGrid.jsx
// UX fix #4: показываем ТОЛЬКО свободные слоты (занятые создают тревогу)
// Если слотов нет — показываем сообщение + ссылку на ближайший день

import { getNextAvailableSlot } from '../data/constants'

export default function TimeGrid({ slots, selected, onSelect, selectedDate, onDateJump }) {
  // slots содержит только свободные (фильтрация на уровне getMockSlots)
  const freeSlots = slots.filter(s => s.available)

  if (freeSlots.length === 0) {
    const next = getNextAvailableSlot(selectedDate)
    return (
      <div className="text-center py-6 space-y-3">
        <p className="text-tg-hint text-sm">На этот день нет свободных мест</p>
        <button
          onClick={() => onDateJump(next)}
          className="text-accent text-sm font-medium min-h-[44px] px-4
                     flex items-center justify-center mx-auto"
        >
          Ближайшее свободное: {next.date} · {next.time} →
        </button>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-4 gap-2">
      {freeSlots.map(slot => {
        const isSelected = selected?.time === slot.time
        return (
          <button
            key={slot.time}
            onClick={() => onSelect(slot)}
            className={`h-11 rounded-lg text-sm font-medium
                        transition-colors duration-150
                        ${isSelected
                          ? 'bg-accent text-white'
                          : 'bg-tg-bg-sec text-tg-text active:bg-accent/20'
                        }`}
          >
            {slot.time}
          </button>
        )
      })}
    </div>
  )
}
```

### 6.10 Экран 5 — SuccessScreen

```jsx
// src/screens/SuccessScreen.jsx
// ДИРЕКТИВЫ:
// - BackButton.hide() — запись уже создана, нельзя "отменить" через назад
// - MainButton: "Готово" → tg.close()
// - HapticFeedback.notificationOccurred('success') при монтировании
// - Анимация: SVG-галочка через CSS stroke-dasharray (без Lottie)
// - UX fix #3: кнопка "← Вернуться в каталог" → navigate('index')
// - UX fix #5: цена без "от" если price_exact === true

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import Layout from '../components/Layout'
import SuccessAnimation from '../components/SuccessAnimation'
import { tg } from '../lib/telegram'
import { haptic } from '../lib/haptics'
import { buildCalendarUrl, formatDateTimeRu } from '../lib/calendar'

export default function SuccessScreen({ params, navigate }) {
  const { booking } = params

  useEffect(() => {
    haptic.notify('success')
    tg.BackButton.hide()
    tg.MainButton.setText('Готово')
    tg.MainButton.enable()
    tg.MainButton.show()
    tg.MainButton.onClick(() => tg.close())
    return () => tg.MainButton.offClick()
  }, [])

  const calUrl = buildCalendarUrl(booking)
  // UX fix #5: точная или "от" цена на экране успеха
  const priceLabel = booking.service.price_exact
    ? `${booking.service.price_from.toLocaleString('ru-RU')} ₽`
    : `от ${booking.service.price_from.toLocaleString('ru-RU')} ₽`

  return (
    <Layout>
      <div className="flex flex-col items-center pt-10 px-4 text-center">
        <SuccessAnimation />

        <motion.h1
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="text-2xl font-bold text-tg-text mt-4"
        >
          Вы записаны!
        </motion.h1>

        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.65 }}
          className="w-full mt-6 bg-tg-bg-sec rounded-xl p-4 text-left space-y-3"
        >
          <Row label="Услуга"   value={booking.service.name} />
          <Row label="Когда"    value={formatDateTimeRu(booking.date, booking.time)} />
          <Row label="Цена"     value={priceLabel} />
          <Row label="Длит."    value={`${booking.service.duration} мин`} />
        </motion.div>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8 }}
          className="text-tg-hint text-sm mt-4"
        >
          Напоминание придёт в Telegram за 24 часа до визита
        </motion.p>

        <motion.a
          href={calUrl}
          target="_blank"
          rel="noopener noreferrer"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.9 }}
          className="text-accent text-sm mt-3 min-h-[var(--tap-min)]
                     flex items-center"
        >
          Добавить в Google Calendar →
        </motion.a>

        {/* UX fix #3: после записи можно вернуться в каталог, не закрывая TMA */}
        <motion.button
          onClick={() => navigate('index')}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.0 }}
          className="text-tg-hint text-sm mt-2 min-h-[var(--tap-min)]
                     flex items-center"
        >
          ← Вернуться в каталог
        </motion.button>
      </div>
    </Layout>
  )
}

function Row({ label, value }) {
  return (
    <div className="flex justify-between items-baseline">
      <span className="text-tg-hint text-sm">{label}</span>
      <span className="text-tg-text text-sm font-medium text-right max-w-[60%]">
        {value}
      </span>
    </div>
  )
}
```

### 6.11 SuccessAnimation (SVG + CSS)

```jsx
// src/components/SuccessAnimation.jsx
// Анимация: круг → галочка через stroke-dasharray
// Без Lottie, без GIF — чистый CSS

export default function SuccessAnimation() {
  return (
    <div className="success-anim">
      <svg viewBox="0 0 52 52" className="w-20 h-20">
        <circle
          className="success-circle"
          cx="26" cy="26" r="24"
          fill="none"
          stroke="var(--accent)"
          strokeWidth="2"
        />
        <path
          className="success-check"
          fill="none"
          stroke="var(--accent)"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M14 27 l8 8 l16 -16"
        />
      </svg>

      <style>{`
        .success-circle {
          stroke-dasharray: 166;
          stroke-dashoffset: 166;
          animation: stroke 0.4s ease-out forwards;
        }
        .success-check {
          stroke-dasharray: 48;
          stroke-dashoffset: 48;
          animation: stroke 0.3s ease-out 0.35s forwards;
        }
        @keyframes stroke {
          to { stroke-dashoffset: 0; }
        }
      `}</style>
    </div>
  )
}
```

---

## 7. УТИЛИТЫ

### haptics.js

```javascript
// src/lib/haptics.js
import { tg } from './telegram'

export const haptic = {
  select:  ()    => tg.HapticFeedback.selectionChanged(),
  impact:  (s)   => tg.HapticFeedback.impactOccurred(s),   // light|medium|heavy
  notify:  (t)   => tg.HapticFeedback.notificationOccurred(t), // success|error|warning
}
```

### calendar.js

```javascript
// src/lib/calendar.js

const DAYS_SHORT = ['Вс','Пн','Вт','Ср','Чт','Пт','Сб']
const MONTHS = ['января','февраля','марта','апреля','мая','июня',
                'июля','августа','сентября','октября','ноября','декабря']

export function getDatesRange(days) {
  return Array.from({ length: days }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() + i)
    return {
      date: d,
      str:  d.toISOString().slice(0, 10),
      day:  d.getDate(),
    }
  })
}

export function getDayName(date) {
  return DAYS_SHORT[date.getDay()]
}

export function isToday(date) {
  const t = new Date()
  return date.toDateString() === t.toDateString()
}

export function formatDateRu(dateStr) {
  const d = new Date(dateStr)
  return `${DAYS_SHORT[d.getDay()]}, ${d.getDate()} ${MONTHS[d.getMonth()]}`
}

export function formatDateTimeRu(dateStr, time) {
  return `${formatDateRu(dateStr)} · ${time}`
}

export function buildCalendarUrl(booking) {
  const [y, m, day] = booking.date.split('-')
  const [h, min] = booking.time.split(':')
  const start = `${y}${m}${day}T${h}${min}00`
  const endDate = new Date(booking.date)
  const endH = parseInt(h) + Math.floor((parseInt(min) + booking.service.duration) / 60)
  const endMin = (parseInt(min) + booking.service.duration) % 60
  const end = `${y}${m}${day}T${String(endH).padStart(2,'0')}${String(endMin).padStart(2,'0')}00`

  return `https://calendar.google.com/calendar/render?action=TEMPLATE` +
    `&text=${encodeURIComponent('Запись: ' + booking.service.name)}` +
    `&dates=${start}/${end}`
}
```

---

## 8. SAFE AREAS (iPhone)

```css
/* src/styles/globals.css — добавить */

/* Поддержка "чёлки" и Home Indicator */
.screen {
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
}

/* Резерв под MainButton */
.content-with-main-btn {
  padding-bottom: calc(80px + env(safe-area-inset-bottom));
}
```

```javascript
// src/lib/telegram.js — добавить
export function initTelegram() {
  WebApp.ready()
  WebApp.expand()

  // Установить цвет статус-бара в тему
  if (WebApp.setHeaderColor) {
    WebApp.setHeaderColor('bg_color')
  }
}
```

```html
<!-- index.html — мета-тег для safe area -->
<meta name="viewport"
  content="width=device-width, initial-scale=1.0, viewport-fit=cover">
```

---

## 9. ЧЕГО НЕ КОДИМ В MVP

AI-агент не тратит токены на:

| Что | Почему |
|---|---|
| Бэкенд и БД | Только mock-данные (constants.js) |
| Онлайн-оплата | Платёжный провайдер подключается в v1.1 |
| Система регистрации | Авторизация = `window.Telegram.WebApp.initData` |
| Личный кабинет клиента | Нет истории записей — только текущий flow |
| Поиск по услугам | Не нужен при малом каталоге |
| Чат с мастером | Для этого есть Telegram |
| Отзывы и рейтинги | Требует модерации — v2.0 |
| Отмена записи клиентом | v1.1 |
| Мультиязычность | Только русский |
| Dark/Light mode toggle | Telegram управляет темой автоматически |

---

## 10. ПОШАГОВЫЙ АЛГОРИТМ РЕАЛИЗАЦИИ

### Step 1 — Инициализация (1 день)

```bash
npm create vite@latest beauty-tma -- --template react
cd beauty-tma
npm install tailwindcss @tailwindcss/vite @twa-dev/sdk framer-motion lucide-react
```

- Настроить `vite.config.js` (base: './')
- Настроить `tailwind.config.js` (цвета через переменные)
- Создать `src/styles/globals.css` (все CSS-переменные)
- Создать `src/lib/telegram.js` и вызвать `initTelegram()`
- Создать `src/data/constants.js` с mock-данными
- Проверить: TMA открывается в Telegram и занимает весь экран

### Step 2 — Layout + тема (0.5 дня)

- Создать `Layout.jsx` с framer-motion анимацией переходов
- Проверить тёмную и светлую тему: все цвета меняются автоматически
- Проверить safe areas на iPhone с чёлкой

### Step 3 — Верстка экранов (3 дня)

Порядок верстки (по 0.5-1 дню на экран):

1. `IndexScreen` + `CategoryCard` — главная с плиткой
2. `ServicesScreen` + `ServiceCard` — список в iOS-стиле
3. `DetailsScreen` + `PhotoSlider` — карточка + галерея
4. `BookingScreen` + `DatePicker` + `TimeGrid` — бронирование
5. `SuccessScreen` + `SuccessAnimation` — финал

После каждого экрана — тест на реальном телефоне через ngrok.

### Step 4 — Навигация и TG-кнопки (1 день)

- Подключить `AnimatePresence` + `navigate()` во всех экранах
- Настроить MainButton и BackButton на каждом экране по таблице из `tma-roadmap.md`
- Подключить HapticFeedback через `haptic.*` на все действия
- Проверить полный flow: Главная → Список → Карточка → Слоты → Успех → Закрытие

### Step 5 — Safe Areas и финальный тест (0.5 дня)

Чеклист:

- [ ] `tg.ready()` и `tg.expand()` вызываются при старте
- [ ] Все цвета — через `var(--tg-theme-*)` или `var(--accent)`
- [ ] MainButton и BackButton управляются корректно на каждом экране
- [ ] HapticFeedback работает на iOS и Android
- [ ] Skeleton-экраны там, где есть загрузка данных
- [ ] Минимальный tap target 44px — проверить на реальном iPhone
- [ ] Контент не перекрывается MainButton (отступ 80px снизу)
- [ ] Тёмная тема Telegram — все элементы читаемы
- [ ] Safe area (чёлка iPhone) — шапка не обрезается
- [ ] Горизонтальный скролл отсутствует полностью
- [ ] `tg.close()` вызывается на экране успеха

---

## 11. ДЕПЛОЙ

```bash
# Сборка
npm run build   # → папка dist/

# Деплой на Vercel (автоматически из GitHub)
# Или ручной деплой:
npx vercel --prod
```

В BotFather:
```
/newapp → указать HTTPS-URL из Vercel
```

Для локального тестирования:
```bash
npm run dev
npx ngrok http 5173   # → HTTPS-URL для Telegram
```

---

*Этот документ — полное техническое задание для AI-кодера. Читай сверху вниз. Не добавляй функции, не меняй стек. Пиши код точно по директивам.*
