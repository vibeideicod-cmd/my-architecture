# PLAN — Инна Архитектор

> Тактический план по ветке «Инна Архитектор».
> Стратегический — в корневом [../PLAN.md](../PLAN.md).
> Процесс — [../knowledge/playbooks/product-creation.md](../knowledge/playbooks/product-creation.md).

---

## Текущая фаза

**Фаза 4 — Build** — стартую skill-conductor CREATE для `inna-architect`.

**Тип продукта:** Скилл-продукт *(новый тип в матрице Playbook)*
**Хостинг:** Beget (домен — TBD)
**Позиционирование:** «Инна Архитектор — собираю автосистемы продаж экспертам и оффлайн-бизнесу»
**Палитра:** тёмно-зелёный `#103206` + горчичный `#c99700`, архетип Редакционный

---

## 🔥 Сейчас (блокеры и горящее)

- [>] Build скилла `inna-architect` через skill-conductor CREATE
- [ ] От Инны нужны позже (НЕ блокирует Build): фото, TG канал, TG direct, домен deploy, цифры в триггерах скорости

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

- [x] Прочитать источники: `about.md`, `index.html`, `Irina/vizitka.html`
- [x] Собрана концепция лид-машины с 3 опциями и 100% гейтом на контакт

### Фаза 2 — Research
**Ответственный:** analyst · **Артефакт:** [research.md](research.md)

- [x] Внутренние паттерны: MG (конструктор) + Beauty (TMA init) + Alisa (дизайн)
- [x] 7 мировых лид-магнитов экспертов
- [x] VK Mini App quick-start (VKWebAppGetEmail как нативный гейт)
- [x] Бенчмарки конверсии (Unbounce, HubSpot, ConvertKit)

### Фаза 2.5 — Critique
**Ответственный:** product-builder · **Артефакт:** [critique.md](critique.md)

- [x] 7 рисков найдены и зафиксированы
- [x] Плоский список без выдуманных персонажей
- [x] Упрощённый MVP предложен: одна опция, 2 платформы в v1, метрика 30-45%

### Фаза 3 — Design + апгрейд Playbook
**Ответственный:** product-builder · **Артефакты:** [brief.md](brief.md) + правки Playbook

- [x] `brief.md`: секции, архетип Редакционный, палитра, платформы, скилл-файлы
- [x] Позиционирование зафиксировано: «Собираю автосистемы продаж экспертам и оффлайн-бизнесу»
- [x] Палитра утверждена: `#103206` тёмно-зелёный + `#c99700` горчичный
- [ ] Апгрейд `../knowledge/playbooks/product-creation.md` (отложено, не блокирует Build)
- [ ] Создание `../knowledge/prompting/templates-vk-mini-app.md` (отложено до v1.1)

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
