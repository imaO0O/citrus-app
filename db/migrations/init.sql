-- ============================================================================
-- Citrus App - Database Initialization Script
-- ============================================================================
-- Этот файл содержит полную структуру базы данных со всеми таблицами,
-- включая все поля из миграций (002, 03, 04, 05, 06, 07, add_themes).
-- Используйте для создания БД с нуля.
-- ============================================================================

-- ============================================================================
-- 1. ТЕМЫ ОФОРМЛЕНИЯ
-- ============================================================================
CREATE TABLE IF NOT EXISTS themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_dark BOOLEAN DEFAULT FALSE,
    primary_color TEXT DEFAULT '#2196F3',
    accent_color TEXT DEFAULT '#FF9800',
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 2. ПОЛЬЗОВАТЕЛИ
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    theme_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_users_theme FOREIGN KEY (theme_id) REFERENCES themes(id) ON DELETE SET DEFAULT
);

-- ============================================================================
-- 3. ОТМЕТКИ НАСТРОЕНИЯ
-- ============================================================================
CREATE TABLE IF NOT EXISTS mood_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mood_value INTEGER,
    recorded_at TIMESTAMP DEFAULT NOW(),
    time_of_day TEXT,  -- 'morning', 'afternoon', 'evening'
    CONSTRAINT mood_entries_mood_value_check CHECK (mood_value BETWEEN 0 AND 5)
);

-- ============================================================================
-- 4. ЗАПИСИ ДНЕВНИКА
-- ============================================================================
CREATE TABLE IF NOT EXISTS diary_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    mood_value INTEGER,
    entry_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 5. СОБЫТИЯ КАЛЕНДАРЯ
-- ============================================================================
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

-- ============================================================================
-- 6. СТАТЬИ
-- ============================================================================
CREATE TABLE IF NOT EXISTS articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,  -- NULL для системных
    title TEXT,
    content TEXT,
    category TEXT,
    is_custom BOOLEAN DEFAULT FALSE,
    source TEXT DEFAULT 'app',  -- из миграции 06
    tags TEXT[],                -- из миграции 06
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 7. ФОТО ДОФАМИНОВОЙ ГАЛЕРЕИ
-- ============================================================================
CREATE TABLE IF NOT EXISTS memory_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT,
    caption TEXT,
    photo_date DATE,
    is_favorite BOOLEAN DEFAULT FALSE,  -- из миграции 002
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 8. ЗАПИСИ ТРЕКЕРА СНА
-- ============================================================================
CREATE TABLE IF NOT EXISTS sleep_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    sleep_date DATE,
    bed_time TIME,
    wake_time TIME,
    quality INTEGER,
    CONSTRAINT sleep_records_quality_check CHECK (quality BETWEEN 1 AND 5)
);

-- ============================================================================
-- 9. НАСТРОЙКИ ПОЛЬЗОВАТЕЛЯ (JSON)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    preferences JSONB,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 10. РЕЗУЛЬТАТЫ ПСИХОЛОГИЧЕСКИХ ТЕСТОВ
-- ============================================================================
CREATE TABLE IF NOT EXISTS psychological_test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    test_id TEXT NOT NULL,
    scores JSONB NOT NULL,
    interpretations JSONB,
    completed_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 11. СООБЩЕНИЯ ЧАТА С ИИ
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_message TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    response_time_ms INTEGER,    -- из миграции 07
    tokens_used INTEGER,         -- из миграции 07
    model_used TEXT,             -- из миграции 07
    mood_before INTEGER,         -- из миграции 07
    mood_after INTEGER,          -- из миграции 07
    session_id TEXT,             -- из миграции 07
    CONSTRAINT chat_messages_mood_before_check CHECK (mood_before BETWEEN 0 AND 5),
    CONSTRAINT chat_messages_mood_after_check CHECK (mood_after BETWEEN 0 AND 5)
);

-- ============================================================================
-- 12. ДОВЕРЕННЫЕ КОНТАКТЫ
-- ============================================================================
CREATE TABLE IF NOT EXISTS trusted_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 13. ВЫПОЛНЕННЫЕ УПРАЖНЕНИЯ
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL,
    exercise_type TEXT NOT NULL,
    title TEXT,
    completed_at TIMESTAMP DEFAULT NOW(),
    duration_minutes INTEGER,
    completion_count INTEGER DEFAULT 1,
    difficulty_level INTEGER,    -- из миграции 07
    user_notes TEXT,             -- из миграции 07
    mood_before INTEGER,         -- из миграции 07
    mood_after INTEGER,          -- из миграции 07
    CONSTRAINT user_exercises_difficulty_check CHECK (difficulty_level BETWEEN 1 AND 5),
    CONSTRAINT user_exercises_mood_before_check CHECK (mood_before BETWEEN 0 AND 5),
    CONSTRAINT user_exercises_mood_after_check CHECK (mood_after BETWEEN 0 AND 5)
);

-- ============================================================================
-- СТАНДАРТНЫЕ ДАННЫЕ: ТЕМЫ
-- ============================================================================
INSERT INTO themes (id, name, is_dark, primary_color, accent_color) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Светлая', FALSE, '#2196F3', '#FF9800'),
    ('00000000-0000-0000-0000-000000000002', 'Тёмная', TRUE, '#90CAF9', '#FFB74D')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- ИНДЕКСЫ ДЛЯ БЫСТРОГО ПОИСКА
-- ============================================================================

-- Настроение
CREATE INDEX IF NOT EXISTS idx_mood_entries_user_recorded_at 
    ON mood_entries(user_id, recorded_at DESC);

-- Дневник
CREATE INDEX IF NOT EXISTS idx_diary_entries_user_date 
    ON diary_entries(user_id, entry_date);

-- Календарь
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date 
    ON calendar_events(user_id, event_date);

-- Фото
CREATE INDEX IF NOT EXISTS idx_memory_photos_user_id 
    ON memory_photos(user_id, created_at DESC);

-- Психологические тесты
CREATE INDEX IF NOT EXISTS idx_test_results_user_test 
    ON psychological_test_results(user_id, test_id, completed_at DESC);

-- Чат сообщения
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id 
    ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at 
    ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id 
    ON chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at_user 
    ON chat_messages(user_id, created_at DESC);

-- Доверенные контакты
CREATE INDEX IF NOT EXISTS idx_trusted_contacts_user_id 
    ON trusted_contacts(user_id);

-- Упражнения
CREATE INDEX IF NOT EXISTS idx_user_exercises_user_id 
    ON user_exercises(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_exercises_type 
    ON user_exercises(exercise_type);
CREATE INDEX IF NOT EXISTS idx_user_exercises_user_type_date 
    ON user_exercises(user_id, exercise_type, completed_at DESC);
