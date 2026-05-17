# API Contract — CRM MVP

Дата: 2026-05-17  
Статус: контракт между `karta-rosta.html` и будущим CRM API

## Endpoint MVP

```http
POST https://crm.ideidlyabiznesa1913.ru/api/leads
Content-Type: application/json
```

## Правило маршрута

CRM — источник правды. Канал связи (`telegram`, `vk`, `whatsapp`, `max`, `email`, `phone`) нужен для уведомления и follow-up, но не заменяет карточку лида.

Целевой маршрут:

```text
karta-rosta.html
→ POST /api/leads
→ карточка лида в CRM
→ уведомление в выбранный/доступный канал
```

## Request

```json
{
  "source": "karta-rosta",
  "name": "Александра",
  "channel": "telegram",
  "contact": "@username",
  "context_note": "Хочу понять, где теряю заявки",
  "main_growth_point": "Точка 1: заявки и первый контакт",
  "interested_offer_format": "standard",
  "notification_channel": "telegram",
  "consent_given_at": "2026-05-17T12:00:00+03:00",
  "consent_text_version": "karta-rosta-pd-2026-05-17",
  "answers": {
    "niche": "Бьюти: салон, мастер, бренд",
    "business_age": "1-3 года",
    "team_size": "1-2 человека помогают",
    "workload": "40-60",
    "time_drains": ["Ответы клиентам", "Создание контента"],
    "loss_points": ["Заявки приходят, но теряются"],
    "main_irritation": "Всё держится только на мне",
    "automation_now": ["Ничего — всё руками"],
    "ai_experience": "Использую для отдельных задач",
    "ai_blockers": ["Не понимаю, с чего начать"]
  },
  "result_summary": [
    {
      "title": "Точка 1: заявки и первый контакт",
      "text": "У вас есть риск потери заявок на этапе первого ответа."
    }
  ],
  "page_url": "https://ideidlyabiznesa1913.ru/karta-rosta.html"
}
```

## Response — success

```json
{
  "ok": true,
  "lead_id": "lead_20260517_001",
  "status": "new",
  "message": "Лид сохранён"
}
```

## Response — validation error

```json
{
  "ok": false,
  "error": "validation_error",
  "message": "Укажите контакт"
}
```

## Response — server error

```json
{
  "ok": false,
  "error": "server_error",
  "message": "CRM временно недоступна"
}
```

## Правило fallback на фронте

Если `POST /api/leads` не отвечает или возвращает ошибку:

1. Не скрывать результат квиза.
2. Показать честный текст: “CRM временно недоступна”.
3. Дать кнопку копирования краткой сводки.
4. Дать временные ручные каналы: Telegram/VK/email/другой доступный канал.

Квиз не должен создавать ложное ощущение, что контакт сохранён, если API не подтвердил сохранение.

## Минимальная валидация API

| Поле | Проверка |
|---|---|
| `source` | одно из разрешённых значений |
| `name` | не пустое, 2-80 символов |
| `channel` | `telegram`, `whatsapp`, `vk`, `max`, `email`, `phone`, `other` |
| `contact` | не пустое, 3-120 символов |
| `main_growth_point` | string, можно пусто |
| `interested_offer_format` | `express`, `standard`, `deep`, `unknown` |
| `notification_channel` | `telegram`, `whatsapp`, `vk`, `max`, `email`, `phone`, `other`, `none` |
| `consent_given_at` | ISO datetime, обязательно перед сохранением контакта |
| `consent_text_version` | версия текста согласия |
| `answers` | object |
| `result_summary` | array или string |

## CORS

На старте разрешить только:

```text
https://ideidlyabiznesa1913.ru
https://www.ideidlyabiznesa1913.ru
```

Для локальной проверки временно:

```text
http://localhost:8000
http://127.0.0.1:8000
```

Локальные origins убрать перед production.
