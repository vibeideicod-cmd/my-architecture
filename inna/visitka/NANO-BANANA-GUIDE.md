# Nano Banana — пошаговая инструкция для Инны

> Цель документа: сесть и через 15 минут начать генерировать визуалы для визитки.
> Nano Banana — это кодовое имя модели Google **Gemini 2.5 Flash Image**.
> Главное её отличие — она не теряет лицо при правках и понимает промпт на естественном языке как обычный чат.

---

## 1. Где Nano Banana живёт

Два рабочих интерфейса:

| Что | Адрес | Когда лучше |
|---|---|---|
| **Gemini app** | https://gemini.google.com | Привычный чат-интерфейс. Загружаешь фото, пишешь словами, получаешь картинку. **Этот используем сейчас.** |
| **Google AI Studio** | https://aistudio.google.com | Для разработчиков. Те же модели, больше параметров, можно через API. Понадобится потом, когда будем строить агента-генератора. |

В России обычно требуется **VPN**, иначе сайт не откроется или вернёт «недоступен». У тебя VPN-сервер уже есть (тот, что vpn-london).

---

## 2. С нуля — что сделать один раз

1. **Включить VPN.** В системе подключиться к vpn-london. Проверка: открой https://www.google.com — если открывается без ошибок, VPN работает.
2. **Войти в Google.** Открой https://gemini.google.com и войди под своей Google-почтой. Если её нет — заведи (5 минут).
3. **Подписка.** Бесплатный план даёт несколько генераций изображений в день. Если делаем серию — нужен **Google AI Pro** (раньше назывался Gemini Advanced), это ~$20/мес или ~2000 ₽. Для 5 hero-композиций бесплатного плана хватит, для серии mini-app и постов — лучше подписка. Подписку можно включить кнопкой «Upgrade» сверху и отменить через месяц.
4. **Выбрать модель.** В верхней части окна — селектор модели. Выбираем **Gemini 2.5 Flash Image** (она же Nano Banana). Если такой опции нет — выбери самую свежую с пометкой «image» или «multimodal».

Это всё, дальше работаешь как в обычном чате.

---

## 3. Как загрузить фото и написать промпт

1. В нижней части окна Gemini есть **скрепка / иконка вложения**. Жмёшь, выбираешь файл с компа.
2. Грузишь твою фотку с VK-баннера (она уже есть в `inbox-inna/archive/2026-04-27_vk-banner-v10-103206.png`).
3. Под фото в том же поле — пишешь промпт. На английском Nano Banana работает заметно точнее, чем на русском. Промпты ниже даны на английском, не нужно переводить.
4. Жмёшь «Send» / Enter.
5. Ждёшь 10-20 секунд. Получаешь 1-4 варианта (зависит от плана).
6. Жмёшь правой кнопкой по понравившемуся → «Save image as» → сохраняешь в `clients/inna/visitka/assets/inna-hero.jpg`.

**Если результат не тот** — пишешь следующим сообщением «correction please: <что не так>». Например: «too cyberpunk, make it more premium magazine», или «keep the face exactly the same, only change the background», или «the gold lines should be thinner». Nano Banana помнит контекст диалога — каждое следующее сообщение это правка предыдущего, не новая генерация с нуля. Это её главная сила.

---

## 4. Принципы промпта

Хороший промпт для Nano Banana — это короткое тех.задание из 4 блоков:

```
1. БАЗА: что делаем (edit / generate / compose).
2. ЛИЦО И ИДЕНТИЧНОСТЬ: что не трогаем (face, hair, expression, clothing).
3. ИЗМЕНЕНИЯ: что меняем (background, lighting, style, composition).
4. ТЕХНИКА: формат, освещение, стиль (cinematic, magazine, premium, no cyberpunk).
```

**Жёсткие запреты в КАЖДОМ промпте** (вшиваем в конец):
- `no cyberpunk, no neon glow, no AI-glow halo, no plastic skin, no photorealistic stock photo aesthetic` — иначе модель уползает в дешёвый «техно-портрет».

---

## 5. Промпты для визитки (от простого к сильному)

### Промпт 1 — базовый «премиум на тёмно-зелёном» (попробуй первым, чтобы привыкнуть)

```
Edit this photo of the woman. Replace the background with a deep forest green (#103206)
fading to almost black at the bottom edge. Apply cinematic colour grading: warm
highlights on her face, deeper shadows, subtle warm vignette. Add a thin elegant gold
rim-light (#D4AF37) along the right edge of her silhouette — hair and shoulder.
Add subtle film grain.
Keep her face, hair, expression and clothing exactly as they are.
Output 1920×1080, portrait positioned on the right two-thirds, leave clean negative
space on the left for typography.
Style: editorial portrait for a premium magazine. NO cyberpunk, NO neon glow, NO
AI-glow halo, NO plastic skin, NO stock photo aesthetic.
```

### Промпт 2 — «Архитектор автосистем» (главный кандидат на hero)

Это про тебя. Лицо вписано в архитектурную схему из тонких золотых линий — будто blueprint вокруг человека. Премиум, технологично, без неона.

```
Edit this photo. Place the woman against a deep forest green background (#103206
fading to #0A1F03). Behind and around her, render an architectural blueprint of
fine gold (#D4AF37) lines and small connection nodes — like an isometric system
diagram or neural-network graph drawn with engineering precision. The lines should
flow softly behind her shoulders and gently across the negative space, NOT cover
her face.
Lighting on her face: cinematic, warm side-light, subtle gold reflection on the
right cheekbone. Add subtle film grain and a very faint warm vignette.
Keep her face, expression, hairstyle and clothing 100% unchanged.
Composition: portrait positioned on the right two-thirds, blueprint pattern occupies
the left third and gently wraps behind her.
Output 1920×1080, editorial premium magazine quality.
Style references: Wired magazine cover, architectural drawing, technical blueprint
overlay. NO cyberpunk, NO neon glow, NO sci-fi UI, NO plastic skin, NO holographic
clichés.
```

### Промпт 3 — «Двойная экспозиция, граф знаний»

Для альтернативного hero — портрет с наложением графа узлов, как будто архитектура мысли проступает через волосы и плечи. Артистичный, более художественный.

```
Edit this photo. Apply double-exposure technique: the woman's portrait is the primary
layer, gently merging with a secondary layer of fine gold (#D4AF37) network graph —
small circular nodes connected by thin lines, like a knowledge graph or system
architecture diagram. The graph appears in her hair, on her shoulders, and across the
negative space, but her face remains crystal clear and untouched.
Background: deep forest green (#103206 to #0A1F03 vertical gradient).
Lighting: cinematic warm side-light. Add film grain and subtle warm vignette.
Keep face, expression, hairstyle, clothing exactly as in the source.
Output 1920×1080.
Style: contemporary editorial portrait with subtle technical overlay. NO cyberpunk,
NO neon, NO AI-glow halo, NO plastic skin, NO sci-fi.
```

### Промпт 4 — «Узлы С.С.С.Р. вокруг»

Буквальная иллюстрация методологии: вокруг портрета — четыре светящихся узла С / С / С / Р, соединённых тонкими золотыми линиями. Портрет в центре композиции.

```
Compose a portrait scene. Place the woman in the centre of the frame against a deep
forest green background (#103206). Around her, in symmetrical positions (top-left,
top-right, bottom-left, bottom-right), draw four small luminous gold circles — each
circle contains a single Cyrillic letter in serif typography: С, С, С, Р. Connect
all four circles with thin gold lines that pass behind her, NOT across her face.
The visual reads as a system diagram with the woman as its centre.
Lighting on her face: cinematic, warm. Subtle film grain. Warm vignette.
Keep face, expression, hair, clothing exactly as in the source.
Output 1920×1080.
Style: architectural diagram meets editorial portrait. Premium, restrained, NOT
flashy. NO cyberpunk, NO neon, NO sci-fi, NO holographic effects.
```

### Промпт 5 — обложка PDF (после того, как hero выбран)

```
Reframe the chosen hero image to A4 landscape format (3508×2480 at 300 dpi).
Position the figure on the right third. Adjust the background gradient to flow from
#103206 at the top to #244C3F at the bottom. Add a single thin gold horizontal line
across the lower third — this is the typography baseline for the future PDF cover.
Keep face, expression, lighting and grain consistent with the source.
NO cyberpunk, NO neon, NO stock aesthetic.
```

---

## 6. Стратегия — как пройти за 30 минут

1. **Прогон 1 (5 мин)** — Промпт 1. Привыкаешь к интерфейсу, видишь как модель читает твоё лицо.
2. **Прогон 2 (10 мин)** — Промпт 2 (главный кандидат). Если получилось как надо → сохраняешь как `inna-hero.jpg`. Если ушло в киберпанк → правка следующим сообщением: `too neon, more like a printed architectural blueprint, less glow`.
3. **Прогон 3 (10 мин)** — Промпт 3 для альтернативы. Сравниваешь с прогоном 2, выбираешь финальный.
4. **Прогон 4 (5 мин)** — Промпт 5, обложка PDF (только когда hero уже выбран).

Промпт 4 (узлы С.С.С.Р.) — опционально, если хочется буквальную иллюстрацию. Это сложный для модели запрос, может занять 3-5 итераций с правками.

---

## 7. Куда сохранять

| Что | Куда |
|---|---|
| Главный hero | `clients/inna/visitka/assets/inna-hero.jpg` |
| Альтернативный hero | `clients/inna/visitka/assets/inna-hero-alt.jpg` |
| Обложка PDF | `clients/inna/visitka/assets/inna-pdf-cover.jpg` |
| Все варианты, которые не пошли | `clients/inna/visitka/assets/_drafts/` |

Когда положишь файл — скажи мне, я открою визитку, проверю как смотрится с реальным портретом, и тогда возвращаемся к доработкам дизайна (кружки С.С.С.Р., возможно технологический слой).

---

## 8. Если что-то идёт не так

| Симптом | Что писать в чат Gemini следующим сообщением |
|---|---|
| Лицо «уехало», стало другим | `Keep the original face EXACTLY as in the source photo. Only change <что меняем>. Do not redraw the face.` |
| Слишком киберпанк / неон | `Less cyberpunk, less neon. More premium printed magazine aesthetic. Gold should be metallic, not glowing.` |
| Слишком плоско, как сток | `Add depth and editorial mood. Cinematic side-light, subtle warm grain, magazine-cover quality.` |
| Линии слишком толстые / кричат | `Make the gold lines thinner and more subtle. They should be a quiet background pattern, not the main subject.` |
| Фон не тот зелёный | `The background green should be exactly #103206 (deep forest), not bright or pure green. Add explicit hex code in your interpretation.` |
| Композиция не та | `Move the figure to the right two-thirds of the frame, leave clean negative space on the left.` |

Промпты не нужно писать заново — Nano Banana помнит весь чат, поэтому правка следующим сообщением действует на текущий результат.

---

*Файл живёт в `clients/inna/visitka/NANO-BANANA-GUIDE.md`. Обновляется по мере опыта.*
