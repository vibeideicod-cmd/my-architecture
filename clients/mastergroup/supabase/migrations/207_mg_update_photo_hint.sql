-- ============================================================
-- МГ-платформа v2 — Миграция 207: обновление подсказки для фото
-- Теперь мастер загружает фото файлом, а не вставляет ссылку.
-- ============================================================

-- Добавляем 'file' в допустимые типы
alter table mg_config_questions drop constraint mg_config_questions_type_check;
alter table mg_config_questions add constraint mg_config_questions_type_check
  check (type in ('text','textarea','url','select','list','cta_choice','file'));

-- Обновляем подсказку и тип
update mg_config_questions
set
  label = 'Твоё фото',
  hint = 'Загрузи фото — JPG, PNG или WebP, до 5 МБ. Автоматически обрежется до квадрата. Можно пропустить — поставим красивый кружок с первой буквой имени.',
  example = '',
  type = 'file'
where code = 'photo_url' and block = 'hero';
