-- Премодерация публичных статей сообщества.
-- moderation_status: 'private' (по умолчанию, видна только автору и системе),
--                    'pending' (отправлена на модерацию), 'approved', 'rejected'.
ALTER TABLE articles ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT FALSE;
ALTER TABLE articles ADD COLUMN IF NOT EXISTS moderation_status TEXT DEFAULT 'private';

-- Быстрый поиск статей, ожидающих модерации / одобренных публичных.
CREATE INDEX IF NOT EXISTS idx_articles_moderation
  ON articles (moderation_status)
  WHERE is_public = TRUE;
