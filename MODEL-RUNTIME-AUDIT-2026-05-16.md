# Model Runtime Audit — агенты, модели, Codex и Claude Code

Дата: 2026-05-16  
Статус: финализирован 2026-05-17 после синхронизации `agents/*.md`

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

Главный рассинхрон был не в составе команды, а в слоях. На 2026-05-17 он закрыт через split-policy в спорных `agents/*.md`:

- `model-map.md` и `team-overview.md` держат целевую экономическую карту: **6 Opus / 23 Sonnet / 2 Haiku**.
- `.claude/skills/*/SKILL.md` в ключевых местах уже совпадают с целевой картой: `marketer`, `systems`, `ai-builder`, `product-builder` на Opus; `git-manager`, `deployer-beget`, `deploy`, `seo` на Haiku.
- `.claude/agents/` содержит 2 runtime-subagent: `git-manager` и `deployer-beget`, оба Haiku.
- `agents/*.md` в основном являются контекст-агентами. Их строка “Модель” справочная, если агент не вынесен в `.claude/agents/` или skill.
- Для Director, Marketer, Systems и AI Builder зафиксирована не одна жёсткая модель, а **экономная split-policy**: дорогая модель включается на высокую цену ошибки, Sonnet/Codex используются на операционную работу по готовому плану.

## Pass/fail перед аудитом

| Проверка | Вердикт | Комментарий |
|---|---|---|
| Понятно, сколько агентов | PASS | 31 агент: 3 вне департаментов + 28 в 11 департаментах |
| Есть целевая модельная карта | PASS | `model-map.md` и `team-overview.md` совпадают: 6/23/2 |
| Есть runtime-модели у Claude subagents | PASS | 2 subagent: git/deploy на Haiku |
| Есть runtime-модели у Claude skills | PASS | `model:` есть в skill frontmatter |
| `agents/*.md` синхронизированы с модельной картой | PASS после sync | 4 спорные роли переведены на split-policy: Director, Marketer, Systems, AI Builder |
| Понятно, как Codex учитывает модели | PASS после стратегии | Codex не переключается по Claude frontmatter, использует документы как инструкции |

## Таблица по 31 агенту

Легенда:

- **Runtime-критично** - реально влияет на модель при запуске в Claude Code.
- **Док-долг** - строка вводит в заблуждение, но сама по себе не переключает модель.
- **OK** - слои согласованы или расхождение отсутствует.
- **Решить** - нужна содержательная политика, не механическая правка.

| Агент | Цель в `model-map/team-overview` | `agents/*.md` | `.claude runtime` | Тип | Решение |
|---|---|---|---|---|---|
| Director | Sonnet | Sonnet базово + Opus на архитектурных аудитах | нет subagent/skill | Split-policy OK | Операционная маршрутизация = Sonnet. Архитектурные аудиты и долгосрочные решения могут идти на более сильной модели сессии Codex/Claude |
| Skill-Auditor | Sonnet | Sonnet | skill не найден отдельным runtime в текущем списке, есть agent-файл | OK | Оставить Sonnet |
| Librarian | Sonnet | Sonnet | нет отдельного runtime | OK | Оставить Sonnet |
| Branding | Sonnet | Sonnet | skill `branding` = Sonnet | OK | Оставить Sonnet |
| Brandbook Creator | Sonnet | Sonnet | skill `brandbook-creator` = Sonnet | OK | Оставить Sonnet |
| Marketer | Opus | Opus на стратегии + Sonnet на регулярных кампаниях | skill `marketer` = Opus | Split-policy OK | Стратегия каналов и кампаний = Opus. Оперативное руководство контентом/копирайтингом = Sonnet |
| Marketing-Strategist | Opus | Opus | отдельного skill не видно | OK | Оставить Opus для глубокой стратегии |
| Content | Sonnet | Sonnet | skill `content` = Sonnet | OK | Оставить Sonnet |
| Copywriter | Sonnet | Sonnet | skill `copywriter` = Sonnet | OK | Оставить Sonnet |
| SMM-Manager | Sonnet | Sonnet | отдельного skill не видно | OK | Оставить Sonnet |
| Sales | Sonnet | Sonnet | skill `sales` = Sonnet | OK | Оставить Sonnet |
| Product Builder | Opus | Opus | skill `product-builder` = Opus, `discovery` = Opus | OK | Оставить Opus |
| Websites | Sonnet | Sonnet | skill `websites` = Sonnet | OK | Оставить Sonnet; Codex может делать точечные правки/проверки дешевле как repo-исполнитель |
| Systems | Opus | Opus на архитектуре + Sonnet/Codex на реализации по плану | skill `systems` = Opus | Split-policy OK | Архитектура ботов/CRM/интеграций = Opus. Точечная реализация/фикс по готовому плану = Codex/Sonnet |
| AI Builder | Opus | Opus на старте AI-продукта + Sonnet/Codex на обслуживании | skill `ai-builder` = Opus | Split-policy OK | Старт AI-продукта, сценарии и архитектура = Opus. Обслуживание базы/промпта по готовой схеме = Sonnet/Codex |
| Analytics-Rukovoditel | Sonnet | Sonnet | skill `analytics-rukovoditel` = Sonnet | OK | Оставить Sonnet |
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
- `agents/director.md`: Sonnet базово + Opus на сложных архитектурных аудитах и долгосрочных решениях.

Оценка:
- Если Director только маршрутизирует задачу, Sonnet достаточно.
- Если Director ведёт архитектурный аудит, держит всю систему, оценивает стратегию Codex + Claude Code и принимает структуру проверки, может быть оправдана более сильная модель сессии.

Решение:
- Принята split-policy: Director в обычной операционной маршрутизации работает на Sonnet.
- На архитектурных аудитах, стратегических развилках и долгосрочных решениях допустимо временное повышение до Opus/сильной сессии Codex/Claude.
- Это больше не считается рассинхроном.

### Marketer

Факт:
- `model-map.md` и `team-overview.md`: Opus.
- `agents/marketer.md`: Opus на стратегии каналов, крупных кампаниях и запусках + Sonnet на регулярных кампаниях и оперативном руководстве контентом/копирайтингом.
- `.claude/skills/marketer/SKILL.md`: Opus.

Оценка:
- Стратегия каналов, кампаний, позиционирования и запусков с долгосрочными последствиями оправдывает Opus.
- Текущие тексты, рубрики, посты и регулярное ведение уже закрываются Sonnet-агентами: Content, Copywriter, SMM-Manager.

Решение:
- Целевой Marketer как руководитель стратегии = Opus.
- Текущие кампании, регулярное ведение и постановка задач Content/Copywriter/SMM = Sonnet.
- Рассинхрон закрыт в `agents/marketer.md`.

### Systems

Факт:
- `model-map.md` и `team-overview.md`: Opus.
- `agents/systems.md`: Opus на архитектуре ботов/CRM/Supabase/интеграций + Sonnet на точечной реализации по готовому `BACKEND-PLAN.md` и repo-правках.
- `.claude/skills/systems/SKILL.md`: Opus.

Оценка:
- Архитектура бота, CRM, Supabase, API, интеграций = высокая цена ошибки, Opus оправдан.
- Точечная реализация по готовому `BACKEND-PLAN.md`, ограниченные исправления и repo-проверки можно делать в Codex или Sonnet.

Решение:
- Systems-архитектура = Opus.
- Systems-реализация по готовому плану = Codex/Sonnet допустимы.
- Рассинхрон закрыт в `agents/systems.md`.

### AI Builder

Факт:
- `model-map.md` и `team-overview.md`: Opus.
- `agents/ai-builder.md`: Opus на старте AI-продукта + Sonnet на обслуживании готовой схемы и обновлении базы знаний.
- `.claude/skills/ai-builder/SKILL.md`: Opus.

Оценка:
- Сборка AI-продукта под клиента, сценарии, база знаний, системный промпт и продуктовая логика = Opus.
- Обновление базы знаний, правки формулировок, обслуживание уже заданной схемы = Sonnet/Codex допустимы.

Решение:
- AI Builder на старте продукта = Opus.
- Обслуживание по готовой схеме = Sonnet/Codex.
- Рассинхрон закрыт в `agents/ai-builder.md`.

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
4. Проверить, что точечные правки после решения Инны внесены.
5. Не менять модели в агент-файлах механически без нового согласования.

## Что проверять в Claude Code

Claude Code нужен там, где важна фактическая механика:

- реально ли `git-manager` и `deployer-beget` вызываются как Haiku subagents;
- реально ли skills подхватывают `model:` из frontmatter;
- не запускаются ли рутинные skills на модели текущей дорогой сессии;
- как Director вызывает Agent tool и передаёт контекст.

## Финальный вердикт

Model/runtime preflight закрыт:

- не спорить “таблица против agent-файла”;
- `model-map/team-overview` - это целевая экономическая карта;
- `.claude/skills` и `.claude/agents` - runtime-слой Claude Code;
- `agents/*.md` - контекст-слой, где модель часто справочная, но теперь спорные заголовки синхронизированы split-policy;
- Codex - отдельная рабочая среда для repo-аудита и правок.

Критичных runtime-проблем прямо сейчас не видно: основные runtime-слои Claude Code для skills/subagents согласованы, а 4 спорных `agents/*.md` приведены к экономной split-policy.
