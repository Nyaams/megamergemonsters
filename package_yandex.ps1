param(
    [string]$ExportDir = "export_web",
    [string]$OutputFile = "yandex_build.zip"
)

$RootDir = Get-Location
$SourcePath = Join-Path $RootDir $ExportDir
$BridgeSource = Join-Path $RootDir "yandex_sdk_bridge.js"
$ZipTarget = Join-Path $RootDir $OutputFile

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Yandex Games Package Builder for Godot   " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if (!(Test-Path $SourcePath)) {
    Write-Host "Directory '$ExportDir' not found." -ForegroundColor Yellow
    Write-Host "Please export your project first in Godot:" -ForegroundColor White
    Write-Host "  1. Project -> Export... -> Web" -ForegroundColor White
    Write-Host "  2. Click 'Export Project...' (NOT 'Export ZIP'!)" -ForegroundColor Yellow
    Write-Host "  3. Create folder '$ExportDir' and set filename to 'index.html'" -ForegroundColor White
    Write-Host "  4. Run this script again." -ForegroundColor Green
    exit 0
}

$IndexHtml = Join-Path $SourcePath "index.html"
if (!(Test-Path $IndexHtml)) {
    Write-Host "ERROR: 'index.html' not found in '$ExportDir'!" -ForegroundColor Red
    Write-Host "Ensure the main HTML file is named 'index.html'." -ForegroundColor Yellow
    exit 1
}

$BridgeDest = Join-Path $SourcePath "yandex_sdk_bridge.js"
Copy-Item -Path $BridgeSource -Destination $BridgeDest -Force
Write-Host "Copied yandex_sdk_bridge.js into '$ExportDir'." -ForegroundColor Green

if (Test-Path $ZipTarget) {
    Remove-Item -Path $ZipTarget -Force
}

Write-Host "Creating archive '$OutputFile'..." -ForegroundColor Cyan
$Items = Get-ChildItem -Path "$SourcePath\*" | Select-Object -ExpandProperty FullName
Compress-Archive -Path $Items -DestinationPath $ZipTarget -Force

if (Test-Path $ZipTarget) {
    $size = [math]::Round((Get-Item $ZipTarget).Length / 1MB, 2)
    Write-Host "SUCCESS! Archive created: $OutputFile ($size MB)" -ForegroundColor Green
    Write-Host "'index.html' is located at the root of the ZIP archive." -ForegroundColor Green
    Write-Host "You can now upload $OutputFile directly to Yandex Games Console (Draft tab)." -ForegroundColor Cyan
}
