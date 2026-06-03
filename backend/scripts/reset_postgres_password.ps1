# Resets the PostgreSQL 17 `postgres` superuser password to "postgres" and
# creates the scoring_app database. RUN THIS IN AN ELEVATED (Administrator)
# PowerShell window.
#
# How it works (standard, safe procedure):
#   1. Back up pg_hba.conf
#   2. Temporarily switch local auth to "trust" (no password needed)
#   3. Restart the service, set the new password, create the database
#   4. Restore the original pg_hba.conf and restart again
#
# After it finishes, your password is:  postgres

$ErrorActionPreference = 'Stop'

$logPath = Join-Path $PSScriptRoot 'reset_log.txt'
try { Start-Transcript -Path $logPath -Force | Out-Null } catch {}

$pgRoot   = 'C:\Program Files\PostgreSQL\17'
$dataDir  = Join-Path $pgRoot 'data'
$hba      = Join-Path $dataDir 'pg_hba.conf'
$psql     = Join-Path $pgRoot 'bin\psql.exe'
$service  = 'postgresql-x64-17'
$newPass  = 'postgres'
$dbName   = 'scoring_app'

Write-Host '== Checking administrator rights ==' -ForegroundColor Cyan
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($id)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must be run in an ELEVATED PowerShell (Run as Administrator).'
}

Write-Host '== Backing up pg_hba.conf ==' -ForegroundColor Cyan
$backup = "$hba.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
Copy-Item $hba $backup -Force
Write-Host "   Backup: $backup"

try {
    Write-Host '== Switching local auth to trust (temporary) ==' -ForegroundColor Cyan
    $orig = Get-Content $hba -Raw
    $trust = $orig -replace 'scram-sha-256', 'trust' -replace '\bmd5\b', 'trust'
    Set-Content -Path $hba -Value $trust -Encoding ascii

    Write-Host '== Restarting service ==' -ForegroundColor Cyan
    Restart-Service $service -Force
    Start-Sleep -Seconds 3

    Write-Host '== Setting new postgres password ==' -ForegroundColor Cyan
    & $psql -U postgres -d postgres -h localhost -c "ALTER USER postgres WITH PASSWORD '$newPass';"

    Write-Host "== Creating database '$dbName' (if it does not exist) ==" -ForegroundColor Cyan
    $exists = & $psql -U postgres -d postgres -h localhost -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName';"
    if ($exists -ne '1') {
        & $psql -U postgres -d postgres -h localhost -c "CREATE DATABASE $dbName;"
        Write-Host "   Created $dbName"
    } else {
        Write-Host "   $dbName already exists"
    }
}
finally {
    Write-Host '== Restoring original pg_hba.conf ==' -ForegroundColor Cyan
    Copy-Item $backup $hba -Force
    Restart-Service $service -Force
    Start-Sleep -Seconds 3
}

Write-Host ''
Write-Host 'DONE. postgres password is now: postgres' -ForegroundColor Green
Write-Host "Database '$dbName' is ready. You can close this window." -ForegroundColor Green
try { Stop-Transcript | Out-Null } catch {}
