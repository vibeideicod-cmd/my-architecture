-- ============================================================
-- Beauty TMA — Миграция 005: Функция get_available_slots
-- Назначение: вернуть свободные слоты записи на конкретную дату
-- для конкретного мастера, не открывая клиенту доступ к таблице
-- bookings (там лежат имена и телефоны других клиенток —
-- приватные данные, чтение через anon key запрещено в 002).
--
-- Решение: PostgreSQL-функция с SECURITY DEFINER. Выполняется
-- с правами создателя (суперпользователь postgres), читает
-- schedules + bookings внутри БД, отдаёт наружу ТОЛЬКО массив
-- свободных времён в формате 'HH:MI'. Никакие данные клиенток
-- не утекают — функция возвращает только строки времени.
--
-- Логика:
--   1. По дате определяем день недели (PostgreSQL: 0=Вс…6=Сб → наш: 1=Пн…7=Вс)
--   2. Достаём расписание мастера на этот день
--   3. Если выходной или нет расписания — пустой массив
--   4. Генерим слоты от start_time до end_time с шагом slot_duration
--   5. Выкидываем прошедшие (slot_ts > now())
--   6. Выкидываем пересекающиеся с уже подтверждёнными бронями
--      (стандартный тест пересечения интервалов: A.start < B.end И A.end > B.start)
--   7. Возвращаем массив строк 'HH:MI' в локальном часовом поясе мастера
--
-- Часовой пояс: дефолт 'Europe/Moscow' (Анна в Москве). Параметр
-- p_tz позволяет переопределить для будущих мастеров из других
-- городов без изменения функции.
-- ============================================================

create or replace function get_available_slots(
  p_master_id text,
  p_date      date,
  p_tz        text default 'Europe/Moscow'
)
returns text[]
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dow      int;
  v_schedule schedules%rowtype;
  v_result   text[];
begin
  -- PostgreSQL extract(dow): 0=воскресенье … 6=суббота
  -- Наша схема: 1=понедельник … 7=воскресенье
  v_dow := case extract(dow from p_date)::int
             when 0 then 7
             else extract(dow from p_date)::int
           end;

  -- Достаём расписание мастера на этот день недели
  select * into v_schedule
  from schedules
  where master_id = p_master_id
    and day_of_week = v_dow;

  -- Нет записи в расписании или это выходной — слотов нет
  if not found or not v_schedule.is_working then
    return array[]::text[];
  end if;

  -- Генерим, фильтруем, форматируем
  select array_agg(slot_label order by slot_ts)
    into v_result
  from (
    select
      to_char(slot_ts at time zone p_tz, 'HH24:MI') as slot_label,
      slot_ts
    from (
      -- Базовый момент дня в локальном поясе мастера, конвертим в UTC timestamptz
      select
        ((p_date + v_schedule.start_time)::timestamp at time zone p_tz)
          + (n * (v_schedule.slot_duration || ' minutes')::interval) as slot_ts
      from generate_series(
        0,
        (extract(epoch from (v_schedule.end_time - v_schedule.start_time))
          / 60 / v_schedule.slot_duration - 1)::int
      ) n
    ) raw
    where
      -- Не отдаём прошедшие слоты
      slot_ts > now()
      -- Не отдаём пересекающиеся с подтверждёнными бронями
      -- (стандартный тест пересечения интервалов)
      and not exists (
        select 1 from bookings b
        where b.master_id = p_master_id
          and b.status = 'confirmed'
          and b.scheduled_at < (slot_ts + (v_schedule.slot_duration || ' minutes')::interval)
          and (b.scheduled_at + (b.duration_min || ' minutes')::interval) > slot_ts
      )
  ) filtered;

  -- Если ни одного слота не осталось — array_agg даст null, возвращаем пустой массив
  return coalesce(v_result, array[]::text[]);
end;
$$;

-- ── Доступ ────────────────────────────────────────────────
-- Функцию можно вызывать анонимно (через anon key) и
-- авторизованно. Никаких других ролей не нужно.
revoke all on function get_available_slots(text, date, text) from public;
grant execute on function get_available_slots(text, date, text) to anon, authenticated;

-- ── Smoke-test (запусти руками в SQL Editor для проверки) ─
-- select get_available_slots('anna', current_date + 1);
-- → должен вернуть ['10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00']
--   (если завтра — рабочий день Анны)
