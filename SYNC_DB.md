# Синхронизация базы данных Citrus

## Быстрый старт

### Экспорт БД с одного ПК
```powershell
# Полная БД (структура + данные)
.\sync-db.ps1 -Mode export -BackupFile backup.sql

# Только данные (без структуры)
.\sync-db.ps1 -Mode dump-data -BackupFile data-only.sql

# Только структура (без данных)
.\sync-db.ps1 -Mode dump-structure -BackupFile structure.sql
```

### Импорт БД на другой ПК
```powershell
# Импорт полной БД
.\sync-db.ps1 -Mode import -BackupFile backup.sql

# Применить только миграции (создать структуру с нуля)
.\sync-db.ps1 -Mode migrate
```

## Сценарии использования

### 1. Синхронизация между ПК (полная)
```powershell
# На ПК 1: экспортируем
.\sync-db.ps1 -Mode export -BackupFile backup.sql

# Копируем backup.sql на ПК 2 (через Git, облако, USB)

# На ПК 2: импортируем
.\sync-db.ps1 -Mode import -BackupFile backup.sql
```

### 2. Перенос только данных пользователя
```powershell
# На ПК 1: экспортируем только данные
.\sync-db.ps1 -Mode dump-data -BackupFile user-data.sql

# На ПК 2: импортируем данные в существующую структуру
.\sync-db.ps1 -Mode import -BackupFile user-data.sql
```

### 3. Развёртывание с нуля
```powershell
# На новом ПК: применяем миграции
.\sync-db.ps1 -Mode migrate
```

## Команды

| Команда | Описание |
|---------|----------|
| `export` | Полный дамп БД (структура + данные) |
| `import` | Импорт из SQL файла |
| `migrate` | Применение миграций из `db/migrations/` |
| `dump-data` | Экспорт только данных (без CREATE TABLE) |
| `dump-structure` | Экспорт только структуры (без INSERT) |

## Автоматизация через Git

Добавьте в `.git/hooks/post-commit` для авто-бэкапа:
```bash
#!/bin/bash
powershell -Command ".\\sync-db.ps1 -Mode export -BackupFile db/backups/backup-$(date +%Y%m%d).sql"
```

## Docker команды вручную

```bash
# Экспорт (с сохранением внутри контейнера)
docker exec citrus_postgres pg_dump -U citrus -d citrus -f /tmp/backup.sql
docker cp citrus_postgres:/tmp/backup.sql backup.sql
docker exec citrus_postgres rm /tmp/backup.sql

# Импорт
docker cp backup.sql citrus_postgres:/tmp/restore.sql
docker exec citrus_postgres psql -U citrus -d citrus -f /tmp/restore.sql
docker exec citrus_postgres rm /tmp/restore.sql

# Только структура
docker exec citrus_postgres pg_dump -U citrus -d citrus --schema-only -f /tmp/structure.sql
docker cp citrus_postgres:/tmp/structure.sql structure.sql
docker exec citrus_postgres rm /tmp/structure.sql

# Только данные
docker exec citrus_postgres pg_dump -U citrus -d citrus --data-only -f /tmp/data.sql
docker cp citrus_postgres:/tmp/data.sql data.sql
docker exec citrus_postgres rm /tmp/data.sql
```

## Кодировка

Скрипт использует **UTF-8** для корректного отображения русских символов:
- `PGCLIENTENCODING=UTF8` — переменная окружения для pg_dump/psql внутри контейнера
- Файлы сохраняются через `docker cp`, что сохраняет исходную кодировку PostgreSQL
