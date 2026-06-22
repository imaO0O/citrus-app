-- Повторяющиеся события календаря.
-- recurrence: 'none' (по умолчанию), 'daily', 'weekly', 'monthly'.
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS recurrence TEXT DEFAULT 'none';
