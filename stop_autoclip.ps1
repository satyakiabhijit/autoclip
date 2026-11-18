# AutoClip Windows Terminator (PowerShell)
Write-Host "Stopping AutoClip services..." -ForegroundColor Yellow

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if (Test-Path "backend_win.pid") {
    $BackendPid = Get-Content "backend_win.pid" -ErrorAction SilentlyContinue
    if ($BackendPid) {
        Stop-Process -Id $BackendPid -Force -ErrorAction SilentlyContinue
    }
    Remove-Item "backend_win.pid" -Force -ErrorAction SilentlyContinue
}

if (Test-Path "frontend_win.pid") {
    $FrontendPid = Get-Content "frontend_win.pid" -ErrorAction SilentlyContinue
    if ($FrontendPid) {
        taskkill /PID $FrontendPid /T /F 2>$null
    }
    Remove-Item "frontend_win.pid" -Force -ErrorAction SilentlyContinue
}

# Cleanup ports 8000 and 3000
Get-NetTCPConnection -LocalPort 8000, 3000 -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}

Write-Host "[OK] AutoClip services stopped." -ForegroundColor Green
