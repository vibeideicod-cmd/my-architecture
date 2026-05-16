# FILES — карта папки knowledge/

Дата обновления: 2026-05-16

База знаний агентства: методология, стандарты, инструменты, бренд, обучения.

## Корневой файл

| Файл | Статус | Для чего |
|---|---|---|
| [README.md](README.md) | активный | Описание базы знаний |

## Основные разделы

| Раздел | Статус | Что внутри |
|---|---|---|
| [methodology/](methodology/) | ⭐ источник правды | Методологии: stage 0-6 системы СССР, audio-pipeline, deploy-stages, discovery-signals, research-standard, strategic-standard, tov-anti-patterns, instagram-stories, architecture-building, video-transcripts, audit-params, **superpowers-integration** (15.05), **superpowers-skill-audit** (15.05), director-drift-log |
| [tools/](tools/) | ⭐ источник правды | Инструменты команды: team-overview (31 агент), model-map, skills-catalog |
| [playbooks/](playbooks/) | ⭐ источник правды | Универсальные плейбуки: product-creation (6 фаз), content-marketing |
| [prompting/](prompting/) | ⭐ источник правды | Промптинг: craft-formula, critique-techniques, examples, mistakes, power-ups, templates-backend / templates-landing / templates-mini-app, lesson-log, techniques |
| [standards/](standards/) | ⭐ источник правды | Стандарты: design-system, content-plan, content-voice |
| [brand/](brand/) | ⭐ источник правды | Бренд Инны: brandbook, palette (8 цветов, психология, нумерология) |
| [clients/](clients/) | активный | Клиентские типы и шаблоны: client-types, intake-questions, typical-problems, ai-solutions + подпапка mastergroup |
| [market/](market/) | активный | Маркет-ресёрч: research, research-v2-funnel-tools (09.05) |
| [templates/](templates/) | активный | Шаблоны документов |
| [learnings/](learnings/) | активный + 📦 архив | База обучений (107MB из-за PDF в `sources/`). Структура: ai-assistant-workflow, portfolio-packaging, prompting, klient-privlechenie, content, vibe-coding + _meta |

## Что использовать дальше

**Для методологии работы с клиентом:** `methodology/stage-0.md` … `stage-6.md` (полный цикл СССР).

**Для нового цифрового продукта:** `playbooks/product-creation.md` (6 фаз: Discovery → Research → Critique → Plan → Build → QA+Deploy).

**Для инженерной задачи:** `methodology/superpowers-integration.md` (методология) + соответствующий шаблон в `prompting/templates-*.md`.

**Для понимания команды:** `tools/team-overview.md` (31 агент) + `tools/model-map.md` (Haiku/Sonnet/Opus) + `tools/skills-catalog.md` (32 скилла).

**Для бренда Инны:** `brand/palette.md` (источник правды по палитре, приоритет над CLAUDE.md).

**Для обучений:** `learnings/` (summary-файлы активны, PDF в `sources/` — архив источников, не трогать без задачи).

## Тяжёлые файлы

Раздел `learnings/` содержит около 107MB, в основном PDF-источники в подпапках `sources/`. Это нормально — это библиотека первоисточников обучений. Не коммитить новые PDF без необходимости.

## Правило обновления

База знаний обновляется через два сценария:
1. **2-й раз повторился вопрос** → создать справочник в `knowledge/<тип>/<тема>.md` (правило из `CLAUDE.md`).
2. **Урок из обучения** → разложить через протокол inbox в `learnings/`.

Владелец зоны — Librarian (см. `RESPONSIBILITY-MATRIX.md`).
