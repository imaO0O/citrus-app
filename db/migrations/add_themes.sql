-- Добавляем стандартные темы (если их нет)
INSERT INTO themes (id, name, is_dark, primary_color, accent_color) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Светлая', FALSE, '#2196F3', '#FF9800'),
    ('00000000-0000-0000-0000-000000000002', 'Тёмная', TRUE, '#90CAF9', '#FFB74D'),
ON CONFLICT (id) DO NOTHING;

-- Добавляем theme_id в users если не существует
ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_id UUID DEFAULT '00000000-0000-0000-0000-000000000001';

-- Добавляем внешний ключ если не существует
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_users_theme' AND table_name = 'users'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT fk_users_theme 
        FOREIGN KEY (theme_id) REFERENCES themes(id) ON DELETE SET DEFAULT;
    END IF;
END $$;

-- Проверяем результат
SELECT * FROM themes;
SELECT id, email, name, theme_id FROM users;
