# PLAN — Инна Архитектор

> Тактический план по ветке «Инна Архитектор».
> Стратегический — в корневом [../PLAN.md](../PLAN.md).
> Процесс — [../knowledge/playbooks/product-creation.md](../knowledge/playbooks/product-creation.md).

---

## Текущая фаза

**Фаза 1 — Discovery** — собираем мини-анкету по контенту визитки Инны.

**Тип продукта:** Скилл-продукт *(новый тип, добавляем в матрицу Playbook в Фазе 3)*
**Хостинг:** Beget, путь `/inna/` *(требует уточнения — поддомен или путь)*

---

## 🔥 Сейчас (блокеры и горящее)

- [>] Мини-анкета Инне по контенту визитки (CTA / кейсы / tone / фото / контакты)

---

## 📋 Чеклист по фазам

**Легенда:** `[ ]` не начато · `[>]` в работе · `[x]` готово · `[!]` блокер · `[~]` отложено

### Фаза 0 — Скаффолд ветки
- [x] Создана папка `inna-arhitektor/` + подпапки `skills/`, `output/{browser,tma,vk}/`
- [x] Создан `CLAUDE.md` с правилами изоляции и позиционированием
- [x] Создан `PLAN.md` (этот файл)
- [x] Инна положила `skill-conductor/` в корень ветки (инструмент рядом со `skills/` где будут продукты)

### Фаза 1 — Discovery
**Ответственный:** product-builder · **Артефакт:** [idea.md](idea.md)

- [ ] Прочитать источники: `../clients/neuro-babki/about.md`, `../index.html`, `../Irina/vizitka.html`
- [ ] Задать Инне 6 узких вопросов одним заходом (CTA / кейсы / tone / фото / что НЕ показывать)
- [ ] Заполнить `idea.md` с разделом «Позиционирование» и «Чего НЕ будет»
- [ ] Формулировка подтверждена Инной

### Фаза 2 — Research
**Ответственный:** analyst · **Артефакт:** [research.md](research.md)

- [ ] Выжимка `../clients/mastergroup/mvp/` — паттерн HTML + Supabase + Beget
- [ ] Выжимка `../clients/beauty/tg-app/` — TMA с Telegram SDK
- [ ] Выжимка `../clients/alisa/` — персональная визитка на Beget
- [ ] VK Mini App API — VK Bridge, манифест, деплой (30 мин ресёрч)

### Фаза 2.5 — Critique
**Ответственный:** product-builder · **Артефакт:** [critique.md](critique.md)

- [ ] Глазами эксперт-аудитории Инны (инфобиз)
- [ ] Глазами UX-дизайнера Ирины
- [ ] Глазами конкурента (другой «архитектор автосистем»)
- [ ] «Ты уверен?» на позиционировании и палитре

### Фаза 3 — Design + апгрейд Playbook
**Ответственный:** product-builder · **Артефакты:** [brief.md](brief.md) + правки Playbook

- [ ] `brief.md`: секции визитки, архетип, палитра, поведение per-platform
- [ ] Выбор визуального архетипа (2-3 варианта Инне на выбор)
- [ ] Апгрейд `../knowledge/playbooks/product-creation.md`: тип «Скилл-продукт» + строка VK Mini App из TBD в Ready
- [ ] Создание `../knowledge/prompting/templates-vk-mini-app.md`

### Фаза 4 — Build (через skill-conductor)
**Ответственный:** skill-conductor · **Артефакты:** `skills/inna-architect/**`

- [ ] skill-conductor Step 1 Intent (переиспользуем `idea.md`)
- [ ] skill-conductor Step 2 Baseline (проверка что без скилла не работает)
- [ ] skill-conductor Step 3 Architecture (pattern: Context-aware selection)
- [ ] skill-conductor Step 4 Scaffold (`init_skill.py`)
- [ ] skill-conductor Step 5 SKILL.md + references + templates (browser/tma/vk)
- [ ] skill-conductor Step 6 Evals (3 тест-кейса)
- [ ] `uv run scripts/eval_skill.py skills/inna-architect` → 10/10

### Фаза 5 — Content
**Ответственные:** скилл + Инна

- [ ] Инна заполняет контент-схему (JSON) с реальными данными
- [ ] Прогон скилла → 3 HTML в `output/{browser,tma,vk}/index.html`
- [ ] Все заглушки заменены, фото/аватар вставлены

### Фаза 6 — QA + Deploy
**Ответственные:** qa → deployer-beget

- [ ] QA по чеклисту `../agents/qa.md` + адаптив 375/768/1440
- [ ] `deploy-inna.sh` (копия `deploy-mg.sh`, путь `/inna/`)
- [ ] Деплой на Beget
- [ ] 3 финальных теста: браузер / TMA через тест-бот / VK Mini App через dev-центр
- [ ] Финальная приёмка Инной

---

## ✅ Готово

- [x] 2026-04-20 — Скаффолд ветки (Фаза 0 частично)

---

## ❓ Открытые решения (требуют слова Инны)

- [ ] Домен/путь деплоя: отдельный поддомен без маркеров НБ или путь `/inna/` на существующем?
- [ ] Визуальный архетип — предложим 2-3 варианта после idea.md
- [ ] Tone of voice: экспертный-сдержанный или тёплый-дружеский?

---

## 🐛 Известные баги

*Пока пусто.*
