-- Отдельное поле тегов дневника (чтобы не смешивать с текстом/markdown)
ALTER TABLE diary_entries ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
