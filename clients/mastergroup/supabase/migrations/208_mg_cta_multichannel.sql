-- ============================================================
-- МГ-платформа — Миграция 208: мульти-канальная связь
-- Переход с модели "один канал на выбор" (cta_choice) на
-- "несколько каналов одновременно" (cta_multi).
-- Мастер заполняет те каналы, где реально работает —
-- Telegram / WhatsApp / Телефон / VK / MAX.
-- ============================================================

-- 1. Расширяем check constraint type в справочнике вопросов
alter table mg_config_questions
  drop constraint if exists mg_config_questions_type_check;

alter table mg_config_questions
  add constraint mg_config_questions_type_check
    check (type in ('text','textarea','url','select','list','cta_choice','cta_multi','file'));

-- 2. Обновляем вопрос блока cta — новый тип и новые options
update mg_config_questions
set
  type = 'cta_multi',
  label = 'Куда клиенту с тобой связаться?',
  hint = 'Заполни те каналы, где ты реально на связи. На публичной странице появятся кнопки только для заполненных. Минимум один канал обязателен.',
  example = 'Telegram: @alisa_guitar',
  options = '[
    {"value":"telegram","label":"Telegram","placeholder":"@username или ссылка t.me/…","brand_color":"#229ED9"},
    {"value":"whatsapp","label":"WhatsApp","placeholder":"+7 999 123 4567","brand_color":"#25D366"},
    {"value":"phone","label":"Телефон (звонок)","placeholder":"+7 999 123 4567","brand_color":"#4B7850"},
    {"value":"vk","label":"ВКонтакте","placeholder":"https://vk.com/username","brand_color":"#0077FF"},
    {"value":"max","label":"MAX","placeholder":"Ссылка на профиль в MAX","brand_color":"#F15A29"}
  ]'::jsonb
where code = 'cta_choice';

-- 3. Комментарий для справочника
comment on column mg_config_questions.type is
  'text | textarea | url | select | list | cta_choice (legacy, один канал) | cta_multi (новый, набор каналов)';
