-- Добавить колонку is_favorite в memory_photos (для существующих БД)
ALTER TABLE memory_photos ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;
