param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("export", "import", "migrate", "dump-data", "dump-structure")]
    [string]$Mode,
    
    [string]$BackupFile = "backup.sql",
    [switch]$DataOnly,
    [switch]$StructureOnly
)

$containerName = "citrus_postgres"
$user = "citrus"
$db = "citrus"
$migrationsPath = ".\db\migrations"

function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

if ($Mode -eq "export") {
    Write-Color "Экспорт полной БД в $BackupFile..." "Cyan"
    docker exec -e PGCLIENTENCODING=UTF8 $containerName pg_dump -U $user -d $db -f /tmp/backup.sql
    docker cp "${containerName}:/tmp/backup.sql" $BackupFile
    docker exec $containerName rm /tmp/backup.sql
    Write-Color "✓ Экспорт завершён" "Green"
}
elseif ($Mode -eq "import") {
    if (-not (Test-Path $BackupFile)) {
        Write-Color "✗ Файл $BackupFile не найден" "Red"
        exit 1
    }
    Write-Color "Импорт БД из $BackupFile..." "Cyan"
    docker cp $BackupFile "${containerName}:/tmp/restore.sql"
    docker exec -e PGCLIENTENCODING=UTF8 $containerName psql -U $user -d $db -f /tmp/restore.sql
    docker exec $containerName rm /tmp/restore.sql
    Write-Color "✓ Импорт завершён" "Green"
}
elseif ($Mode -eq "migrate") {
    Write-Color "Применение миграций из $migrationsPath..." "Cyan"
    $files = Get-ChildItem -Path $migrationsPath -Filter "*.sql" | Sort-Object Name
    foreach ($file in $files) {
        Write-Host "  Applying $($file.Name)..."
        docker cp $file.FullName "${containerName}:/tmp/migration.sql"
        docker exec -e PGCLIENTENCODING=UTF8 $containerName psql -U $user -d $db -f /tmp/migration.sql
        docker exec $containerName rm /tmp/migration.sql
    }
    Write-Color "✓ Миграции применены" "Green"
}
elseif ($Mode -eq "dump-data") {
    Write-Color "Экспорт только данных (без структуры)..." "Cyan"
    docker exec -e PGCLIENTENCODING=UTF8 $containerName pg_dump -U $user -d $db --data-only -f /tmp/data.sql
    docker cp "${containerName}:/tmp/data.sql" $BackupFile
    docker exec $containerName rm /tmp/data.sql
    Write-Color "✓ Экспорт данных завершён" "Green"
}
elseif ($Mode -eq "dump-structure") {
    Write-Color "Экспорт только структуры БД..." "Cyan"
    docker exec -e PGCLIENTENCODING=UTF8 $containerName pg_dump -U $user -d $db --schema-only -f /tmp/structure.sql
    docker cp "${containerName}:/tmp/structure.sql" $BackupFile
    docker exec $containerName rm /tmp/structure.sql
    Write-Color "✓ Экспорт структуры завершён" "Green"
}
else {
    Write-Color "Неизвестный режим: $Mode" "Red"
    Write-Host @"

Использование:
  .\sync-db.ps1 -Mode export              - Экспорт полной БД
  .\sync-db.ps1 -Mode import              - Импорт полной БД
  .\sync-db.ps1 -Mode migrate             - Применить миграции
  .\sync-db.ps1 -Mode dump-data           - Экспорт только данных
  .\sync-db.ps1 -Mode dump-structure      - Экспорт только структуры

Примеры:
  .\sync-db.ps1 -Mode export -BackupFile backup.sql
  .\sync-db.ps1 -Mode import -BackupFile backup.sql
  .\sync-db.ps1 -Mode migrate
"@
}
