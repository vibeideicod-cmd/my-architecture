# Каталог визуальных техник

> **Когда использовать:** Кодыч (`agents/websites.md`) обращается сюда, когда нужно усилить страницу атмосферой и глубиной, а не оставлять плоский solid-фон. Для каждого приёма — готовый CSS-сниппет.
>
> **Источник:** адаптация из официального скила `frontend-design` от Anthropic, плюс приёмы, которые мы уже использовали в HUB, ЮБ, МГ.
>
> **Жёсткое правило:** только чистый CSS, без JS-фреймворков. Никаких CDN.

---

## Принцип «match complexity to vision»

Перед выбором техник определись с визуальным курсом из меню архетипов в [agents/websites.md](../../agents/websites.md). Затем подбирай **под него**:

- **Брутальный минимализм / редакционный** — почти ничего из этого каталога. Один-два приёма максимум, остальное — voids и точная типографика.
- **Максимализм / ретро-футуризм / арт-деко** — комбинируй 3-5 техник в одной странице, не бойся плотности.
- **Органик / пастель** — мягкие градиенты, noise overlay, soft shadows. Без жёстких геометрий.
- **Индастриал / брутализм** — grain overlay, harsh borders, monospace типографика, никаких soft-shadows.

**Полумерные страницы запрещены.** Если сделал «немного градиента, немного теней, немного анимаций» без курса — это и есть AI slop. Либо коммитимся в курс полностью, либо убираем.

---

## 1. Gradient mesh (атмосферный градиентный фон)

Когда: люкс, ретро-футуризм, органик, пастель. Заменяет плоский фон.

```css
body {
  background:
    radial-gradient(at 20% 30%, hsla(28, 80%, 60%, 0.35) 0px, transparent 50%),
    radial-gradient(at 80% 0%, hsla(189, 80%, 56%, 0.25) 0px, transparent 50%),
    radial-gradient(at 80% 80%, hsla(355, 80%, 60%, 0.20) 0px, transparent 50%),
    radial-gradient(at 0% 100%, hsla(269, 80%, 60%, 0.30) 0px, transparent 50%),
    #1a1625;
  min-height: 100vh;
}
```

Тонкая настройка: 3-5 радиальных градиентов в разных позициях, alpha 0.2-0.4, базовый цвет фона — глубокий тёмный или светлый кремовый. Цвета должны быть из палитры клиента, не «универсальные».

---

## 2. Noise / grain overlay (плёночное зерно)

Когда: ретро, аналоговая эстетика, ЮБ-стиль (морской санаторий), брутализм. Убирает «цифровую стерильность».

```css
body::before {
  content: '';
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 1;
  opacity: 0.06;
  mix-blend-mode: overlay;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}
```

Регулировка: opacity от 0.04 до 0.10. Выше 0.10 уже мешает читать текст.

---

## 3. Geometric patterns (геометрический фон)

Когда: индастриал, брутализм, утилитарный, технологичный.

```css
.hero {
  background-color: #f4f1ea;
  background-image:
    linear-gradient(rgba(0,0,0,0.06) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0,0,0,0.06) 1px, transparent 1px);
  background-size: 40px 40px;
}
```

Варианты: точечная сетка `radial-gradient(circle, ... 1px, transparent 1px)`, диагональные линии `repeating-linear-gradient(45deg, ...)`, шевроны.

---

## 4. Layered transparencies (слоистые прозрачности)

Когда: глубина без фотографий. Заменяет stock-картинки.

```css
.card {
  background:
    linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0.02) 100%);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 24px;
}
```

Glassmorphism в умеренных дозах. На светлом фоне — `rgba(0,0,0, ...)` вместо белого.

---

## 5. Dramatic shadows (драматичные тени)

Когда: люкс, редакционный, арт-деко. Не путать с soft-drop-shadow.

```css
.featured {
  box-shadow:
    0 20px 60px -20px rgba(16, 50, 6, 0.4),
    0 8px 24px -8px rgba(16, 50, 6, 0.2),
    0 0 0 1px rgba(212, 175, 55, 0.12) inset;
}
```

Многослойные тени с цветом из палитры (не серый дефолт), жёсткими и мягкими слоями. Inset-borders усиливают.

---

## 6. Custom cursors (кастомный курсор)

Когда: люкс, игрушечный, max-аутентичный лендинг. Один акцент на странице, не везде.

```css
.hero {
  cursor: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='32' height='32'%3E%3Ccircle cx='16' cy='16' r='6' fill='%23d4af37'/%3E%3C/svg%3E") 16 16, pointer;
}
```

Один интересный курсор на heroe-секции — сильнее, чем 5 одинаковых на странице.

---

## 7. Decorative borders (декоративные рамки)

Когда: арт-деко, редакционный, ретро. Замена скучного `border: 1px solid #ccc`.

```css
.frame {
  border: 1px solid var(--gold);
  position: relative;
  padding: 48px;
}
.frame::before {
  content: '';
  position: absolute;
  inset: 8px;
  border: 1px solid var(--gold);
  pointer-events: none;
}
```

Двойные рамки, угловые «уголки», или SVG-обрамление. Никогда не дефолтный 1px solid.

---

## 8. Page-load orchestration (одна большая входная анимация)

Когда: всегда, если выбран курс с движением. **Один** оркестрованный entrance > десяток разбросанных микро-эффектов.

```css
@keyframes enter {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}
.hero > * {
  opacity: 0;
  animation: enter 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
.hero > *:nth-child(1) { animation-delay: 0.0s; }
.hero > *:nth-child(2) { animation-delay: 0.15s; }
.hero > *:nth-child(3) { animation-delay: 0.30s; }
.hero > *:nth-child(4) { animation-delay: 0.45s; }
```

Staggered reveal через `animation-delay`, не через JS. `cubic-bezier(0.16, 1, 0.3, 1)` — мягкое замедление.

---

## 9. Hover surprises (неожиданные hover)

Когда: интерактивные элементы. Не «фейд-плавно-цветом», а что-то характерное.

```css
.cta {
  background: var(--gold);
  color: var(--green-deep);
  padding: 16px 40px;
  border: none;
  position: relative;
  overflow: hidden;
  transition: color 0.3s ease;
}
.cta::before {
  content: '';
  position: absolute;
  inset: 0;
  background: var(--green-deep);
  transform: translateY(100%);
  transition: transform 0.3s cubic-bezier(0.65, 0, 0.35, 1);
  z-index: -1;
}
.cta:hover {
  color: var(--gold);
}
.cta:hover::before {
  transform: translateY(0);
}
```

Sweep-fill, инверсия цвета, magnet-pull (через CSS `transform`), «съезжающий» текст — что угодно, кроме `opacity: 0.8`.

---

## 10. Asymmetric grids (асимметричная сетка)

Когда: редакционный, брутализм, креативное портфолио. Сразу выдаёт «не AI slop».

```css
.grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1.5fr;
  gap: 32px;
}
.grid > :nth-child(2) {
  grid-row: span 2;
  align-self: end;
}
.grid > :nth-child(5) {
  margin-top: -80px;
}
```

Колонки с разной шириной, элементы со span/offset, отрицательные margin, overlap. Симметричные 3-колонки = AI slop.

---

## Чеклист: страница точно не AI slop?

После завершения вёрстки прогоняй:

- [ ] Выбран один из 12 архетипов в [agents/websites.md](../../agents/websites.md), и видно какой именно
- [ ] Хотя бы 1 техника из этого каталога применена осознанно
- [ ] Шрифт НЕ Inter / Roboto / Arial / system (см. чёрный список в [design-system.md](design-system.md))
- [ ] Фон НЕ плоский solid (если только курс не «брутальный минимализм»)
- [ ] Кнопки с hover-эффектом, который не сводится к `opacity` или `brightness`
- [ ] Тени не серые дефолтные, а с цветом из палитры
- [ ] Анимация при загрузке оркестрована (одна крупная), а не разбросана

Если хоть один пункт не закрыт без осознанного решения — это AI slop, переделываем.
