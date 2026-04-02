#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Скрипт для смены IP-адреса API в Flutter приложении

.DESCRIPTION
    Меняет baseUrl в файлах:
    - lib/core/repository/auth_repository.dart
    - lib/core/api/sleep_api_service.dart
    - lib/core/api/calendar_event_api_service.dart

.PARAMETER Ip
    IP-адрес для установки (например, 192.168.0.100)
    Если не указан, определяется автоматически

.PARAMETER Port
    Порт для установки (например, 8081)

.EXAMPLE
    .\set-ip.ps1 -Ip 192.168.1.50 -Port 8081

.EXAMPLE
    .\set-ip.ps1 -Port 8081
    Автоматически определит IP компьютера

.EXAMPLE
    .\set-ip.ps1
    Автоматически определит IP и порт 8081
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Ip,
    
    [Parameter(Mandatory = $false)]
    [string]$Port = "8081"
)

# Очистка параметров от кавычек
$Ip = $Ip -replace "'", ""
$Port = $Port -replace "'", ""

# Вывод сообщений
if ([string]::IsNullOrEmpty($Ip)) {
    Write-Host "=== Смена IP-адреса API ===" -ForegroundColor Cyan
    Write-Host "Автоматическое определение IP..." -ForegroundColor White
} else {
    Write-Host "=== Смена IP-адреса API ===" -ForegroundColor Cyan
    Write-Host "IP: $Ip, Порт: $Port" -ForegroundColor White
}

# Автоматическое определение IP, если не указан
if ([string]::IsNullOrEmpty($Ip)) {
    # Приоритет: Wi-Fi адаптеры, затем Ethernet, исключая виртуальные
    $Ip = (Get-NetIPAddress -AddressFamily IPv4 | 
           Where-Object { 
               $_.InterfaceAlias -notmatch "Loopback|Virtual|WSL|Hyper-V|Bluetooth" -and
               $_.IPAddress -match "^\d+\.\d+\.\d+\.\d+$"
           } |
           Sort-Object { 
               if ($_.InterfaceAlias -match "Wi-Fi|Wireless|Беспроводная") { return 1 }
               elseif ($_.InterfaceAlias -match "Ethernet") { return 2 }
               else { return 3 }
           } |
           Select-Object -First 1 -ExpandProperty IPAddress)
    
    if ([string]::IsNullOrEmpty($Ip)) {
        # Резервный вариант через WMI
        $Ip = (Get-WmiObject Win32_NetworkAdapterConfiguration | 
               Where-Object { 
                   $_.IPEnabled -and 
                   $_.IPAddress -match "^\d+\.\d+\.\d+\.\d+$" -and
                   $_.IPAddress -notmatch "26\.|169\.254\."
               } | 
               Select-Object -First 1 -ExpandProperty IPAddress)
    }
    
    if ([string]::IsNullOrEmpty($Ip)) {
        $Ip = "127.0.0.1"
        Write-Host "[!] Не удалось определить IP, используем 127.0.0.1" -ForegroundColor Yellow
    } else {
        Write-Host "[i] Определён IP компьютера: $Ip" -ForegroundColor Cyan
    }
}

Write-Host "Новый URL: http://$Ip`:$Port" -ForegroundColor Green
Write-Host ""

# Путь к директории проекта
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Files = @(
    "lib\core\repository\auth_repository.dart",
    "lib\core\api\sleep_api_service.dart",
    "lib\core\api\calendar_event_api_service.dart"
)

$OldUrlPattern = "http://[\d\.]+:\d+"
$NewUrl = "http://" + $Ip + ":" + $Port

$ModifiedCount = 0

foreach ($File in $Files) {
    $FilePath = Join-Path $ProjectRoot $File
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "[!] Файл не найден: $File" -ForegroundColor Yellow
        continue
    }
    
    $Content = Get-Content $FilePath -Raw -Encoding UTF8
    $NewContent = $Content -replace $OldUrlPattern, $NewUrl
    
    if ($Content -ne $NewContent) {
        Set-Content $FilePath -Value $NewContent -Encoding UTF8 -NoNewline
        Write-Host "[OK] Обновлён: $File" -ForegroundColor Green
        $ModifiedCount++
    } else {
        Write-Host "[=] Без изменений: $File" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Готово ===" -ForegroundColor Cyan
Write-Host "Обновлено файлов: $ModifiedCount из $($Files.Count)" -ForegroundColor White
Write-Host ""
Write-Host "Для проверки запустите:" -ForegroundColor Yellow
Write-Host "  flutter run"
