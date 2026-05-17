-- Добавляем поля аватара и телефона в таблицу пользователей
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone text;
