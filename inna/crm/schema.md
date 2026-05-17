# Schema — CRM «Моя база клиентов»

Дата: 2026-05-17  
Статус: MVP-схема для первого подключения `karta-rosta.html`

## Главный принцип

В MVP CRM хранит не “всё про клиента”, а минимум для follow-up:

- кто пришёл;
- откуда пришёл;
- что ответил в квизе;
- какой первичный разбор получил;
- какой платный формат заинтересовал;
- что Инне делать дальше.

CRM — источник правды. Telegram/VK/WhatsApp/MAX/email/телефон — это каналы уведомления и общения, но не место хранения заявки.

## Таблица `leads`

| Поле | Тип | Обязательное | Для чего |
|---|---|---:|---|
| `id` | uuid/string | да | Уникальный ID лида |
| `created_at` | datetime | да | Когда пришёл |
| `updated_at` | datetime | да | Когда менялся статус |
| `source` | string | да | Источник: `karta-rosta`, `visitka`, `manual`, `vk`, `tg` |
| `status` | enum | да | Текущий статус обработки |
| `name` | string | да | Имя |
| `channel` | enum | да | `telegram`, `whatsapp`, `vk`, `email`, `phone`, `other` |
| `contact` | string | да | Ник, телефон, email или ссылка |
| `context_note` | string | нет | Что человек сам написал “на повестке” |
| `main_growth_point` | string | нет | Главная точка по карте |
| `interested_offer_format` | enum | нет | `express`, `standard`, `deep`, `unknown` |
| `notification_channel` | enum | нет | Куда отправлять уведомление: `telegram`, `vk`, `whatsapp`, `max`, `email`, `phone`, `other`, `none` |
| `notification_status` | enum | нет | `pending`, `sent`, `failed`, `manual` |
| `consent_given_at` | datetime | да для публичных форм | Когда пользователь дал согласие |
| `consent_text_version` | string | да для публичных форм | Версия текста согласия |
| `niche` | string | нет | Ниша из Q1 |
| `business_age` | string | нет | Сколько лет бизнесу |
| `team_size` | string | нет | Размер команды |
| `workload` | string | нет | Личная нагрузка |
| `main_pains` | json/text | нет | Ответы Q5-Q7 |
| `automation_now` | json/text | нет | Что уже автоматизировано |
| `ai_experience` | string | нет | Опыт с AI |
| `ai_blockers` | json/text | нет | Что мешает внедрить |
| `result_summary` | text/json | нет | Сформированная карта точек роста |
| `next_step` | string | нет | Что предложить дальше |
| `followup_owner` | string | нет | Кто отвечает за контакт |
| `followup_due_at` | datetime | нет | Когда связаться |
| `notes` | text | нет | Ручные заметки Инны |

## Статусы

| Статус | Значение | Кто ставит |
|---|---|---|
| `new` | Лид пришёл, ещё не обработан | API |
| `needs-review` | Нужен ручной просмотр Инны | API / Инна |
| `contacted` | Инна написала человеку | Инна |
| `qualified` | Понятно, что это наш потенциальный клиент | Инна / Sales |
| `not-fit` | Не наш клиент сейчас | Инна / Sales |
| `audit-offered` | Предложен платный AI-аудит | Инна / Sales |
| `audit-paid` | Клиент оплатил аудит | Sales / Financial |
| `in-work` | Передан в работу | Director |
| `closed` | Завершён / отказ / отложен | Инна / Sales |

## Источники

| Source | Что означает |
|---|---|
| `karta-rosta` | Квиз «Карта точек роста» |
| `visitka` | Визитка Инны |
| `manual` | Ручное добавление |
| `vk` | VK личная страница / группа |
| `tg` | Telegram |
| `max` | MAX |
| `referral` | Рекомендация |

## Минимальный вид карточки лида

```text
Имя + контакт
Статус
Источник
Предпочтительный канал
Главные боли
Карта точек роста
Интересующий формат аудита
Следующий шаг
Заметки
```

## Следующий шаг по умолчанию

Если лид пришёл из `karta-rosta`, по умолчанию:

`next_step = "Написать вручную, уточнить контекст, предложить платный AI-аудит при совпадении с профилем клиента"`
