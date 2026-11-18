# AutoClip Windows Launcher (PowerShell)
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "         AutoClip Launcher (Windows)      " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Set desktop mode environment
$env:AUTOCLIP_MODE = "desktop"
$env:AUTOCLIP_DESKTOP_MODE = "true"
$env:AUTOCLIP_DATA_DIR = "$ScriptDir\data"
$env:AUTOCLIP_APP_DIR = "$ScriptDir\data"
$env:PYTHONUNBUFFERED = "1"

# Ensure directories exist
if (-not (Test-Path "data")) { New-Item -ItemType Directory -Path "data" | Out-Null }
if (-not (Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" | Out-Null }
if (-not (Test-Path "uploads")) { New-Item -ItemType Directory -Path "uploads" | Out-Null }

# Stop any previous instances on ports 8000 / 3000
Get-NetTCPConnection -LocalPort 8000, 3000 -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}

# 1. Start backend
Write-Host "[1/3] Starting backend server (http://127.0.0.1:8000)..." -ForegroundColor Yellow
$BackendProc = Start-Process -FilePath ".\venv\Scripts\python.exe" -ArgumentList "-m uvicorn backend.main:app --host 127.0.0.1 --port 8000" -PassThru -WindowStyle Hidden
$BackendProc.Id | Out-File -Encoding ascii "backend_win.pid"

# Wait for backend
$Retries = 0
$BackendReady = $false
while ($Retries -lt 20) {
    Start-Sleep -Seconds 1
    try {
        $resp = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($resp.status -eq "healthy") {
            $BackendReady = $true
            break
        }
    } catch {}
    $Retries++
}

if (-not $BackendReady) {
    Write-Host "[ERROR] Backend failed to start. Check logs/backend.log for details." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Backend started successfully!" -ForegroundColor Green

# 2. Start frontend
Write-Host "[2/3] Starting frontend interface (http://localhost:3000)..." -ForegroundColor Yellow
$FrontendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd frontend && npm run dev -- --host 127.0.0.1 --port 3000" -PassThru -WindowStyle Hidden
$FrontendProc.Id | Out-File -Encoding ascii "frontend_win.pid"

# Wait for frontend
$Retries = 0
$FrontendReady = $false
while ($Retries -lt 20) {
    Start-Sleep -Seconds 1
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", 3000)
        $tcp.Close()
        $FrontendReady = $true
        break
    } catch {}
    $Retries++
}

if ($FrontendReady) {
    Write-Host "[OK] Frontend started successfully!" -ForegroundColor Green
} else {
    Write-Host "[INFO] Frontend is initializing..." -ForegroundColor Yellow
}

# 3. Open browser
Write-Host "[3/3] Opening AutoClip in your browser..." -ForegroundColor Cyan
Start-Process "http://localhost:3000"

Write-Host ""
Write-Host "AutoClip is running at http://localhost:3000" -ForegroundColor Green
Write-Host "To stop the app: run .\stop_autoclip.ps1 or double-click stop_autoclip.bat" -ForegroundColor Gray
Write-Host ""
