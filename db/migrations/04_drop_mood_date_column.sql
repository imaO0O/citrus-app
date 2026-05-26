-- Удаляем колонку date из mood_entries, так как recorded_at уже содержит полную информацию о дате и времени

-- Сначала обновим запросы фильтрации в бэкенде чтобы использовать DATE(recorded_at) вместо date
ALTER TABLE mood_entries DROP COLUMN IF EXISTS date;

-- Обновляем индекс для использования recorded_at вместо date
DROP INDEX IF EXISTS idx_mood_entries_user_date;
CREATE INDEX IF NOT EXISTS idx_mood_entries_user_recorded_at ON mood_entries(user_id, recorded_at DESC);
