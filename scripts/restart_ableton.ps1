# Restart Ableton Live (Windows) - used after installing a new Remote Script.
#
# Asks Live to close gracefully, so you still get the normal "Save changes?"
# dialog. It will NOT kill Live out from under unsaved work unless you pass
# -Force explicitly.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/restart_ableton.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/restart_ableton.ps1 -Force
#
# NOTE: keep this file ASCII-only. Windows PowerShell 5.1 reads .ps1 as
# Windows-1252, and a UTF-8 dash/smart-quote decodes into a character it
# treats as a string delimiter, which breaks parsing.

param(
    [int]$TimeoutSeconds = 60,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-LiveProcess {
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -like 'Ableton Live*' } |
        Select-Object -First 1
}

# Locate the Live executable (C:\ProgramData\Ableton\Live NN\Program\*.exe)
$exe = Get-ChildItem 'C:\ProgramData\Ableton' -Recurse -Filter '*.exe' -Depth 3 -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'Ableton Live*' } |
    Select-Object -First 1 -ExpandProperty FullName

$live = Get-LiveProcess

if (-not $live) {
    if (-not $exe) {
        Write-Host "Could not find Ableton Live. Start it manually."
        exit 1
    }
    Write-Host "Ableton is not running. Starting it..."
    Start-Process $exe
    Write-Host "Ableton started."
    exit 0
}

if (-not $exe) { $exe = $live.Path }

Write-Host "Asking Ableton to close - save your set if prompted..."
$null = $live.CloseMainWindow()

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    if (-not (Get-LiveProcess)) { break }
    Start-Sleep -Seconds 1
}

$live = Get-LiveProcess
if ($live) {
    if ($Force) {
        Write-Host "Still open after $TimeoutSeconds s. Force quitting - UNSAVED CHANGES WILL BE LOST."
        Stop-Process -Id $live.Id -Force
        Start-Sleep -Seconds 2
    }
    else {
        Write-Host "Ableton is still open after $TimeoutSeconds s (probably waiting on the Save dialog)."
        Write-Host "Finish saving, then re-run this script. Pass -Force to quit without waiting."
        exit 1
    }
}

Write-Host "Ableton closed. Restarting..."
Start-Sleep -Seconds 1
Start-Process $exe
Write-Host ""
Write-Host "Ableton restarted."
Write-Host "Confirm: Settings > Link, Tempo & MIDI > Control Surface = 'AbletonMCP'."
