# Excalibur G870 Black Screen Fix (Aggressive Power & Protocol Fix)
# Targeting Quanta Camera (VID_0408&PID_209D)

function Write-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Color "=== Excalibur G870 Siyah Ekran Onarımı (Güç ve Protokol) ===" "Cyan"

# 1. USB Seçici Askıya Alma (Selective Suspend) Devre Dışı Bırakma
Write-Color "[1/3] Kamera Güç Tasarrufu Ayarları Devre Dışı Bırakılıyor..." "Yellow"
$cameraPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_0408&PID_209D&MI_00\6&53BB634&0&0000\Device Parameters"

if (Test-Path $cameraPath) {
    Set-ItemProperty -Path $cameraPath -Name "EnableSelectiveSuspend" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cameraPath -Name "EnhancedPowerManagementEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cameraPath -Name "SelectiveSuspendEnabled" -Value 0 -ErrorAction SilentlyContinue
    Write-Color "Güç tasarrufu kısıtlamaları kaldırıldı." "Green"
} else {
    Write-Color "Kamera kayıt yolu bulunamadı, genel ayarlar deneniyor..." "Red"
}

# 2. UVC (USB Video Class) Protokol Onarımı
Write-Color "[2/3] UVC Protokol Ayarları Optimize Ediliyor..." "Yellow"
$mfPath = "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\Platform"
$mfPath64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation\Platform"

foreach ($path in @($mfPath, $mfPath64)) {
    if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    # FrameServer'ı tamamen körleyelim, DirectShow'u zorlayalım
    Set-ItemProperty -Path $path -Name "EnableFrameServerMode" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "EnableAutoRotation" -Value 0 -ErrorAction SilentlyContinue
}

# 3. Kamera Cihazını "Yazılımsal" Olarak Yeniden Başlatma
Write-Color "[3/3] Kamera Sürücüsü Yeniden Yükleniyor..." "Yellow"
$dev = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Webcam*" -or $_.HardwareID -like "*VID_0408&PID_209D*" }

if ($dev) {
    Write-Color "Cihaz bulundu: $($dev.FriendlyName). Resetleniyor..." "Green"
    Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    Write-Color "Cihaz başarıyla resetlendi." "Green"
}

Write-Color "`nİŞLEM TAMAMLANDI!" "Green"
Write-Color "Lütfen şunları yapın:" "White"
Write-Color "1. Fn + F10 tuşuna basarak kameranın kapalı olmadığından emin olun." "White"
Write-Color "2. BİLGİSAYARI YENİDEN BAŞLATIN (Kayıt defteri ayarları için şart)." "White"
Write-Color "3. Açıldığında SettingsFix.py scriptini tekrar çalıştırın." "White"
