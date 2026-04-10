-- Исправить constraint mood_value чтобы принимать 0-5 (было 1-5)
ALTER TABLE mood_entries DROP CONSTRAINT IF EXISTS mood_entries_mood_value_check;
ALTER TABLE mood_entries ADD CONSTRAINT mood_entries_mood_value_check CHECK (mood_value BETWEEN 0 AND 5);
