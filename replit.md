# citrus-app

Приложение «Цитрус» — сервис мониторинга ментального здоровья и антистресс-поддержки для студентов.

## Структура репозитория

```
apps/
  dart_frog_backend/
    server.dart            Точка входа: конфиг, БД, роутинг, CORS, main
    handlers/              Обработчики маршрутов по модулям (part-файлы):
                           auth, user, sleep, mood, diary, calendar,
                           media (фото/контакты), tests, exercises, casino, content
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
- **Бэкенд:** `server.dart` (точка входа + роутинг) и `handlers/*.dart` (part-файлы одной библиотеки) на пакете `dart_frog`
- **БД:** Supabase Postgres (через секреты `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL`)
- **Прочее:** GigaChat (ИИ-чат), Cloudinary (фото), JWT, Mailer (Yandex SMTP)

## Запуск на Replit

Workflow «Start application» выполняет:

```bash
cd apps/dart_frog_backend && dart run server.dart
```

Конфигурация:
- `PORT=5000` задан в Replit Secrets — `server.dart` читает его и слушает 5000.
- `DB_*` секреты указывают на Supabase (`db.<project>.supabase.co:5432/postgres` — прямое подключение).
- В `.replit` настроены: модули `dart-3.10`/`postgresql-16`, проброс порта `5000 → 80`, workflow и развёртывание.

Перезапуск — кнопка **Restart** рядом с workflow «Start application» в панели Workflows.

## Маршруты (без префикса `/api`)

`/themes`, `/auth/register`, `/auth/login`, `/auth/forgot-password`, `/auth/reset-password`,
`/user/profile`, `/user/avatar`, `/user/theme`, `/sleep/records`, `/mood/records`,
`/diary/entries`, `/calendar/events`, `/exercises`, `/exercises/complete`, `/exercises/stats`,
`/analytics/stats`, `/tests`, `/tests/results`, `/trusted-contacts` и др.

## Развёртывание (publish)

Настроено как `vm` deployment:
- **Build:** `cd apps/dart_frog_backend && dart pub get`
- **Run:** `cd apps/dart_frog_backend && dart run server.dart`

`PORT=5000` и `DB_*` (Supabase) подтягиваются из Secrets автоматически и в development, и в production.

## Известные нюансы

- **Supabase Pooler в transaction mode (порт 6543)** даёт ошибку `42P05 duplicate_prepared_statement` — коллизия имён prepared statements в `postgres ^2.6` Dart-драйвере при работе через Supavisor. **Решение:** использовать прямое подключение (`db.<project>.supabase.co:5432`) вместо transaction-mode pooler. В коде добавлен автоматический ретри при 42P05 (закрытие + переподключение + повторный запрос). SSL включается автоматически если хост содержит `supabase`, или явно через `DB_SSL=true`.
- **`.env` не нужен на Replit** — в логах будет `[dotenv] Load failed: file not found: '.env'`, это нормально, переменные подтягиваются из Secrets через `includePlatformEnvironment: true`.
- **Replit-овская встроенная Postgres** не используется (бэкенд работает только с Supabase). Её можно удалить из панели Database в UI.
