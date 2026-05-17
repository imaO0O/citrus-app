-- Добавить поля source и tags в articles
ALTER TABLE articles ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'app';
ALTER TABLE articles ADD COLUMN IF NOT EXISTS tags TEXT[];
