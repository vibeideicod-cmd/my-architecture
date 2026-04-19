-- ============================================================
-- МГ-платформа — Миграция 212: блок «Программа» в конструкторе
-- Этап 5C:
-- Мастер ведёт программу своей МГ прямо на странице — это
-- подробный текст (список занятий, темы, что на каждой встрече).
-- Заполняется черновиком, редактируется в любой момент.
-- ============================================================

-- Расширяем check для блоков: добавляем 'program'
alter table mg_config_questions
  drop constraint if exists mg_config_questions_block_check;

alter table mg_config_questions
  add constraint mg_config_questions_block_check
    check (block in ('hero','about','offer','cta','program'));

-- Вопрос блока program
insert into mg_config_questions (block, order_idx, code, label, hint, example, required, type, max_length, options) values
  ('program', 1, 'program_content',
    'Программа твоей мастер-группы',
    'Подробно: из чего состоит твоя МГ, что на каждой встрече, какие темы. Это черновик — редактируй по ходу, после каждой публикации кандидаты видят актуальную версию.',
    E'Неделя 1 — Погружение: разбор текущего состояния\nНеделя 2 — Практика: техника дыхания\nНеделя 3 — Работа с телом\nНеделя 4 — Интеграция результатов',
    true, 'textarea', 2000, null)
on conflict (code) do update set
  label = excluded.label,
  hint = excluded.hint,
  example = excluded.example,
  required = excluded.required,
  type = excluded.type,
  max_length = excluded.max_length,
  options = excluded.options,
  block = excluded.block,
  order_idx = excluded.order_idx;
