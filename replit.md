# citrus-app

Приложение «Цитрус» — сервис мониторинга ментального здоровья и антистресс-поддержки для студентов.

## Структура репозитория

```
apps/
  dart_frog_backend/
    server.dart            Главный файл бэкенда (один большой файл с маршрутами)
    lib/services/          GigaChat и Email сервисы
    pubspec.yaml           Зависимости Dart
  flutter_app/             Flutter мобильный клиент (на Replit не запускается)
packages/
  api_client/              Общий пакет для клиента (скелет)
  models/                  Общие модели (скелет)
db/migrations/             SQL-миграции (схема Supabase)
docker-compose.yml         Локальная Postgres для разработки (на Replit не используется)
```

## Стек

- **Язык:** Dart 3.10 (модуль Replit `dart-3.10`)
- **Бэкенд:** один файл `server.dart` на пакете `dart_frog`
- **БД:** Supabase Postgres (через секреты `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`)
- **Прочее:** GigaChat (ИИ-чат), Cloudinary (фото), JWT, Mailer (Yandex SMTP)

## Запуск на Replit

Workflow «Start application» выполняет:

```bash
cd apps/dart_frog_backend && dart run server.dart
```

Конфигурация:
- `PORT=5000` задан в Replit Secrets — `server.dart` читает его и слушает 5000.
- `DB_*` секреты указывают на Supabase (`aws-1-eu-central-1.pooler.supabase.com:6543/postgres`).
- В `.replit` настроены: модули `dart-3.10`/`postgresql-16`, проброс порта `5000 → 80`, workflow и развёртывание.

Перезапуск — кнопка **Restart** рядом с workflow «Start application» в панели Workflows.

## Маршруты (без префикса `/api`)

`/themes`, `/auth/register`, `/auth/login`, `/auth/forgot-password`, `/auth/reset-password`,
`/user/profile`, `/user/avatar`, `/user/theme`, `/sleep/records`, `/mood/records`,
`/diary/entries`, `/calendar/events`, `/exercises`, `/exercises/complete`, `/exercises/stats`,
`/analytics/stats`, `/tests`, `/tests/results`, `/trusted-contacts` и др.

## Развёртывание (publish)

Настроено как `vm` deployment:
- **Build:** `cd apps/dart_frog_backend && dart_frog build`
- **Run:** `cd apps/dart_frog_backend && PORT=5000 dart build/bin/server.dart`

> Команда сборки осталась с предыдущей dart_frog-структуры; для текущего одностраничного `server.dart` достаточно `dart run server.dart`. При необходимости развёртывание можно перенастроить.

## Известные нюансы

- **Supabase Pooler в transaction mode (порт 6543)** иногда даёт `prepared statement "000000000000" already exists` на первом запросе после рестарта — это коллизия имён prepared statements в `postgres ^2.6` Dart-драйвере. Если станет мешать — использовать direct connection (`db.<project>.supabase.co:5432`) или session-mode pooler.
- **`.env` не нужен на Replit** — в логах будет `[dotenv] Load failed: file not found: '.env'`, это нормально, переменные подтягиваются из Secrets через `includePlatformEnvironment: true`.
- **Replit-овская встроенная Postgres** не используется (бэкенд работает только с Supabase). Её можно удалить из панели Database в UI.
