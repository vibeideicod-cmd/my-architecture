# agent-runtime/logs — логи агентов

Короткие логи работы агентов для отладки.

## Формат лога

```
[2026-04-29 10:00] analytics-rukovoditel: старт — анализ конкурентов VK
[2026-04-29 10:02] analytics-rukovoditel: собрано 5 конкурентов
[2026-04-29 10:05] analytics-rukovoditel: готово → agent-runtime/shared/2026-04-29-analytics-competitors.md
```

## Именование

```
<агент>.log
```

Примеры: `analytics-rukovoditel.log`, `marketer.log`, `content.log`

## Важно

Папка в `.gitignore` — логи не попадают в git.
