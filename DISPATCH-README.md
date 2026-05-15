# DISPATCH-README — куда идти по типу задачи

Дата обновления: 2026-05-15

Этот файл отвечает на вопрос: **какой документ читать и какого агента подключать, когда приходит задача**.

Главные источники:
- правила агента — [CLAUDE.md](CLAUDE.md);
- актуальный фокус — [PLAN.md](PLAN.md);
- роль Директора — [agents/director.md](agents/director.md);
- таблица маршрутизации — [agents/routing-table.md](agents/routing-table.md);
- карта команды — [knowledge/tools/team-overview.md](knowledge/tools/team-overview.md).
- регламент живой документации — [DOCS-MAINTENANCE.md](DOCS-MAINTENANCE.md).

## Базовый протокол Директора

1. Определи тип задачи.
2. Определи контур: весь бизнес / Инна / Ирина / клиент / инфраструктура / обучение.
3. Найди ближайший источник правды.
4. Если задача про клиента — прочитай `clients/<name>/PLAN.md`, `brief.md`, `FILES.md`.
5. Если задача про Инну или Ирину — иди в соответствующую папку направления и ближайший `PLAN.md`/`FILES.md`.
6. Подключи нужный департамент.
7. После результата обнови `project-log.md` или соответствующий журнал.
8. Если изменились файлы — коммит и пуш после завершения логической единицы.

## По контуру работы

| Контур | Сначала читать | Дальше |
|---|---|---|
| Весь бизнес / операционная система | [PLAN.md](PLAN.md), [FILES.md](FILES.md), [DISPATCH-README.md](DISPATCH-README.md) | Director + Planner + Business-Architect |
| Инна как владелец и эксперт | `inna/` + ближайший `PLAN.md`/`FILES.md` | Marketer / Product Builder / Websites / Systems по задаче |
| Ирина как партнёр | `irina/`, `clients/irina/` + ближайший `PLAN.md`/`FILES.md` | Branding + Brandbook Creator + Websites + Content |
| Конкретный клиент | `clients/<name>/PLAN.md`, `brief.md`, `FILES.md` | Нужный департамент по типу deliverable |
| Инфраструктура / серверы / Beget / деплой | [FILES.md](FILES.md), `deploy/`, профиль проекта | DevOps/Infra + Deployer-Beget + Git Manager |
| Каналы / VK / Telegram / сайт | папка владельца канала: `inna/`, `irina/` или `clients/<name>/` | Marketer + SMM-Manager + Websites/Systems |
| Обучение / методика / входящие знания | `inbox20/`, `transcripts/`, `knowledge/learnings/` | Librarian + Analytics-Head |

## По типу задачи

| Если задача про... | Сначала читать | Департамент / агент |
|---|---|---|
| Текущий фокус проекта | [PLAN.md](PLAN.md) | Director + Planner |
| Личная бизнес-архитектура Инны | `inna/`, [PLAN.md](PLAN.md) | Director + Business-Architect + нужный департамент |
| Задачи Ирины | `irina/`, `clients/irina/` | Branding + Brandbook Creator + нужный департамент |
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
| Код / баг / деплой / API / техническая архитектура | [knowledge/methodology/superpowers-integration.md](knowledge/methodology/superpowers-integration.md), ближайший `PLAN.md`/`brief.md` | `/superpowers` + нужный технический агент |
| Сервер / Beget / инфраструктура проекта | `deploy/`, профиль проекта, [FILES.md](FILES.md) | DevOps/Infra + Deployer-Beget |
| VK / Telegram / сайт Инны | `inna/` + ближайший `PLAN.md`/`FILES.md` | Marketer + SMM-Manager + Websites/Systems |
| VK / Telegram / сайт клиента | `clients/<name>/PLAN.md`, `brief.md`, `FILES.md` | Marketer + SMM-Manager + Websites/Systems |
| Партнёрство / продажа / процент | клиентский `PLAN.md`, `project-log.md` | Sales + Financial + Yuridika |
| Юридика, договор, персональные данные | `knowledge/`, клиентский контекст | Yuridika + Contract-Lawyer / PD-Lawyer |
| Обучение / материал Димы / чужая методика | `transcripts/`, `knowledge/learnings/` | Librarian + Analytics-Head |
| Идея Инны | `ideas/` | Director + Librarian |
| Обработка входящих | `inbox-inna/`, `inbox20/` | Director + Librarian |
| Коммит / пуш | `git status`, `git diff` | Git Manager |
| Деплой | deploy scripts, `DEPLOYMENT.md` | Deployer-Beget + DevOps/Infra |
| Архитектура документации / хаос в файлах | [PLAN.md](PLAN.md), [FILES.md](FILES.md), [DOCS-MAINTENANCE.md](DOCS-MAINTENANCE.md) | Director + Librarian + Project-Manager |

## Иерархия планов

Планы не равны друг другу.

1. [PLAN.md](PLAN.md) — что сейчас важно на уровне всего проекта.
2. Ближайший `PLAN.md` внутри `inna/`, `irina/` или другой рабочей зоны — тактика направления.
3. `clients/<name>/PLAN.md` — тактика конкретного клиента.
4. [PLAN-legacy-2026-05-08.md](PLAN-legacy-2026-05-08.md) — исторический, не использовать как текущий план.

Если планы конфликтуют:
- по клиенту побеждает `clients/<name>/PLAN.md`;
- по направлению Инны/Ирины побеждает ближайший локальный `PLAN.md`;
- по всему проекту побеждает `PLAN.md`;
- по правилам работы побеждает `CLAUDE.md`.

## Как агент узнаёт, где искать

Для каждого запроса:
- если есть имя клиента — идти в `clients/<name>/FILES.md`;
- если есть тип задачи — свериться с таблицей выше;
- если задача про знания/обучение — идти через Librarian;
- если задача про продуктовую архитектуру — подключать Business-Architect;
- если задача инженерная (код, баг, деплой, API, бот, Mini App, AI-консультант) — включить `/superpowers` по [superpowers-integration.md](knowledge/methodology/superpowers-integration.md);
- если задача повторяется второй раз — создавать/обновлять справочник в `knowledge/`;
- если задача повторяется 3+ раза — предлагать апгрейд архитектуры: скилл, агент или автоматизацию.

## Что НЕ делает этот файл

- Не хранит сами знания.
- Не заменяет `CLAUDE.md`.
- Не заменяет клиентские `PLAN.md`.
- Не является журналом задач.
