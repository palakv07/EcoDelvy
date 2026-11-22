# Run the Python Optimization Worker for EcoDelvy Serverpod
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$python = "python"
if (Test-Path ".\.venv\Scripts\python.exe") {
    $python = ".\.venv\Scripts\python.exe"
} elseif (Test-Path "..\.venv\Scripts\python.exe") {
    $python = "..\.venv\Scripts\python.exe"
}

Write-Host "Starting EcoDelvy Optimization Worker using $python..." -ForegroundColor Cyan
& $python -m optimization_service.worker
