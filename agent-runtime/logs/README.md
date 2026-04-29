# agent-runtime/logs — логи агентов

Короткие логи работы агентов для отладки.

## Формат лога

```
[2026-04-29 10:00] analytics-head: старт — анализ конкурентов VK
[2026-04-29 10:02] analytics-head: собрано 5 конкурентов
[2026-04-29 10:05] analytics-head: готово → agent-runtime/shared/2026-04-29-analytics-competitors.md
```

## Именование

```
<агент>.log
```

Примеры: `analytics-head.log`, `marketer.log`, `content.log`

## Важно

Папка в `.gitignore` — логи не попадают в git.
