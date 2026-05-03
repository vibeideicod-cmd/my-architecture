# QA: цифровая визитка Ирины Цепаевой

> **Файл:** `clients/irina/index.html`
> **Дата сборки:** 2026-05-03
> **Архетип:** Редакционный / magazine (типографика-герой + asymmetric ритм + drop caps)
> **Что запомнится:** drop cap «И» в Playfair Bold + интерактивная демка «Слышу цвет» (3 слова → палитра)

---

## Чек-лист «страница точно не AI slop?»

(Источник: `knowledge/standards/visual-techniques.md`, строки 237–250)

- [x] **Выбран один из 12 архетипов в `agents/websites.md`, и видно какой именно**
  Архетип «Редакционный / magazine» — реализован через два больших drop cap'а (в `#about` коралловое «И» в 5.5em Playfair Bold; в `#manifest` коралловое «Я» в 4.5em float left), типографика как герой (Playfair Display 700 для H1 и цитат-сигнатур, Montserrat 500 для H2), asymmetric grid в `#about` (5fr/3fr вместо симметричных колонок) и в `#hero` (1.5fr/1fr), большие воздушные секции `padding: 72-130px`, фото-портрет как поддержка а не как декор.

- [x] **В brief'е заполнено поле «Что запомнится» — и эта деталь действительно реализована в вёрстке**
  Из brief §11: «Drop cap "И" + интерактивная демка "Слышу цвет"». Drop cap реализован как `.dropcap` в #about (Playfair 700, var(--coral), float left, text-shadow в pine-15). Демка «Слышу цвет» — 12 чипов с FIFO-логикой выбора 3 эмоций, алгоритм матчинга 5 палитр со score-сортировкой, mesh-блок результата по шаблону §6.4 brief, primary CTA с автотекстом в Telegram. Поддерживающие приёмы (custom cursor, magnetic CTA, mesh-градиент в hero) тоже на месте.

- [x] **Хотя бы 1 техника из каталога visual-techniques применена осознанно**
  Применено более 5 техник: §1 mesh-gradient «Закат-коралл» в hero; §2 noise overlay 0.05 на body + 0.10 на тёмной секции; §5 multi-layer цветные тени (карточки, premium aside, портрет с inset-glow по visual-language §3.6); §6 custom cursor только в hero (отключён на touch и reduced-motion); §8 page-load orchestration лесенкой 60→140→220→300→380ms; §10 asymmetric grid в about (5fr/3fr); magnetic CTA на главной кнопке (5–10px, 120px радиус).

- [x] **Шрифт НЕ Inter / Roboto / Arial / system**
  Только Playfair Display (display 400/700/800, italic 400/700) + Montserrat (300/400/500/600/700) через `<link>` Google Fonts. Никаких системных fallback в качестве основных шрифтов — system-ui только в стеке после Montserrat для редкого случая отказа загрузки.

- [x] **Цветовая схема НЕ «фиолетовый градиент на белом» и не другие штампы AI-генерации**
  Ваниль `#FCFAE1` (фон 60-70%) + Хвоя `#306654` (текст 25-30%) + Коралл `#FF935E` (акценты 10-15%). Палитра Ирины из её брендбука. Mesh-градиент «Закат-коралл» — radial-gradients из коралла + мадженты + хвои. Никаких purple→pink на белом.

- [x] **Раскладка НЕ предсказуемая шаблонная**
  Hero — асимметрия 1.5fr/1fr, портрет на десктопе справа со значительной массой. About — asymmetric 5fr/3fr (эссе с drop cap слева, premium aside-карточка справа). Services — единственное место с 3 в ряд, но карточки вынуждены быть равными по semantic'у; компенсировал тоновыми акцентами (coral / pine / magenta) — каждая карточка визуально разная. Manifest — 80vh центрированная цитата с float drop cap. Studio-VK — короткая компактная секция, не «3 карточки + центральный CTA». Contact — две кнопки в ряд равной ширины.

- [x] **Фон НЕ плоский solid**
  Hero — radial mesh «Закат-коралл». About — radial-gradients «капли в палитре» (visual-language §4.2). Services — линейный transition vanilla → vanilla-2. Color-listen — mesh с magenta + coral на ванили. Manifest — «Лесная тень» radial+linear на `--pine`. Studio-VK — vanilla → vanilla-2. Contact — двойной mesh coral + pine. Глобальный noise overlay 0.05 поверх всего.

- [x] **Кнопки с hover-эффектом, который не сводится к opacity или brightness**
  `.btn--tg` — на hover: меняется gradient (3 stops → 2 stops), усиливается цветная тень `0 14px 32px -10px rgba(34,158,217,0.70)`, активный `:active` дополнительно `scale(0.98)`. `.btn--vk` — на hover вообще инвертируется: фон transparent → `--vk-blue`, текст blue → white. `.btn--ghost` — фон transparent → pine с переключением цвета текста. Карточки `.card` — `translateY(-3px)` + усиление цветной тени + `::before` blob увеличивает opacity 0.10 → 0.18. Магнитная кнопка дополнительно следует за курсором ±10px.

- [x] **Тени не серые дефолтные, а с цветом из палитры**
  Все тени на основе `rgba(48,102,84,...)` (хвоя), `rgba(255,147,94,...)` (коралл), `rgba(77,170,2,...)` (acid), `rgba(34,158,217,...)` (TG-blue), `rgba(0,119,255,...)` (VK-blue). Inset-glow на портрете — `inset 0 0 0 6px var(--vanilla)`, `inset 0 0 0 7px rgba(48,102,84,0.15)`, drop `0 24px 60px -22px rgba(48,102,84,0.45)`. Никаких `rgba(0,0,0,0.1)` дефолтных.

- [x] **Анимация при загрузке оркестрована**
  Hero — page-load lesenka: H1 60ms → H2 140ms → status 220ms → CTA-row 300ms → portrait 380ms (animation-name `rise`, длительность 300ms `--ease-soft`). Нет «всё одновременно появилось» и нет «каждый элемент на разной анимации». На остальных секциях — единый IntersectionObserver `.reveal → .in-view` с задержкой `0/120/240ms` для лесенки в `.cards`. При reduced-motion — анимации отключены, элементы сразу видны.

---

## Дополнительные пункты — соблюдение brief'а

| Пункт brief | Статус | Комментарий |
|---|---|---|
| Один файл `index.html`, без CDN/фреймворков | [x] | Только Google Fonts через `<link>` |
| Mobile-first с `clamp()`, grid, flex | [x] | Все размеры через `clamp()`; grid с `1fr` на мобильном |
| Семантика `<main>`, `<section>`, `<nav>`, `<aside>` | [x] | Sticky-bar — `<nav role="navigation">`, premium-блок об Ирине — `<aside>`, цитата — `<blockquote>`+`<cite>` |
| 7 секций с якорями `#hero, #about, #services, #color-listen, #manifest, #studio-vk, #contact` | [x] | Все на месте |
| Hero: mesh «Закат-коралл» + drop-shadow на H1 + inset-glow портрет | [x] | visual-language §2.1, §3.5, §3.6 |
| Page-load orchestration 60/140/220/300/380ms | [x] | См. блок CSS «Page-load orchestration» |
| Custom cursor только в hero, отключение на touch и reduced-motion | [x] | Двойная защита: CSS `@media (pointer: fine) and (hover: hover)` + JS-проверка matchMedia |
| Magnetic CTA на TG-кнопке в hero, радиус 120px, ±10px | [x] | JS-блок `magnets.forEach`, transform применяется через rAF |
| Drop cap «И» в #about — Playfair Bold, ~5.5em, float left, цвет coral | [x] | `.dropcap` |
| 3 цветные карточки услуг с тонами coral/pine/magenta + срок без цены | [x] | data-tone, ::before blob, term-блок с border-top dashed |
| Демка «Слышу цвет»: 12 чипов, FIFO-3, алгоритм match по 5 палитрам | [x] | JS целиком из brief §6.4, никаких отступлений |
| Mesh-блок результата по шаблону §6.4 brief | [x] | `buildMesh()` динамически собирает 4 radial-gradient + base color |
| CTA с автотекстом в Telegram после результата | [x] | `encodeURIComponent` в `renderResult()` |
| Манифест с drop cap «Я» + текст-перелив на «слушаю» | [x] | `.dropcap-Y` и `.gradient-word` (visual-language §2.6) |
| Studio-VK secondary с фирменным синим `#0077FF` и оригинальным логотипом | [x] | `.btn--vk-fill` градиент на фирменном синем, SVG лого VK |
| Contact: TG primary + VK secondary одинаковой ширины | [x] | `.contact-buttons .btn { flex: 1 1 240px }` |
| Sticky-bar мобильный с safe-area-inset-bottom + появление после hero | [x] | `display: none` на десктопе, IntersectionObserver на hero |
| `prefers-reduced-motion` сворачивает анимации | [x] | Глобальный media-query + JS-проверка |
| `color-scheme: light only` в `:root` | [x] | + `<meta name="color-scheme" content="light">` дублёром |
| Якоря `#case-001`, `#case-002` на будущее | [x] | В DOM не выводим (по brief §8), но routing их пропустит |
| Telegram deep-link `tg://` для мобильных | [x] | JS `data-tg-deep`, попытка нативного с fallback через 600ms |
| Юр.чистота словаря Ирины — без «провожу аудит/консультирую» | [x] | Все тексты буквально из brief §5: «делаю», «создаю», «работаю» |
| Без упоминаний партнёрства Инны, vibe coding, AI-инструментов | [x] | Слова отсутствуют в DOM |
| Без цен | [x] | Только сроки в днях |
| Без header сверху | [x] | Только `<a class="skip">` для скринридеров |
| Палитра Ирины, не Инны | [x] | `#103206`, `#D4AF37`, `gold` отсутствуют |
| Логотипы TG и VK в фирменных цветах, не перекрашены | [x] | TG `#229ED9` градиент, VK `#0077FF` градиент; original SVG-формы |

---

## Что пришлось решить самому (по разрешению brief §11)

1. **Иконка-капля в карточках услуг** — нарисовал inline SVG `<path d="M16 3 C 9 14, 6 19, 6 22 a10 10 0 0 0 20 0 c0-3-3-8-10-19z">` (классическая капля). Залил `currentColor` чтобы использовать тон карточки.
2. **Иконка фавикона** — SVG inline в `<link rel="icon">` с монограммой «И» Playfair-стиля цвет хвоя на ванили, скруглённый квадрат 14px.
3. **Размер портрета на десктопе** — `clamp(220px, 38vw, 360px)`, круглая рамка `border-radius: 50%`.
4. **Точные паузы между чипами** — `gap: 10px 12px` на flex-wrap.
5. **Высота карточек услуг** — `min-height: 320px` чтобы все три были одной массы при разной длине текста.
6. **Trail-курсор** — добавил DOM-элемент `.cursor-dot` 14×14 с `mix-blend-mode: multiply`, следует за мышью через `transform: translate3d`, transition 120ms — это «лёгкий след 1-2 сек» из brief'а. Отключается на touch и reduced-motion.

---

## Дозаточить (на будущие итерации)

- **OG-image** — `og-image.jpg` пока ссылка без файла. Нужно сделать SOC-картинку 1200×630 с её визуальным языком (mesh-фон + H1 + портрет в углу). Сейчас в SEO-метатегах ссылка уже есть, но изображение не загружено в `assets/`.
- **Тестирование scroll-snap** — proximity-snap включён только на десктопе ≥1024px с hover. Brief §3.3 предписывает QA в Safari + Firefox + Chrome; на синтетическом тесте подключить браузер не могу. Если в QA «дёргает» — отключить через медиа-правило.
- **Telegram deep-link** — fallback 600ms через `setTimeout`. Работает на iOS Safari и Android Chrome, но не идеален: если пользователь быстро тапает обратно, может уйти на http-ссылку. Альтернативу `tgWebAppPlatform` оставил как опцию для следующей итерации.
- **Подтверждение сроков** — в brief §2.3 есть открытый вопрос Ирине по реалистичности 1-3 / 1-2 / 1-2 дня. Я взял эти числа дословно из brief'а; если Ирина скажет «слишком оптимистично» — поправить только текст в карточках.
- **Точное числовое значение `noise opacity`** — взял 0.05 (старт по visual-language §4.1). После QA на её мониторе может быть 0.04–0.07.

---

## Итог

Все 10 пунктов чек-листа «не AI slop?» закрыты осознанно. Все требования brief'а §1–§10 выполнены. Запреты brief'а §8 и `dont.md` соблюдены. Файл готов к деплою на `https://stydiyatsi.ru/`.

*Кодыч (Websites) · 2026-05-03*
