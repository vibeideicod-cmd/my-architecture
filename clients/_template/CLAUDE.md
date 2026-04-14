# Проект: [Название клиента]

## Контекст клиента

- **Название:** [Название]
- **Сфера:** [санаторий / магазин / сервис / другое]
- **Город:** [город]
- **Сайт / соцсети:** [ссылки, если есть]
- **Текущая фаза:** смотри [PLAN.md](PLAN.md) раздел «Текущая фаза»

## Специфика этого проекта

[Особые требования клиента, фирменные цвета, тон коммуникации, ограничения, что нельзя трогать]

## Документы проекта (по Playbook)

Не все файлы нужны сразу — они появляются по ходу фаз:

| Файл | Фаза | Ответственный |
|---|---|---|
| [idea.md](idea.md) | 1 Discovery | product-builder |
| [research.md](research.md) | 2 Research | analyst |
| [critique.md](critique.md) | 2.5 Critique | product-builder |
| [brief.md](brief.md) | 3 Plan | product-builder → специалист |
| [BACKEND-PLAN.md](BACKEND-PLAN.md) | 3 Plan | systems (если нужен бэкенд) |
| Код проекта + CLAUDE.md-карта | 4-5 Build/Content | websites / systems |
| [TESTING.md](TESTING.md) | 6 QA | qa |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 6 Deploy | deployer-beget |
| [PLAN.md](PLAN.md) | сквозной | Директор (обновляет фазы) |
| [project-log.md](project-log.md) | сквозной | Директор (хроника) |

## Универсальный процесс

Перед любой задачей читай [knowledge/playbooks/product-creation.md](../../knowledge/playbooks/product-creation.md) — там собраны все фазы, типы продуктов, промпт-шаблоны.

## Корневые правила

Следуй всем правилам из корневого [CLAUDE.md](../../CLAUDE.md) и:
- Дизайн-система: [/knowledge/standards/design-system.md](../../knowledge/standards/design-system.md)
- Методология СССР: [/knowledge/methodology/](../../knowledge/methodology/)
- Жизненный цикл проекта: [/agents/director.md](../../agents/director.md) раздел «Жизненный цикл проекта»

## Активация директора

До любого ответа на задачу прочитай [/agents/director.md](../../agents/director.md) и работай в роли Директора. **Обязательно сообщи Инне в начале ответа на какой фазе сейчас этот клиент** (фаза хранится в [PLAN.md](PLAN.md)).
