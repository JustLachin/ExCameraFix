# Excalibur G870 Full Hardware & Software Camera Reset
# This script is more aggressive to fix the "Black Screen" issue.

function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Color "=== EXCALIBUR G870 agresif kamera sifirlama (TAM COZUM) ===" "Cyan"

# 1. Kill all camera-using processes
Write-Color "[1/6] Kamera kullanan uygulamalar kapatiliyor..." "Yellow"
$apps = @("Discord", "Teams", "Skype", "Zoom", "WhatsApp", "Camera")
foreach ($app in $apps) {
    Stop-Process -Name $app -Force -ErrorAction SilentlyContinue
}

# 2. Reset Frame Server & Services
Write-Color "[2/6] Kamera servisleri sifirlaniyor..." "Yellow"
Stop-Service -Name "FrameServer" -Force -ErrorAction SilentlyContinue
Set-Service -Name "FrameServer" -StartupType Disabled -ErrorAction SilentlyContinue
Restart-Service -Name "camsvc" -Force -ErrorAction SilentlyContinue

# 3. Registry Enforcement (Deep Clean)
Write-Color "[3/6] Kayit defteri ayarları zorlaniyor..." "Yellow"
$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\Platform",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation\Platform"
)
foreach ($path in $paths) {
    if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "EnableFrameServerMode" -Value 0 -ErrorAction SilentlyContinue
}

# 4. Hardware Power Cycle (Disable/Enable)
Write-Color "[4/6] Kamera donanimi güç döngüsüne sokuluyor..." "Yellow"
$camera = Get-PnpDevice -Class Camera | Where-Object { $_.FriendlyName -like "*Webcam*" }
if ($camera) {
    Write-Color "Cihaz bulundu: $($camera.FriendlyName). Devre disi birakiliyor..." "Magenta"
    Disable-PnpDevice -InstanceId $camera.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Write-Color "Cihaz tekrar etkinlestiriliyor..." "Green"
    Enable-PnpDevice -InstanceId $camera.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
}

# 5. USB Hub Reset (To wake up the sensor)
Write-Color "[5/6] USB Hub bilesenleri kontrol ediliyor..." "Yellow"
$hubs = Get-PnpDevice -Class USB | Where-Object { $_.FriendlyName -like "*Root Hub*" -or $_.FriendlyName -like "*Generic USB Hub*" }
foreach ($hub in $hubs) {
    # We only reset hubs that might be connected to the camera
    # This is safe but might flicker USB mouse/keyboard for a second
    Write-Color "Resetleniyor: $($hub.FriendlyName)" "Gray"
    Disable-PnpDevice -InstanceId $hub.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Enable-PnpDevice -InstanceId $hub.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
}

# 6. Final Privacy Clear
Write-Color "[6/6] Gizlilik izinleri sifirlaniyor..." "Yellow"
$privacyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
if (Test-Path $privacyPath) {
    Set-ItemProperty -Path $privacyPath -Name "Value" -Value "Allow" -ErrorAction SilentlyContinue
}

Write-Color "`nISLEM TAMAMLANDI!" "Green"
Write-Color "Lutfen simdi sunu yapin:" "White"
Write-Color "1. Fn + F10 tusuna iki kez basin (Kapali/Acik)." "White"
Write-Color "2. Bilgisayari kapatip (Sut Down) 10 saniye bekleyip tekrar acin (Restart degil, Shut Down)." "White"
Write-Color "3. Acildiginda hicbir uygulamayi acmadan 'camera_test.py' calistirin." "White"
