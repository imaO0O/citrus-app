#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Скрипт для смены IP-адреса API в Flutter приложении

.DESCRIPTION
    Обновляет baseUrl в lib/core/config/api_config.dart

.PARAMETER Ip
    IP-адрес для установки (например, 192.168.0.100)
    Если не указан, определяется автоматически

.PARAMETER Port
    Порт для установки (например, 8081)

.PARAMETER Emulator
    Использовать адрес эмулятора (10.0.2.2)

.EXAMPLE
    .\set-ip.ps1 -Ip 192.168.0.100 -Port 8081

.EXAMPLE
    .\set-ip.ps1
    Автоматически определяет IP и обновляет конфиг

.EXAMPLE
    .\set-ip.ps1 -Emulator
    Устанавливает адрес для Android-эмулятора
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Ip,

    [Parameter(Mandatory = $false)]
    [string]$Port = "8081",

    [switch]$Emulator
)

# Очистка параметров от кавычек
$Ip = $Ip -replace "'", ""
$Port = $Port -replace "'", ""

Write-Host "=== Смена IP-адреса API ===" -ForegroundColor Cyan

# Режим эмулятора
if ($Emulator) {
    $Ip = "10.0.2.2"
    Write-Host "[i] Режим эмулятора: $Ip`:$Port" -ForegroundColor Cyan
}
elseif ([string]::IsNullOrEmpty($Ip)) {
    Write-Host "Автоматическое определение IP..." -ForegroundColor White

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

$NewUrl = "http://$Ip`:$Port"
Write-Host "Новый URL: $NewUrl" -ForegroundColor Green

# Путь к директории проекта (на уровень выше scripts)
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $ProjectRoot "lib\core\config\api_config.dart"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "[!] Файл не найден: $ConfigPath" -ForegroundColor Red
    exit 1
}

$Content = Get-Content $ConfigPath -Raw -Encoding UTF8

# Заменяем URL в api_config.dart (ищем строку с baseUrl)
$OldUrlPattern = "http://[\d\.]+:\d+"
$NewContent = $Content -replace $OldUrlPattern, $NewUrl

if ($Content -ne $NewContent) {
    Set-Content $ConfigPath -Value $NewContent -Encoding UTF8 -NoNewline
    Write-Host "[OK] Обновлён: api_config.dart" -ForegroundColor Green
} else {
    Write-Host "[=] URL уже установлен: $NewUrl" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Готово ===" -ForegroundColor Cyan
Write-Host "Запустите приложение: flutter run" -ForegroundColor Yellow
