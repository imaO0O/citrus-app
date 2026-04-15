-- Миграция 07: Улучшение таблиц chat_messages и user_exercises
-- Добавление полезных полей и индексов для статистики

-- Добавляем поле response_time_ms для измерения скорости ответа ИИ
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS response_time_ms INTEGER;

-- Добавляем поле tokens_used для отслеживания использования токенов
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS tokens_used INTEGER;

-- Добавляем поле model_used для отслеживания используемой модели
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS model_used TEXT;

-- Добавляем поле mood_before для отслеживания настроения до сессии
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS mood_before INTEGER CHECK (mood_before BETWEEN 0 AND 5);

-- Добавляем поле mood_after для отслеживания настроения после сессии
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS mood_after INTEGER CHECK (mood_after BETWEEN 0 AND 5);

-- Добавляем поле session_id для группировки сообщений по сессиям
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS session_id TEXT;

-- Добавляем индекс для фильтрации по session_id
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON chat_messages(session_id);

-- Добавляем индекс для статистики по дате
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at_user ON chat_messages(user_id, created_at DESC);

-- Улучшаем таблицу user_exercises
-- Добавляем поле для отслеживания прогресса
ALTER TABLE user_exercises 
ADD COLUMN IF NOT EXISTS difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5);

-- Добавляем поле для заметок пользователя после упражнения
ALTER TABLE user_exercises 
ADD COLUMN IF NOT EXISTS user_notes TEXT;

-- Добавляем поле mood_before для отслеживания настроения до упражнения
ALTER TABLE user_exercises 
ADD COLUMN IF NOT EXISTS mood_before INTEGER CHECK (mood_before BETWEEN 0 AND 5);

-- Добавляем поле mood_after для отслеживания настроения после упражнения
ALTER TABLE user_exercises 
ADD COLUMN IF NOT EXISTS mood_after INTEGER CHECK (mood_after BETWEEN 0 AND 5);

-- Добавляем индекс для группировки по exercise_type
CREATE INDEX IF NOT EXISTS idx_user_exercises_type ON user_exercises(exercise_type);

-- Добавляем индекс для статистики по дате и типу
CREATE INDEX IF NOT EXISTS idx_user_exercises_user_type_date ON user_exercises(user_id, exercise_type, completed_at DESC);
