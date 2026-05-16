# Model Runtime Audit — агенты, модели, Codex и Claude Code

Дата: 2026-05-16  
Статус: preflight-аудит перед приёмочным аудитом архитектуры

## Зачем этот файл

Нужно понять не “какая таблица права”, а:

- какая модель оптимальна для роли по качеству и экономии;
- где модель реально исполняется в Claude Code;
- где модель в `agents/*.md` является только справочной строкой;
- что должен проверять Codex;
- что нужно проверять именно в Claude Code.

Связанная стратегия: [knowledge/tools/codex-claude-operating-strategy.md](knowledge/tools/codex-claude-operating-strategy.md).

## Короткий вывод

Команда по смыслу не изменилась: **31 агент**.

Главный рассинхрон не в составе команды, а в слоях:

- `model-map.md` и `team-overview.md` держат целевую экономическую карту: **6 Opus / 23 Sonnet / 2 Haiku**.
- `.claude/skills/*/SKILL.md` в ключевых местах уже совпадают с целевой картой: `marketer`, `systems`, `ai-builder`, `product-builder` на Opus; `git-manager`, `deployer-beget`, `deploy`, `seo` на Haiku.
- `.claude/agents/` содержит 2 runtime-subagent: `git-manager` и `deployer-beget`, оба Haiku.
- `agents/*.md` в основном являются контекст-агентами. Их строка “Модель” справочная, если агент не вынесен в `.claude/agents/` или skill. Поэтому рассинхрон в `agents/*.md` чаще является **документационным долгом**, а не реальным расходом модели.

## Pass/fail перед аудитом

| Проверка | Вердикт | Комментарий |
|---|---|---|
| Понятно, сколько агентов | PASS | 31 агент: 3 вне департаментов + 28 в 11 департаментах |
| Есть целевая модельная карта | PASS | `model-map.md` и `team-overview.md` совпадают: 6/23/2 |
| Есть runtime-модели у Claude subagents | PASS | 2 subagent: git/deploy на Haiku |
| Есть runtime-модели у Claude skills | PASS | `model:` есть в skill frontmatter |
| `agents/*.md` синхронизированы с модельной картой | PARTIAL FAIL | 4 явных рассинхрона: Director, Marketer, Systems, AI Builder |
| Понятно, как Codex учитывает модели | PASS после стратегии | Codex не переключается по Claude frontmatter, использует документы как инструкции |

## Таблица по 31 агенту

Легенда:

- **Runtime-критично** - реально влияет на модель при запуске в Claude Code.
- **Док-долг** - строка вводит в заблуждение, но сама по себе не переключает модель.
- **OK** - слои согласованы или расхождение отсутствует.
- **Решить** - нужна содержательная политика, не механическая правка.

| Агент | Цель в `model-map/team-overview` | `agents/*.md` | `.claude runtime` | Тип | Решение |
|---|---|---|---|---|---|
| Director | Sonnet | Opus | нет subagent/skill | Док-долг + решить | Операционная маршрутизация = Sonnet. Архитектурный аудит может временно идти на сильной модели сессии Codex/Claude, но не делать Opus постоянным без решения |
| Skill-Auditor | Sonnet | Sonnet | skill не найден отдельным runtime в текущем списке, есть agent-файл | OK | Оставить Sonnet |
| Librarian | Sonnet | Sonnet | нет отдельного runtime | OK | Оставить Sonnet |
| Branding | Sonnet | Sonnet | skill `branding` = Sonnet | OK | Оставить Sonnet |
| Brandbook Creator | Sonnet | Sonnet | skill `brandbook-creator` = Sonnet | OK | Оставить Sonnet |
| Marketer | Opus | Sonnet | skill `marketer` = Opus | Док-долг + решить | Стратегия каналов и кампаний = Opus. Текущие кампании и контент можно вести через Sonnet-специалистов. Заголовок `agents/marketer.md` требует решения/синхронизации |
| Marketing-Strategist | Opus | Opus | отдельного skill не видно | OK | Оставить Opus для глубокой стратегии |
| Content | Sonnet | Sonnet | skill `content` = Sonnet | OK | Оставить Sonnet |
| Copywriter | Sonnet | Sonnet | skill `copywriter` = Sonnet | OK | Оставить Sonnet |
| SMM-Manager | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| Sales | Sonnet | Sonnet | skill `sales` = Sonnet | OK | Оставить Sonnet |
| Product Builder | Opus | Opus | skill `product-builder` = Opus, `discovery` = Opus | OK | Оставить Opus |
| Websites | Sonnet | Sonnet | skill `websites` = Sonnet | OK | Оставить Sonnet; Codex может делать точечные правки/проверки дешевле как repo-исполнитель |
| Systems | Opus | Sonnet | skill `systems` = Opus | Док-долг + решить | Архитектура ботов/CRM/интеграций = Opus. Точечная реализация/фикс по готовому плану может идти через Codex/Sonnet. Заголовок `agents/systems.md` рассинхронен |
| AI Builder | Opus | Sonnet | skill `ai-builder` = Opus | Док-долг + решить | Старт AI-продукта, сценарии и архитектура = Opus. Обслуживание базы/промпта по готовой схеме может быть Sonnet/Codex. Заголовок `agents/ai-builder.md` рассинхронен |
| Analytics-Head | Sonnet | Sonnet | skill `analytics-head` = Sonnet | OK | Оставить Sonnet |
| Analyst | Sonnet | Sonnet | skill `analyst` = Sonnet | OK | Оставить Sonnet |
| Product-Analyst | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| Audience-Researcher | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| Planner | Sonnet | Sonnet | skill `planner` = Sonnet | OK | Оставить Sonnet |
| Project-Manager | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| Financial | Sonnet | Sonnet | skill `financial` = Sonnet | OK | Оставить Sonnet |
| Pricing-Specialist | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| Yuridika | Sonnet | Sonnet | skill `yuridika` = Sonnet | OK | Оставить Sonnet |
| Contract-Lawyer | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| PD-Lawyer | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| DevOps/Infra | Sonnet | Sonnet | skill `devops-infra` = Sonnet, `monitoring-check` = Sonnet | OK | Оставить Sonnet |
| Git Manager | Haiku | Haiku | subagent `git-manager` = Haiku, skill `git-manager` = Haiku | Runtime OK | Оставить Haiku |
| Deployer-Beget | Haiku | Haiku | subagent `deployer-beget` = Haiku, skills `deployer-beget`/`deploy` = Haiku | Runtime OK | Оставить Haiku |
| QA | Sonnet | Sonnet | skill `qa` = Sonnet | OK | Оставить Sonnet |
| Business-Architect | Opus | Opus | отдельного skill не видно | OK | Оставить Opus |

## Спорные роли

### Director

Факт:
- `model-map.md` и `team-overview.md`: Sonnet.
- `agents/director.md`: Opus.

Оценка:
- Если Director только маршрутизирует задачу, Sonnet достаточно.
- Если Director ведёт архитектурный аудит, держит всю систему, оценивает стратегию Codex + Claude Code и принимает структуру проверки, может быть оправдана более сильная модель сессии.

Решение для аудита:
- Не считать это runtime-ошибкой автоматически.
- Зафиксировать как **политический рассинхрон**: нужно решить, Director всегда Sonnet или “Sonnet базово, Opus на архитектурных аудитах”.

### Marketer

Факт:
- `model-map.md` и `team-overview.md`: Opus.
- `agents/marketer.md`: Sonnet.
- `.claude/skills/marketer/SKILL.md`: Opus.

Оценка:
- Стратегия каналов, кампаний, позиционирования и запусков с долгосрочными последствиями оправдывает Opus.
- Текущие тексты, рубрики, посты и регулярное ведение уже закрываются Sonnet-агентами: Content, Copywriter, SMM-Manager.

Решение для аудита:
- Целевой Marketer как руководитель стратегии = Opus.
- Заголовок `agents/marketer.md` рассинхронизировать после подтверждения.

### Systems

Факт:
- `model-map.md` и `team-overview.md`: Opus.
- `agents/systems.md`: Sonnet.
- `.claude/skills/systems/SKILL.md`: Opus.

Оценка:
- Архитектура бота, CRM, Supabase, API, интеграций = высокая цена ошибки, Opus оправдан.
- Точечная реализация по готовому `BACKEND-PLAN.md`, ограниченные исправления и repo-проверки можно делать в Codex или Sonnet.

Решение для аудита:
- Systems-архитектура = Opus.
- Systems-реализация по готовому плану = Codex/Sonnet допустимы.
- Заголовок `agents/systems.md` рассинхронизировать после подтверждения.

### AI Builder

Факт:
- `model-map.md` и `team-overview.md`: Opus.
- `agents/ai-builder.md`: Sonnet.
- `.claude/skills/ai-builder/SKILL.md`: Opus.

Оценка:
- Сборка AI-продукта под клиента, сценарии, база знаний, системный промпт и продуктовая логика = Opus.
- Обновление базы знаний, правки формулировок, обслуживание уже заданной схемы = Sonnet/Codex допустимы.

Решение для аудита:
- AI Builder на старте продукта = Opus.
- Обслуживание по готовой схеме = дешевле.
- Заголовок `agents/ai-builder.md` рассинхронизировать после подтверждения.

## Как использовать Codex в этом аудите

Codex в этом проекте не заменяет Claude Code runtime. Его роль в model-runtime аудите:

1. Сверить файлы фактами:
   - `model-map.md`;
   - `team-overview.md`;
   - `agents/*.md`;
   - `.claude/agents/*.md`;
   - `.claude/skills/*/SKILL.md`.
2. Найти рассинхроны.
3. Разделить рассинхроны на runtime-критичные и документационные.
4. Подготовить точечные правки после решения Инны.
5. Не менять модели в агент-файлах механически без согласования.

## Что проверять в Claude Code

Claude Code нужен там, где важна фактическая механика:

- реально ли `git-manager` и `deployer-beget` вызываются как Haiku subagents;
- реально ли skills подхватывают `model:` из frontmatter;
- не запускаются ли рутинные skills на модели текущей дорогой сессии;
- как Director вызывает Agent tool и передаёт контекст.

## Предварительный вердикт

Аудит можно продолжать, но с поправкой:

- не спорить “таблица против agent-файла”;
- сначала признать, что `model-map/team-overview` - это целевая карта;
- `.claude/skills` и `.claude/agents` - runtime-слой Claude Code;
- `agents/*.md` - контекст-слой, где модель часто справочная;
- Codex - отдельная рабочая среда для repo-аудита и правок.

Критичных runtime-проблем прямо сейчас видно мало: основные runtime-слои Claude Code для skills/subagents выглядят согласованными. Главный долг - синхронизировать 4 спорных `agents/*.md` после решения по политике моделей.

