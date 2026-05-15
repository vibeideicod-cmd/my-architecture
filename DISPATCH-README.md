# DISPATCH-README — куда идти по типу задачи

Дата обновления: 2026-05-15

Этот файл отвечает на вопрос: **какой документ читать и какого агента подключать, когда приходит задача**.

Главные источники:
- правила агента — [CLAUDE.md](CLAUDE.md);
- роль Директора — [agents/director.md](agents/director.md);
- таблица маршрутизации — [agents/routing-table.md](agents/routing-table.md);
- карта команды — [knowledge/tools/team-overview.md](knowledge/tools/team-overview.md).

## Базовый протокол Директора

1. Определи тип задачи.
2. Найди ближайший источник правды.
3. Если задача про клиента — прочитай `clients/<name>/PLAN.md`, `brief.md`, `FILES.md`.
4. Подключи нужный департамент.
5. После результата обнови `project-log.md` или соответствующий журнал.
6. Если изменились файлы — коммит и пуш после завершения логической единицы.

## По типу задачи

| Если задача про... | Сначала читать | Департамент / агент |
|---|---|---|
| Текущий фокус проекта | [CURRENT.md](CURRENT.md) | Director + Planner |
| Правила работы, ограничения, git, память | [CLAUDE.md](CLAUDE.md) | Director |
| Куда идти по файлам | [FILES.md](FILES.md) | Director + Librarian |
| Состав команды агентов | [knowledge/tools/team-overview.md](knowledge/tools/team-overview.md) | Director |
| Модели агентов | [knowledge/tools/model-map.md](knowledge/tools/model-map.md) | Director + Skill-Auditor |
| Новый клиент | `clients/_template/`, [agents/director.md](agents/director.md) | Director + Product Builder + Analyst |
| Существующий клиент | `clients/<name>/PLAN.md`, `FILES.md`, `brief.md` | Director + нужный департамент |
| Клиентский текст / выступление / оффер | клиентский `brief.md`, финальные материалы | Copywriter + Content + QA |
| Презентация / визуальная упаковка | клиентский `brief.md`, `FILES.md`, дизайн-ТЗ | Branding + Brandbook Creator + Ирина |
| Лендинг / сайт / страница | клиентский `PLAN.md`, `brief.md` | Product Builder + Websites + QA |
| Бот / CRM / автоматизация | клиентский `PLAN.md`, техбриф | Systems + AI Builder + QA |
| Партнёрство / продажа / процент | клиентский `PLAN.md`, `project-log.md` | Sales + Financial + Yuridika |
| Юридика, договор, персональные данные | `knowledge/`, клиентский контекст | Yuridika + Contract-Lawyer / PD-Lawyer |
| Обучение / материал Димы / чужая методика | `transcripts/`, `knowledge/learnings/` | Librarian + Analytics-Head |
| Идея Инны | `ideas/` | Director + Librarian |
| Обработка входящих | `inbox-inna/`, `inbox20/` | Director + Librarian |
| Коммит / пуш | `git status`, `git diff` | Git Manager |
| Деплой | deploy scripts, `DEPLOYMENT.md` | Deployer-Beget + DevOps/Infra |

## Иерархия планов

Планы не равны друг другу.

1. [CURRENT.md](CURRENT.md) — что сейчас важно на уровне всего проекта.
2. `inna/PLAN.md`, `irina/PLAN.md` — тактика направлений.
3. `clients/<name>/PLAN.md` — тактика конкретного клиента.
4. Старый корневой [PLAN.md](PLAN.md) — исторический, не использовать как текущий план.

Если планы конфликтуют:
- по клиенту побеждает `clients/<name>/PLAN.md`;
- по всему проекту побеждает `CURRENT.md`;
- по правилам работы побеждает `CLAUDE.md`.

## Как агент узнаёт, где искать

Для каждого запроса:
- если есть имя клиента — идти в `clients/<name>/FILES.md`;
- если есть тип задачи — свериться с таблицей выше;
- если задача про знания/обучение — идти через Librarian;
- если задача про продуктовую архитектуру — подключать Business-Architect;
- если задача повторяется второй раз — создавать/обновлять справочник в `knowledge/`;
- если задача повторяется 3+ раза — предлагать апгрейд архитектуры: скилл, агент или автоматизацию.

## Что НЕ делает этот файл

- Не хранит сами знания.
- Не заменяет `CLAUDE.md`.
- Не заменяет клиентские `PLAN.md`.
- Не является журналом задач.
