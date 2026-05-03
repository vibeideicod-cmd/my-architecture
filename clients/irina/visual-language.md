# Визуальный язык Ирины Цепаевой

> **Назначение:** документ для верстальщика (Websites / Кодыч). На его основе собирается цифровая визитка (HTML), затем адаптация под Telegram Mini App и VK Mini App.
> **Цель визуала:** за 2 секунды показать «супер дизайнер», ещё до прочтения текста.
> **Источники:** `clients/irina/brandbook/palette.md`, `typography.md`, `ui-components.md`, `logo-and-graphics.md`, `dont.md`, `tov-source.md`, `architecture.md`, `architecture-decisions.md`, `brandbook-pdf-brief.md`.
> **Версия:** v1.0 · 2026-05-03 · Branding

---

## 0. Что важно понять Кодычу за 1 минуту

1. **Палитра — собственная Иринина**, **не Инны**. Не использовать `#103206`, `#D4AF37` (золото), `gold`, `#4B7850`, `#FFDD4C`, `#FFF2E9`. Это коды Инны.
2. **Триада бренда Ирины:** Ваниль `#FCFAE1` (фон 60-70%) + Сосновая хвоя `#306654` (основной 25-30%) + Тёплый коралл `#FF935E` (акцент 10-15%). Эта триада на странице = «безошибочно Ирина».
3. **Шрифтовая пара утверждена:** Playfair Display (заголовки) + Montserrat (текст).
4. **Тёплое премиум**, скруглённые формы, воздух, без агрессии и срочности. CAPS LOCK на длинных фразах — нет.
5. **Градиенты и тени — обязательная часть визуального языка** (Ирина их любит, факт от Инны). Но: цветные из её палитры, многослойные, без skeumorphism-3D-эффектов.
6. **Юридическое:** не упоминаем партнёрство с Инной, не упоминаем vibe coding / AI-инструменты в публичных текстах. Любые тексты — на «вы», тёплый премиум.
7. **Логотипы внешних брендов** (Telegram, VK, WhatsApp, MAX) — оригинальные, в фирменных цветах, не перекрашиваем под палитру Ирины.

---

## 1. Палитра (CSS-переменные)

8 цветов из её брендбука. Источник: `clients/irina/brandbook/palette.md`.

```css
:root {
  /* Основные 5 — собственные Иринины */
  --pine:      #306654;  /* Сосновая хвоя — основной, текст, тёмные секции */
  --sprout:    #A1BF5B;  /* Молодая зелень — свежесть, второстепенный CTA */
  --coral:     #FF935E;  /* Тёплый коралл — главный акцент, ссылки, hover */
  --lemon:     #F8EB00;  /* Лимонная цедра — шильдики, точечные акценты */
  --vanilla:   #FCFAE1;  /* Ваниль — главный фон 60-70% */

  /* Дополнительные 3 неоновых — общие с Инной, маркер технологичности */
  --neon:      #13F740;  /* Неоновый зелёный — маркер «AI», статус-индикаторы */
  --acid:      #4DAA02;  /* Кислотный — главная Primary CTA */
  --magenta:   #FF2EC4;  /* Жгучая мадженти — wow-акценты, манифест */

  /* Семантические токены */
  --bg:            var(--vanilla);
  --bg-dark:       var(--pine);
  --text:          var(--pine);
  --text-on-dark:  var(--vanilla);
  --accent:        var(--coral);
  --cta:           var(--acid);
  --link:          var(--coral);

  /* Прозрачные слои — цветные тени и подложки */
  --pine-10:    rgba(48, 102, 84, 0.10);
  --pine-20:    rgba(48, 102, 84, 0.20);
  --pine-40:    rgba(48, 102, 84, 0.40);
  --pine-60:    rgba(48, 102, 84, 0.60);
  --coral-30:   rgba(255, 147, 94, 0.30);
  --coral-50:   rgba(255, 147, 94, 0.50);
  --magenta-25: rgba(255, 46, 196, 0.25);
}
```

### Контрастные пары для текста (из `palette.md`)

| Фон | Цвет текста |
|---|---|
| `--vanilla` (главный фон) | `--pine` |
| `--pine` (тёмная секция) | `--vanilla` |
| `--coral` (акцент) | `--pine` (только заголовки H1-H2, не body) |
| `--sprout` (свежесть) | `--pine` (только заголовки) |
| `--magenta` (wow) | `--pine` (только wow-заголовки H1) |
| `--lemon` | `--pine` — **только шильдики 1-2 слова, не body** |
| Картинка / фото | оверлей `var(--pine-60)` + текст `--vanilla` |

---

## 2. Градиенты

> **Источник принципов:** факт от Инны «Ирина любит градиенты»; CSS-каталог `knowledge/standards/visual-techniques.md` §1, §4.
> **Статус:** *Предложение Branding, согласовать.* В её материалах нет фиксированных рецептов градиентов — собрано на её палитре по канону «тёплое премиум, мягкие переходы».

### 2.1. «Закат-коралл» — Hero-фон визитки

Тёплый горизонт, главное настроение бренда. Используется на hero-секции цифровой визитки.

```css
.hero {
  background:
    radial-gradient(at 25% 20%, rgba(255, 147, 94, 0.55) 0px, transparent 55%),
    radial-gradient(at 80% 10%, rgba(255, 46, 196, 0.18) 0px, transparent 50%),
    radial-gradient(at 60% 90%, rgba(48, 102, 84, 0.35) 0px, transparent 55%),
    var(--vanilla);
  min-height: 100vh;
}
```

### 2.2. «Лесная тень» — премиум-секция (тёмный блок)

Глубокий зелёный с тёплым подсветом. Подходит для блока «обо мне», тарифов, footer.

```css
.section-dark {
  background:
    radial-gradient(at 20% 0%, rgba(255, 147, 94, 0.20) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(161, 191, 91, 0.18) 0px, transparent 55%),
    linear-gradient(180deg, var(--pine) 0%, #244c3f 100%);
  color: var(--text-on-dark);
}
```

### 2.3. «Ванильный шёлк» — мягкий фон длинного контента

Едва заметный тёплый перелив на ванили. Для блоков с длинным текстом (FAQ, описания услуг) — ощущение «не плоско, но глаз отдыхает».

```css
.section-soft {
  background:
    linear-gradient(135deg, var(--vanilla) 0%, #FFF6D4 60%, #FFEAC9 100%);
}
```

### 2.4. «Коралл-кнопка» — Primary CTA с глубиной

Заменяет плоскую заливку на CTA. Сохраняет читаемость, добавляет «вкусности».

```css
.btn-primary {
  background:
    linear-gradient(135deg, #5BC003 0%, var(--acid) 60%, #3A8202 100%);
  color: var(--vanilla);
  border: 0;
  border-radius: 12px;
  padding: 14px 28px;
  font: 700 16px/1 'Montserrat', sans-serif;
}
.btn-primary:hover {
  background: linear-gradient(135deg, var(--acid) 0%, #3A8202 100%);
}
```

### 2.5. «Манифест-маджента» — wow-секция (точечно)

Только для wow-моментов: обложки кейсов, шапки сторис, манифест-экран. Большими массами не использовать (`dont.md` 3.2).

```css
.wow {
  background:
    radial-gradient(at 30% 30%, var(--magenta) 0px, transparent 60%),
    radial-gradient(at 70% 80%, var(--coral) 0px, transparent 55%),
    var(--pine);
}
```

### 2.6. «Текст-перелив» (для одного слова в H1)

Используется максимум 1 раз на странице — на главном слове манифеста («слышу», «цвета»).

```css
.headline-accent {
  background: linear-gradient(120deg, var(--coral) 0%, var(--magenta) 100%);
  -webkit-background-clip: text;
          background-clip: text;
  color: transparent;
}
```

> ❌ Не делать: радужные градиенты из 5+ цветов, голограмму, переливы синий→бирюзовый (вне палитры) — всё это запрещено в `dont.md` 3.3.

---

## 3. Тени

> **Принцип:** тени всегда **цветные из палитры**, многослойные. Серые `rgba(0,0,0,…)` дефолтные — не используем. Skeumorphism-3D — не используем (`dont.md` 6.1).
> **Статус:** *Предложение Branding, согласовать.* Каталог-источник: `knowledge/standards/visual-techniques.md` §5 (dramatic shadows).

### 3.1. Карточка услуги / продукта (мягкая базовая)

```css
.card {
  background: var(--vanilla);
  border-radius: 16px;
  padding: 24px;
  box-shadow:
    0 4px 16px -6px rgba(48, 102, 84, 0.18),
    0 1px 3px rgba(48, 102, 84, 0.08);
  transition: transform .25s ease, box-shadow .25s ease;
}
.card:hover {
  transform: translateY(-2px);
  box-shadow:
    0 12px 32px -10px rgba(48, 102, 84, 0.28),
    0 2px 6px rgba(48, 102, 84, 0.10);
}
```

### 3.2. Primary CTA с цветной тенью под кнопку

Тень в цвет кнопки — кнопка «светится» снизу, остаётся плоской сверху.

```css
.btn-primary {
  box-shadow:
    0 8px 24px -8px rgba(77, 170, 2, 0.55),
    0 2px 6px rgba(77, 170, 2, 0.30);
}
.btn-primary:hover {
  box-shadow:
    0 14px 32px -10px rgba(77, 170, 2, 0.70),
    0 3px 8px rgba(77, 170, 2, 0.40);
}
```

Для secondary CTA (Хвоя) — то же, но с `rgba(48, 102, 84, …)`. Для wow-CTA (Маджента) — `rgba(255, 46, 196, …)`.

### 3.3. Премиум-блок (драматичная многослойная тень)

Для тарифа «РЕКОМЕНДУЕМ», карточки флагмана, секции с фото Ирины.

```css
.featured {
  border-radius: 20px;
  background: var(--vanilla);
  box-shadow:
    0 24px 60px -20px rgba(48, 102, 84, 0.35),
    0 8px 20px -8px rgba(255, 147, 94, 0.25),
    0 0 0 1px rgba(48, 102, 84, 0.10) inset;
}
```

### 3.4. Hover-преображение карточки кейса

```css
.case {
  border-radius: 16px;
  overflow: hidden;
  transition: transform .3s ease, box-shadow .3s ease;
  box-shadow: 0 6px 20px -8px rgba(48, 102, 84, 0.20);
}
.case:hover {
  transform: translateY(-4px);
  box-shadow:
    0 18px 40px -12px rgba(48, 102, 84, 0.35),
    0 4px 12px rgba(255, 147, 94, 0.25);
}
```

### 3.5. Drop-shadow под крупный текст-заголовок

Тёплый «отпечаток» под H1 — заголовок «парит» над фоном без обводки. Только для hero, не для каждого H2.

```css
.hero h1 {
  filter: drop-shadow(0 6px 20px rgba(255, 147, 94, 0.35));
}
```

### 3.6. Inset-glow на фотографии Ирины

Внутренняя цветная подсветка по краю фото — фото «дышит» в палитре бренда.

```css
.portrait {
  border-radius: 24px;
  box-shadow:
    inset 0 0 0 6px var(--vanilla),
    inset 0 0 0 7px rgba(48, 102, 84, 0.15),
    0 20px 50px -18px rgba(48, 102, 84, 0.40);
}
```

> ❌ Не делать: 3D-кнопки с кричащими тенями, тяжёлые серые `rgba(0,0,0,0.5)`, неоновое свечение по контуру (`box-shadow: 0 0 30px var(--neon)` — выглядит токсично).

---

## 4. Текстуры и атмосфера

Бренд Ирины — **тёплое премиум, не цифровая стерильность**. Главный приём атмосферы — лёгкий шум поверх цвета, чтобы убрать «пластиковость».

### 4.1. Noise overlay на всём документе

Каталог: `knowledge/standards/visual-techniques.md` §2. Адаптация под Иринин фон:

```css
body::before {
  content: '';
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 1;
  opacity: 0.05;
  mix-blend-mode: multiply;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}
```

`opacity` держать в диапазоне 0.04–0.07 на ванильном фоне. На тёмной хвое — `mix-blend-mode: overlay` и opacity до 0.10.

### 4.2. Фирменный паттерн «капли в палитре» (фоновая зона)

Источник: `brandbook/logo-and-graphics.md` §3.2 — «мелкие овалы и капли в свободной композиции, прозрачность 5-15%». Для секции «обо мне», шапки сторис.

```css
.about-bg {
  background:
    radial-gradient(circle at 12% 20%, var(--coral-30) 0 8px, transparent 9px),
    radial-gradient(circle at 78% 35%, rgba(161, 191, 91, 0.25) 0 14px, transparent 15px),
    radial-gradient(circle at 30% 80%, rgba(48, 102, 84, 0.18) 0 10px, transparent 11px),
    radial-gradient(circle at 88% 78%, rgba(255, 46, 196, 0.18) 0 6px, transparent 7px),
    var(--vanilla);
}
```

> ❌ Не делать: геометрическую сетку Bootstrap-стиля (не Иринин язык — её формы органические, без острых углов, см. `logo-and-graphics.md` §3).

### 4.3. Чего избегать в текстурах

- Голограмма / переливы радуги — `dont.md` 3.3.
- Glassmorphism с большим `backdrop-filter: blur(40px)` — не тёплое премиум, а холодный tech (`visual-techniques.md` §4 даёт его «в умеренных дозах», для Ирины — максимум `blur(12px)` и только на тёмных секциях).
- Растровые «бумажные» фоны и сток-текстуры — бренд не сток (`dont.md` 5.2).

---

## 5. Типографика

Источник: `clients/irina/brandbook/typography.md`.

### 5.1. Шрифты

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet"
  href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Montserrat:wght@300;400;500;700&display=swap">
```

```css
:root {
  --font-display: 'Playfair Display', Georgia, serif;  /* H1, манифест, цитаты-сигнатуры */
  --font-body:    'Montserrat', system-ui, sans-serif; /* H2-H4, body, кнопки */
}
```

**Курсив — только в Playfair Display** (для цитат-сигнатур). В Montserrat курсив не используем (правило наследуется от Инны).

### 5.2. Шкала (с clamp для адаптива)

```css
:root {
  --fs-h1:      clamp(2.25rem, 1.4rem + 4.2vw, 4.5rem);   /* 36 → 72px */
  --fs-h2:      clamp(1.75rem, 1.2rem + 2.6vw, 3rem);     /* 28 → 48px */
  --fs-h3:      clamp(1.4rem,  1.1rem + 1.4vw, 2rem);     /* 22 → 32px */
  --fs-h4:      clamp(1.2rem,  1.05rem + 0.6vw, 1.5rem);  /* 19 → 24px */
  --fs-body:    clamp(1rem,    0.95rem + 0.25vw, 1.125rem); /* 16 → 18px */
  --fs-small:   0.875rem;   /* 14px */
  --fs-caption: 0.8125rem;  /* 13px */

  --lh-tight:   1.1;
  --lh-snug:    1.2;
  --lh-normal:  1.5;
  --lh-relaxed: 1.6;
}

h1 { font: 700 var(--fs-h1)/var(--lh-tight)   var(--font-display); letter-spacing: -0.01em; }
h2 { font: 700 var(--fs-h2)/1.15              var(--font-body); }
h3 { font: 700 var(--fs-h3)/var(--lh-snug)    var(--font-body); }
h4 { font: 700 var(--fs-h4)/1.25              var(--font-body); }
body, p { font: 400 var(--fs-body)/var(--lh-relaxed) var(--font-body); }
small  { font-size: var(--fs-small);   line-height: var(--lh-normal); }
.caption { font-size: var(--fs-caption); line-height: 1.4; }

.sign { font: italic 400 var(--fs-h3)/1.3 var(--font-display); } /* цитаты-сигнатуры */
```

### 5.3. Правила набора

- Длинное тире `—` в авторских мыслях, не дефис.
- Неразрывный пробел между числом и единицей: `5 000 ₽`, `3 дня`.
- Висячая пунктуация в крупных заголовках при печати.
- Русские «ёлочки» « » для цитат, не "прямые".
- Капитализация по правилам русского языка («Меня не видят», не «Меня Не Видят»).

### 5.4. Антипатт`ерны (из `dont.md` §4)

CAPS LOCK на длинных фразах · 4-5 разных весов на одной странице · подчёркивание для акцента (только для ссылок) · `letter-spacing > 0.1em` на body · H1 < 36px на десктопе · body < 16px на десктопе.

---

## 6. Анимации и motion

> **Жёсткое правило бренда:** все анимации **до 300ms** (`dont.md` 6.4, `ui-components.md` §13). Дольше — тормозит восприятие.

### 6.1. Тайминги и easing

```css
:root {
  --ease-soft:   cubic-bezier(.22, .61, .36, 1);    /* выезды, появления */
  --ease-pop:    cubic-bezier(.34, 1.4, .64, 1);    /* hover-«подъём», bounce */
  --ease-out:    cubic-bezier(.25, .8, .25, 1);     /* универсальный */
  --dur-fast:    150ms;    /* hover */
  --dur-base:    250ms;    /* появления, переходы */
  --dur-slow:    300ms;    /* page-load элементы (потолок) */
}
```

### 6.2. Page-load orchestration (sequencing)

Вместо «всё появилось одновременно» — лесенка с задержкой 60-100ms между элементами hero. Каталог: `visual-techniques.md` §8.

```css
@keyframes rise {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: none; }
}
.hero > * { opacity: 0; animation: rise var(--dur-slow) var(--ease-soft) forwards; }
.hero > *:nth-child(1) { animation-delay: 60ms; }
.hero > *:nth-child(2) { animation-delay: 140ms; }
.hero > *:nth-child(3) { animation-delay: 220ms; }
.hero > *:nth-child(4) { animation-delay: 300ms; }
```

### 6.3. Hover-преображения

- Карточка: `translateY(-2px) → -4px` + усиление цветной тени (см. §3.1, §3.4).
- Primary CTA: `scale(0.98)` на active, тень растёт на hover.
- Ссылки в тексте: появление подчёркивания через `text-decoration-thickness: 2px; text-underline-offset: 4px;`, цвет — Коралл.

> ❌ Не делать: hover с `transform: rotate` (`dont.md` 6.1, выглядит дёшево), бесконечно пульсирующих элементов, hover, скрывающего CTA.

### 6.4. Scroll-эффекты

- `IntersectionObserver` + класс `.in-view` → `opacity 0 → 1`, `translateY(20px) → 0`, длительность 250-300ms.
- Параллакс — **не используем** (`dont.md` 6.3, `ui-components.md` §13: «модно в 2018, в 2026 отвлекает от смысла»).
- `scroll-behavior: smooth;` на `html` — да.
- `prefers-reduced-motion: reduce` — обязательная ветка: отключаем все анимации.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### 6.5. Custom cursor

Каталог: `visual-techniques.md` §6. **Только на hero визитки**, один акцент на странице. Уместно для премиум-впечатления — кружок в Коралле, заменяющий стрелку.

```css
.hero {
  cursor: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24'%3E%3Ccircle cx='12' cy='12' r='5' fill='%23FF935E'/%3E%3C/svg%3E") 12 12, pointer;
}
```

> Решение «использовать или нет» — за Ириной. *Предложение Branding, согласовать.*

---

## 7. Чего НЕ делаем (свод по этой странице)

Зафиксировано в `clients/irina/brandbook/dont.md` (главы 3, 4, 6) и `ui-components.md` §13. Здесь — короткий чек-лист для верстальщика:

**Цвета**
- ❌ Чёрный `#000` для текста и теней — вместо него Хвоя `#306654`.
- ❌ Чисто-белый `#FFF` для фона — вместо него Ваниль `#FCFAE1`.
- ❌ Серые `#808080`, синий, красный, фиолетовый, золото `#D4AF37` — вне палитры.
- ❌ Цвета и палитра Инны (`#103206`, `#D4AF37`, `gold`).

**Градиенты**
- ❌ Радужные градиенты из 5+ цветов.
- ❌ Голограмма, неоновое свечение по контуру кнопок (`box-shadow: 0 0 30px var(--neon)` = токсично).
- ❌ Маджента или Лимон как фон длинного текста.

**Тени**
- ❌ Серые дефолтные `rgba(0,0,0,…)` — только цветные из палитры.
- ❌ Тяжёлые 3D-кнопки skeumorphism.

**Типографика**
- ❌ Comic Sans, Papyrus, Times New Roman, Verdana, готика.
- ❌ CAPS LOCK на длинных фразах.
- ❌ 4-5 разных весов в одном макете.
- ❌ Подчёркивание для акцента (оно только для ссылок).

**Интерфейс**
- ❌ Прямоугольные кнопки без скругления.
- ❌ Кнопка без текста на главной CTA.
- ❌ Hover с `transform: rotate`.
- ❌ Параллакс на каждой секции.
- ❌ Auto-play видео со звуком.
- ❌ Pop-up «Подпишись» через 5 секунд.
- ❌ Анимации длительностью >300ms.

**Логотипы внешних сервисов**
- ❌ Перекрашивать Telegram / VK / WhatsApp / MAX в палитру Ирины. Только оригинальные цвета (`CLAUDE.md` корня).

---

## 8. Открытые вопросы (требуют уточнения у Инны / Ирины)

1. **Тени и градиенты — окончательное согласование.** Все CSS-сниппеты в §2 и §3 — *Предложение Branding* на её палитре. Источников с конкретикой «именно такая тень / именно такой градиент» в её материалах нет — есть только общий факт «любит градиенты и тени». Нужна сверка с Ириной по 4 пунктам:
   - Глубина теней — устраивает ли «премиум-многослойная» (§3.3) или хочется мягче / жёстче?
   - Hero-градиент «Закат-коралл» (§2.1) — это её настроение визитки, или хочет другой главный акцент (например, «Лесная тень» как hero)?
   - Текст-перелив на одном слове H1 (§2.6) — уместно или «слишком»?
   - Inset-glow на портрете (§3.6) — нравится приём или фото оставлять «как есть»?

2. **Custom cursor на hero** (§6.5) — использовать или нет? Решение за Ириной.

3. **Логотип** — `brandbook/logo-and-graphics.md` помечен MVP, концепция логотипа не выбрана (A/B/C/D). До утверждения — на визитке используем монограмму «И» в Playfair Display Bold цветом Хвоя (запасной вариант из §«Главный знак»).

4. **Фото Ирины** — есть ли утверждённый портрет для hero визитки? Если нет — на первой версии оставляем плейсхолдер (овальная карточка с монограммой «И»).

5. **Noise opacity** на ванильном фоне (§4.1) — стартуем с 0.05; финальное значение — после визуального теста на её мониторе (Ирина-дизайнер увидит, какая зернистость уместна).

6. **«Тёплая премиум» против «современный tech»** — у Ирины есть 3-я альтернативная пара шрифтов (Onest для tech-продуктов). Для **визитки** взят Playfair + Montserrat (утверждённая основная). Если в TMA / VK Mini App она захочет более «цифровой» вид — переключаемся на Onest, но это отдельное решение под платформу.

---

## 9. Связанные документы

- `clients/irina/brandbook/palette.md` — полный гид по цветам с психологией и архетипами
- `clients/irina/brandbook/typography.md` — детальная типографика
- `clients/irina/brandbook/ui-components.md` — кнопки, формы, карточки, модалки
- `clients/irina/brandbook/logo-and-graphics.md` — логотип, графический язык, паттерны
- `clients/irina/brandbook/dont.md` — антипримеры (полный список запретов)
- `clients/irina/tov-source.md` — голос Ирины (для текстов на визитке)
- `knowledge/standards/visual-techniques.md` — каталог CSS-приёмов команды (§1, §2, §5, §6, §8)
- `clients/irina/CLAUDE.md` — юр.правила проекта Ирины

---

*Branding · 2026-05-03 · v1.0 · документ для Websites (Кодыч) под цифровую визитку Ирины*
