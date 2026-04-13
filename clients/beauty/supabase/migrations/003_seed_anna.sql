-- ============================================================
-- Beauty TMA — Миграция 003: Стартовые данные (Анна Смирнова)
-- Кладём в базу ту же Анну Смирнову, что сейчас в js/data.js,
-- чтобы после подключения Supabase в TMA визуально ничего не менялось.
-- ============================================================

-- ── Мастер ───────────────────────────────────────────────
insert into masters (id, name, specialty, city, bio, accent_color, status_text)
values (
  'anna',
  'Анна Смирнова',
  'Бьюти-мастер',
  'Москва',
  'Работаю с гель-лаком, акрилом и дизайном. Принимаю на Арбате.',
  '#b49fd4',
  'Принимаю записи на май 🌸'
)
on conflict (id) do nothing;

-- ── Категории ────────────────────────────────────────────
insert into categories (master_id, name, icon, position) values
  ('anna', 'Маникюр', '💅', 1),
  ('anna', 'Педикюр', '🦶', 2),
  ('anna', 'Дизайн',  '✨', 3),
  ('anna', 'Уход',    '🌿', 4);

-- ── Услуги ───────────────────────────────────────────────
-- Привязываем к категориям через подзапрос по имени
insert into services (master_id, category_id, name, description, price_from, price_exact, duration, tags, position) values
  ('anna', (select id from categories where master_id='anna' and name='Маникюр'),
   'Маникюр классический',
   'Обработка кутикулы, придание формы, покрытие по желанию. Включает массаж рук.',
   1200, true, 60, array['Гель-лак','Классика'], 1),

  ('anna', (select id from categories where master_id='anna' and name='Маникюр'),
   'Маникюр гель-лак',
   'Стойкое покрытие до 3 недель. Широкая палитра — более 200 оттенков.',
   1800, true, 90, array['Гель-лак','Стойкость'], 2),

  ('anna', (select id from categories where master_id='anna' and name='Маникюр'),
   'Комби-маникюр',
   'Аппаратная + классическая обработка. Идеально для плотной кутикулы.',
   2000, false, 75, array['Аппаратный','Комби'], 3),

  ('anna', (select id from categories where master_id='anna' and name='Маникюр'),
   'Снятие + маникюр',
   'Бережное снятие старого покрытия + полный маникюр с новым гель-лаком.',
   2200, true, 120, array['Снятие','Гель-лак'], 4),

  ('anna', (select id from categories where master_id='anna' and name='Педикюр'),
   'Педикюр классический',
   'Обработка стоп, ногтей и кутикулы. Завершается увлажняющим кремом.',
   2000, true, 90, array['Классика'], 1),

  ('anna', (select id from categories where master_id='anna' and name='Педикюр'),
   'Педикюр гель-лак',
   'Педикюр + стойкое покрытие гель-лаком. Держится до 4 недель.',
   2500, true, 110, array['Гель-лак'], 2),

  ('anna', (select id from categories where master_id='anna' and name='Педикюр'),
   'Аппаратный педикюр',
   'Аппаратная обработка — нет воды, нет порезов. Особенно эффективен при мозолях.',
   2800, false, 90, array['Аппаратный'], 3),

  ('anna', (select id from categories where master_id='anna' and name='Дизайн'),
   'Простой дизайн',
   'Французский маникюр, омбре, однотонный с декором. 1–2 пальца.',
   500, true, 30, array['Дизайн','Омбре'], 1),

  ('anna', (select id from categories where master_id='anna' and name='Дизайн'),
   'Сложный дизайн',
   'Роспись, объёмный дизайн, nail-art. Цена зависит от сложности узора.',
   800, false, 60, array['Nail-art','Роспись'], 2),

  ('anna', (select id from categories where master_id='anna' and name='Уход'),
   'SPA-маникюр',
   'Маникюр + ванночка + скраб + маска + массаж рук. Максимальное расслабление.',
   2500, true, 90, array['SPA','Уход'], 1),

  ('anna', (select id from categories where master_id='anna' and name='Уход'),
   'Укрепление ногтей',
   'Укрепление биогелем или базой. Восстанавливает ломкие и слоящиеся ногти.',
   1500, true, 60, array['Укрепление'], 2);

-- ── Расписание ───────────────────────────────────────────
-- Пн–Пт: 10:00–18:00, слот 60 мин. Сб/Вс: выходные.
insert into schedules (master_id, day_of_week, start_time, end_time, slot_duration, is_working) values
  ('anna', 1, '10:00', '18:00', 60, true),   -- Пн
  ('anna', 2, '10:00', '18:00', 60, true),   -- Вт
  ('anna', 3, '10:00', '18:00', 60, true),   -- Ср
  ('anna', 4, '10:00', '18:00', 60, true),   -- Чт
  ('anna', 5, '10:00', '18:00', 60, true),   -- Пт
  ('anna', 6, '10:00', '18:00', 60, false),  -- Сб — выходной
  ('anna', 7, '10:00', '18:00', 60, false)   -- Вс — выходной
on conflict (master_id, day_of_week) do nothing;
