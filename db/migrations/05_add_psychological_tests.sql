-- Таблица для хранения результатов психологических тестов
CREATE TABLE IF NOT EXISTS psychological_test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    test_id TEXT NOT NULL,
    scores JSONB NOT NULL,
    interpretations JSONB,
    completed_at TIMESTAMP DEFAULT NOW()
);

-- Индекс для быстрого поиска результатов по пользователю и тесту
CREATE INDEX IF NOT EXISTS idx_test_results_user_test ON psychological_test_results(user_id, test_id, completed_at DESC);
