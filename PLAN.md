# PLAN — Нейро Бабки СССР (стратегический план агентства)

> Общий план по агентству и кросс-клиентским задачам.
> Тактические планы по конкретным клиентам — внутри их папок:
> - [clients/beauty/PLAN.md](clients/beauty/PLAN.md)
> - [clients/yuzhnoberezhniy/](clients/yuzhnoberezhniy/) (PLAN.md TBD)
> - [clients/neuro-babki/](clients/neuro-babki/) (PLAN.md TBD)

---

## 🔥 Сейчас (что в работе)

### Реструктуризация архитектуры (апрель 2026)
Цель: убрать ощущение «раздрая», навести порядок в корне, дать каждому клиенту своё место и свой план.

- [x] Шаг 1 — Beauty переехал в `clients/beauty/` (2026-04-12)
- [x] Создан `clients/beauty/PLAN.md` + обновлён корневой `PLAN.md` под двухуровневую систему
- [x] Шаг 2 — Разобран корневой хлам, документы Нейро Бабки в `clients/neuro-babki/`, создан корневой `README.md` (2026-04-12)
- [ ] Шаг 3 — Усилить `agents/director.md` фазами жизненного цикла проекта (Discovery → Research → Design → Build → Content → QA → Deploy)
- [ ] Шаг 4 — Усилить `clients/_template/` (добавить `PLAN.md.template`, `README.md`, заготовку `brief.md`)
- [ ] Шаг 5 — Превратить `ideas.md` в структурированную копилку отложенного + механизм «идея → план клиента»
- [ ] **Шаг 6 (отложенный, рисковый)** — Перенести production HTML (`index.html`, `hub/`, `Irina/`) в `clients/neuro-babki/` с обновлением `deploy-beget.sh` и `deploy-hub.sh`. Делать после того как закроем 3-5 и убедимся что архитектура устаканилась.

---

## 📋 Активные клиенты

| Клиент | Папка | Фаза | Главное сейчас |
|---|---|---|---|
| **Beauty Визитка** | [clients/beauty/](clients/beauty/) | Build | Починить BUG-001 (TMA некликабельна) |
| **Южнобережный (ЮБ)** | [clients/yuzhnoberezhniy/](clients/yuzhnoberezhniy/) | Build / Deploy | Деплой `demo.` субдомена (старый хвост) |
| **Нейро Бабки (мы сами)** | [clients/neuro-babki/](clients/neuro-babki/) | Content / Build | Главный сайт + HUB лендинг |

---

## 🧱 Сайт «Нейро Бабки СССР» (мы как клиент)

Это страницы нашего собственного бренда — лендинги, визитки, HUB.

### Готово
- [x] Главная визитка ([index.html](index.html))
- [x] HUB лендинг ([hub/index.html](hub/index.html))
- [x] Визитка Ирины ([Irina/vizitka.html](Irina/vizitka.html))
- [x] Лендинг Ирины ([Irina/landing-irina.html](Irina/landing-irina.html))

### В очереди
- [ ] Страница тарифов
- [ ] Страница контактов
- [ ] Форма обратной связи
- [ ] Портфолио с примерами работ

---

## 🛠 Инфраструктура и процессы

- [x] Деплой на Beget через `deploy-beget.sh`
- [x] Скрипт деплоя ЮБ (`deploy-yub.sh`)
- [x] Скрипт деплоя HUB (`deploy-hub.sh`)
- [x] Сессионная память в `/memory/`
- [x] 10 агентов в `/agents/` (Director, Analyst, Branding, Content, Systems, Websites, Product-Builder, QA, Deployer, Git Manager)
- [ ] Усилить `director.md` фазами жизненного цикла (Шаг 3)
- [ ] PLAN.md в каждом активном клиенте (Beauty готов, ЮБ и neuro-babki в очереди)
- [ ] Скрипт `deploy-beauty.sh` (когда мигрируем с Vercel)

---

## 💡 Идеи и отложенное

См. [ideas.md](ideas.md) — там копятся продуктовые идеи и архитектурные «может быть потом» (отдельный Copywriter, Frontend/Backend Dev агенты, общие компоненты и т.д.).

---

## Принципы работы планами

1. **Корневой `PLAN.md`** — только стратегия и кросс-клиентские задачи. Сюда не падают мелочи конкретного клиента.
2. **`clients/{имя}/PLAN.md`** — тактика по этому клиенту. Сюда падают баги, контентные правки, фазы реализации.
3. **`ideas.md`** — то что не делаем сейчас, но не хочется забыть.
4. **`memory/session-log.md`** — хроника сессий, что обсуждали и решили.
