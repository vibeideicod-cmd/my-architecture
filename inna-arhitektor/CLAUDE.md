# Проект: Инна Архитектор — персональная визитка

## Контекст ветки

Это **изолированная ветка** в корне `my-architecture/` (не в `clients/`). Создана 2026-04-20 для теста `skill-conductor` на реальной продуктовой задаче.

**Продукт:** персональная визитка Инны Андрейченко, доступная в 3 формах:
1. По ссылке в браузере (можно прикрепить к любому сообщению)
2. Как Telegram Mini App
3. Как VK Mini App / VK-визитка

**Подход:** делаем не ad-hoc HTML, а **скилл** `inna-architect`, который шаблонизирует генерацию визиток под 3 платформы. Позже тот же скилл породит визитки для экспертов мастер-группы.

## 🔴 Позиционирование

На визитке показываем: **«Инна Архитектор — автосистем и коммуникаций»**.

**НЕ показываем:** бренд «Нейро Бабки СССР» (ни текстом, ни логотипом). Это личный бренд Инны — отдельная арена от агентства.

**Источник био-фактов:** `../clients/neuro-babki/` + `../knowledge/clients/` как удобная папка с данными о Инне, но упаковка снаружи — «Инна Архитектор».

## Палитра (из брендбука НБ, без маркеров НБ)

- Фон: тёмный `#0a0a0a` или `#103206`
- Текст: `#e8e0d8`
- Акцент: `#c99700` (горчичный) + `#e86c3a` (оранжевый)
- Шрифты: Montserrat + Playfair Display (Google Fonts)

## Документы проекта (по Playbook)

| Файл | Фаза | Ответственный |
|---|---|---|
| [idea.md](idea.md) | 1 Discovery | product-builder |
| [research.md](research.md) | 2 Research | analyst |
| [critique.md](critique.md) | 2.5 Critique | product-builder |
| [brief.md](brief.md) | 3 Plan | product-builder → skill-conductor |
| [skills/inna-architect/](skills/inna-architect/) | 4 Build | skill-conductor |
| [output/](output/) | 5 Content | скилл генерирует HTML |
| [TESTING.md](TESTING.md) | 6 QA | qa |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 6 Deploy | deployer-beget |
| [PLAN.md](PLAN.md) | сквозной | Директор |

## Корневые правила

Следуй корневому [../CLAUDE.md](../CLAUDE.md) + особое уточнение для этой ветки:

- **Не смешивать с агентскими продуктами.** Визитка Инны Архитектора не ссылается на НБ и не появляется в `/hub/`/`/Irina/` структуре.
- **Новый тип продукта «Скилл-продукт».** Этот проект — пилот типа, которого в матрице Playbook ещё не было. По итогу расширяем [../knowledge/playbooks/product-creation.md](../knowledge/playbooks/product-creation.md).
- **VK Mini App — белое пятно.** В рамках этого проекта создаём [../knowledge/prompting/templates-vk-mini-app.md](../knowledge/prompting/templates-vk-mini-app.md).

## Активация директора

До любого ответа на задачу по этой ветке — прочитай [../agents/director.md](../agents/director.md) и работай в роли Директора. **Обязательно сообщи Инне в начале ответа на какой фазе сейчас проект** (фаза в [PLAN.md](PLAN.md)).

## Структура инструментов и продуктов

- `skill-conductor/` — **инструмент** (копия из `~/.claude/skills/skill-conductor/`, положила Инна 2026-04-20). Используется для создания нового скилла.
- `skills/` — **результат**: сюда через `skill-conductor` CREATE складываем новые скиллы проекта. Первый — `skills/inna-architect/`.
- `output/{browser,tma,vk}/` — сгенерированные HTML-визитки (результат применения скилла к данным Инны).
