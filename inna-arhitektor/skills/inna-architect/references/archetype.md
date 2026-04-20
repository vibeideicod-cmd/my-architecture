# references/archetype.md

## Архетип: Редакционный

Выбран в brief.md. Обоснование: аудитория — владельцы бизнеса и эксперты, читают много, ценят ясность. Тон — экспертный с теплотой (гибрид без сленга). Редакционный = точная типографика + строгий порядок + минимум декора + премиальность через акценты.

## Что делаем

- **Типографика** — главный инструмент. Playfair Display для крупных Hero-заголовков, Montserrat для всего остального. Контрастные веса (300/400/500/700).
- **Сетка** — одна колонка на мобиле, две на десктопе. Никаких 3+ колонок.
- **Пустое пространство** щедрое. `clamp()` для отступов между секциями: `clamp(3rem, 8vw, 6rem)`.
- **Акценты** только в ключевых точках: CTA-кнопки, подписи к триггерам, hover-состояния. Не злоупотреблять.
- **Линии и рамки** тонкие, 1px, opacity 0.15–0.3. Декоративные уголки на карточках ок (как у Alisa).

## Что НЕ делаем

- ❌ Grain overlay (фон-шум) — это не редакционный, это брутализм
- ❌ Floating blobs / анимированные пятна — не редакционный
- ❌ Многоступенчатые градиенты — максимум 1 градиент, мягкий
- ❌ Glassmorphism с сильным blur (> 20px) — редакционный требует чёткости
- ❌ Тени с большими радиусами — максимум soft shadow 0 4px 24px rgba(0,0,0,.2)
- ❌ Псевдо-3D-эффекты — нет

## Палитра (финал, 2026-04-20)

```css
:root {
  --bg:        #103206;   /* тёмно-зелёный фон — НЕ чёрный */
  --bg-card:   #0d2805;   /* чуть темнее для карточек */
  --accent:    #c99700;   /* горчичный — главный акцент */
  --accent-2:  #e86c3a;   /* оранжевый — вторичный, для CTA и hover */
  --gold:      #d4af37;   /* лёгкая вариация для shine */
  --text:      #e8e0d8;   /* основной текст */
  --text-warm: #d3bfb1;   /* мягкий подтон */
  --text-mute: #a89e94;   /* приглушённый */
  --border:        rgba(201,151,0,.22);
  --border-hover:  rgba(201,151,0,.5);
  --glow:          rgba(201,151,0,.10);
  --radius: 16px;
}
```

## Шрифты

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&display=swap" rel="stylesheet">
```

Применение:
- **Playfair Display** — `h1` (имя «Инна Архитектор»), `h2` (крупные заголовки секций если есть). Вес 700. Italic только для акцентных цитат.
- **Montserrat** — всё остальное. Вес 400 для body, 500 для meta/captions, 600 для подзаголовков, 700 для CTA-кнопок.
- `letter-spacing: .02em` для верхнего регистра, `-0.01em` для Playfair Display заголовков.

## Размерность

Mobile (base = 375px):
- h1: `clamp(2.2rem, 8vw, 3.5rem)`
- h2: `clamp(1.5rem, 5vw, 2.2rem)`
- body: `clamp(.95rem, 2vw, 1rem)` — `line-height: 1.7`
- button: `.95rem`, padding `clamp(.9rem, 3vw, 1.1rem) clamp(1.5rem, 5vw, 2rem)`

## Принцип «один архетип — одна тональность кода»

По правилу `agents/websites.md:132`:
- Редакционный = **минимум CSS**, точная типографика, ноль декоративных техник из [knowledge/standards/visual-techniques.md](../../../knowledge/standards/visual-techniques.md)

Не добавлять в HTML-файл:
- `@keyframes float`, `@keyframes blob`
- `filter: blur(60px)`
- `background: radial-gradient(...), radial-gradient(...), radial-gradient(...)` — больше 1 layer
- `backdrop-filter: blur(...)` сильнее чем 10px

Если очень хочется декор — максимум один subtle `radial-gradient` в фоне с очень низкой opacity (0.05–0.08).
