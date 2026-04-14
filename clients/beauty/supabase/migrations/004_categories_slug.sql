-- ============================================================
-- 004 — Slug у категорий
-- Зачем: CSS даёт цветные градиенты карточкам категорий через
-- селектор `[data-cat="manicure"]`, поэтому нужен стабильный
-- текстовый идентификатор, а не bigserial id.
-- ============================================================

alter table categories
  add column if not exists slug text;

create unique index if not exists ux_categories_master_slug
  on categories (master_id, slug);

-- Заполняем slug для уже существующих категорий Анны
update categories set slug = 'manicure' where master_id = 'anna' and name = 'Маникюр' and slug is null;
update categories set slug = 'pedicure' where master_id = 'anna' and name = 'Педикюр' and slug is null;
update categories set slug = 'design'   where master_id = 'anna' and name = 'Дизайн'  and slug is null;
update categories set slug = 'care'     where master_id = 'anna' and name = 'Уход'    and slug is null;
