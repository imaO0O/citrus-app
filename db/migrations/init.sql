-- Таблица тем оформления (создаётся первой, т.к. users ссылается на неё)
CREATE TABLE IF NOT EXISTS themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_dark BOOLEAN DEFAULT FALSE,
    primary_color TEXT DEFAULT '#2196F3',
    accent_color TEXT DEFAULT '#FF9800',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    theme_id UUID DEFAULT gen_random_uuid(),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (theme_id) REFERENCES themes(id) ON DELETE SET DEFAULT
);

-- Добавляем стандартные темы
INSERT INTO themes (id, name, is_dark, primary_color, accent_color) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Светлая', FALSE, '#2196F3', '#FF9800'),
    ('00000000-0000-0000-0000-000000000002', 'Тёмная', TRUE, '#90CAF9', '#FFB74D')
ON CONFLICT (id) DO NOTHING;

-- Отметки настроения ("дольки")
CREATE TABLE IF NOT EXISTS mood_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mood_value INTEGER CHECK (mood_value BETWEEN 0 AND 5),
    recorded_at TIMESTAMP DEFAULT NOW(),
    date DATE DEFAULT CURRENT_DATE,
    time_of_day TEXT  -- 'morning', 'afternoon', 'evening'
);

-- Записи дневника
CREATE TABLE IF NOT EXISTS diary_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    mood_value INTEGER,
    entry_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- События календаря
CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT,
    description TEXT,
    event_date DATE,
    start_time TIME,
    end_time TIME,
    notification_enabled BOOLEAN DEFAULT TRUE
);

-- Статьи (системные и пользовательские)
CREATE TABLE IF NOT EXISTS articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,  -- NULL для системных
    title TEXT,
    content TEXT,
    category TEXT,
    is_custom BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Фото дофаминовой галереи
CREATE TABLE IF NOT EXISTS memory_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT,
    caption TEXT,
    photo_date DATE,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Записи трекера сна
CREATE TABLE IF NOT EXISTS sleep_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    sleep_date DATE,
    bed_time TIME,
    wake_time TIME,
    quality INTEGER CHECK (quality BETWEEN 1 AND 5)
);

-- Настройки пользователя (JSON)
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    preferences JSONB,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Индексы для ускорения запросов
CREATE INDEX IF NOT EXISTS idx_mood_entries_user_date ON mood_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_diary_entries_user_date ON diary_entries(user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date ON calendar_events(user_id, event_date);
