#!/usr/bin/env bash
set -euo pipefail

# Гарантируем, что dart-инструменты доступны
export PATH="$PATH:$HOME/.pub-cache/bin"

# Маппинг переменных Replit Postgres (PG*) в DB_*, которые ожидает server.dart
export DB_HOST="${DB_HOST:-${PGHOST:-localhost}}"
export DB_PORT="${DB_PORT:-${PGPORT:-5432}}"
export DB_NAME="${DB_NAME:-${PGDATABASE:-citrus}}"
export DB_USER="${DB_USER:-${PGUSER:-citrus}}"
export DB_PASSWORD="${DB_PASSWORD:-${PGPASSWORD:-citrus123}}"

# Порт для Replit preview
export PORT="${PORT:-5000}"

cd "$(dirname "$0")/../apps/dart_frog_backend"

# Подтянем зависимости (быстро, если уже установлены)
dart pub get

# Запускаем сервер
exec dart server.dart
