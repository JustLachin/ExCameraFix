# Excalibur G870 Kamera Onarım ve Etkinleştirme Betiği
# Bu betik yönetici hakları ile çalıştırılmalıdır.

function Write-Host-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Host-Color "=== Excalibur G870 Kamera Onarım Aracı ===" "Cyan"
Write-Host "------------------------------------------"

# 1. Yönetici Kontrolü
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host-Color "HATA: Lütfen bu betiği yönetici olarak çalıştırın!" "Red"
    exit
}

# 2. Donanım Durumu Kontrolü
Write-Host-Color "`n[1/5] Donanım Taraması Yapılıyor..." "Yellow"
$camera = Get-PnpDevice -Class Camera,Image -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Camera*" -or $_.FriendlyName -like "*Webcam*" }

if ($camera) {
    foreach ($dev in $camera) {
        Write-Host "Cihaz Bulundu: $($dev.FriendlyName) - Durum: $($dev.Status)"
        if ($dev.Status -ne "OK") {
            Write-Host-Color "Cihaz sorunlu görünüyor. Yeniden başlatılıyor..." "Magenta"
            Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false
            Start-Sleep -Seconds 2
            Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false
            Write-Host-Color "Cihaz yeniden etkinleştirildi." "Green"
        }
    }
} else {
    Write-Host-Color "UYARI: Windows aygıt yöneticisinde kamera bulunamadı!" "Red"
    Write-Host "Lütfen Fn + F10 (veya Fn + F6) tuş kombinasyonunu deneyin."
}

# 3. Gizlilik Ayarları Kontrolü
Write-Host-Color "`n[2/5] Kayıt Defteri ve Gizlilik Ayarları Onarılıyor..." "Yellow"
try {
    $privacyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
    if (-not (Test-Path $privacyPath)) {
        New-Item -Path $privacyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $privacyPath -Name "Value" -Value "Allow"
    
    $globalPrivacyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
    if (Test-Path $globalPrivacyPath) {
        Set-ItemProperty -Path $globalPrivacyPath -Name "Value" -Value "Allow"
    }
    Write-Host-Color "Gizlilik ayarları 'İzin Ver' olarak güncellendi." "Green"
} catch {
    Write-Host-Color "Gizlilik ayarları güncellenirken hata oluştu." "Red"
}

# 3.5 Frame Server Modu Devre Dışı Bırakma (Bazı kameralarda takılmayı çözer)
Write-Host-Color "`n[2.5/5] Frame Server Modu Yapılandırılıyor..." "Yellow"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\Platform"
if (Test-Path $registryPath) {
    Set-ItemProperty -Path $registryPath -Name "EnableFrameServerMode" -Value 0 -ErrorAction SilentlyContinue
}
$registryPath64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation\Platform"
if (Test-Path $registryPath64) {
    Set-ItemProperty -Path $registryPath64 -Name "EnableFrameServerMode" -Value 0 -ErrorAction SilentlyContinue
}
Write-Host-Color "Frame Server modu devre dışı bırakıldı (Kamera uyumluluğu için)." "Green"

# 3.7 Media Bileşenleri Kontrolü ve Onarımı
Write-Host-Color "`n[2.7/5] Media Bileşenleri Kontrol Ediliyor..." "Yellow"

# HATA 0x80240438 ve Bağlantı Sorunları İçin Agresif Onarım
Write-Host "Windows Update ve Bağlantı bileşenleri sıfırlanıyor (0x80240438 Çözümü)..." -ForegroundColor "Cyan"

# 1. Servisleri Durdur
$services = @("wuauserv", "bits", "cryptsvc", "doSvc")
foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
}

# 2. Windows Update Kayıt Defteri Temizliği (WSUS Bypass)
$registryPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
)
foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name "UseWUServer" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $path -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 0 -ErrorAction SilentlyContinue
    }
}

# 3. Geçici Dosyaları Temizle (SoftwareDistribution) - İsteğe bağlı ama etkili
# Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue

# 4. Servisleri Başlat
foreach ($svc in $services) {
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}

Write-Host "Bağlantı ayarları güncellendi. Yükleme deneniyor..." -ForegroundColor "Cyan"

# Tüm medya ile ilgili yetenekleri al
$mediaCapabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "*Media*" }

foreach ($cap in $mediaCapabilities) {
    if ($cap.State -ne "Installed") {
        Write-Host "--------------------------------------------------" -ForegroundColor "Gray"
        Write-Host "Bileşen: $($cap.Name)" -ForegroundColor "Cyan"
        Write-Host "Durum: İndiriliyor ve Kuruluyor..." -ForegroundColor "Yellow"
        Write-Host "Başlangıç Saati: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor "Gray"
        
        try {
            # DISM ile yüklemeyi dene
            dism.exe /Online /Add-Capability /CapabilityName:$($cap.Name) /NoRestart
            
            $check = Get-WindowsCapability -Online -Name $cap.Name
            if ($check.State -eq "Installed") {
                Write-Host-Color "BAŞARILI: $($cap.Name) yüklendi!" "Green"
            } else {
                throw "Yükleme tamamlanamadı."
            }
        } catch {
            Write-Host-Color "HATA: Otomatik yükleme başarısız (Hata: 0x80240438 devam ediyor)." "Red"
            Write-Host "`n--- MANUEL ÇÖZÜM ADIMLARI ---" -ForegroundColor "Yellow"
            Write-Host "1. Başlat Menüsü > Ayarlar > Uygulamalar > İsteğe Bağlı Özellikler yoluna gidin."
            Write-Host "2. 'Özellikleri görüntüle' butonuna tıklayın."
            Write-Host "3. Arama kutusuna 'Media Player' yazın ve 'Media Player (Eski)' seçeneğini yükleyin."
            Write-Host "4. Eğer Windows 'N' sürümü kullanıyorsanız 'Media Feature Pack'i seçip yükleyin."
            Write-Host "5. İnternet bağlantınızda VPN veya Proxy varsa kapatıp tekrar deneyin."
            Write-Host "----------------------------`n"
        }
    } else {
        Write-Host "Bileşen zaten yüklü: $($cap.Name)" -ForegroundColor "Green"
    }
}

# Eğer hiç medya yeteneği bulunamadıysa (N sürümü olabilir)
if ($null -eq $mediaCapabilities) {
    Write-Host-Color "UYARI: Hiçbir Media bileşeni bulunamadı! Media Feature Pack aranıyor..." "Red"
    try {
        Add-WindowsCapability -Online -Name "Media.MediaFeaturePack~~~~0.0.1.0" -ErrorAction Stop
        Write-Host-Color "Media Feature Pack yüklendi." "Green"
    } catch {
        Write-Host-Color "Media Feature Pack bulunamadı veya yüklenemedi." "Red"
    }
}

Write-Host-Color "Media bileşenleri onarım adımı tamamlandı." "Green"
Write-Host-Color "ÖNEMLİ: Eğer bileşen yüklendiyse, işlem bitince bilgisayarı yeniden başlatın." "Yellow"

# 4. Media Foundation DLL Re-registration (Class Not Registered Hatası İçin)
Write-Host-Color "`n[3/5] Media Foundation Bileşenleri Kaydediliyor..." "Yellow"
$dlls = @("mf.dll", "mfplat.dll", "mfreadwrite.dll", "msmpeg2vdec.dll", "evr.dll")
foreach ($dll in $dlls) {
    if (Test-Path "C:\Windows\System32\$dll") {
        regsvr32.exe /s "C:\Windows\System32\$dll"
    }
}
Write-Host-Color "Sistem DLL bileşenleri re-register edildi." "Green"

# 5. Kamera Uygulamasını Sıfırlama
Write-Host-Color "`n[4/5] Windows Kamera Uygulaması Sıfırlanıyor..." "Yellow"
Get-AppxPackage *WindowsCamera* | Reset-AppxPackage -ErrorAction SilentlyContinue
Write-Host-Color "Kamera uygulaması sıfırlandı." "Green"

# 5.5 Kamera Servisi Kontrolü
Write-Host-Color "`n[4.5/5] Kamera Erişim Servisi Kontrol Ediliyor..." "Yellow"
$camService = Get-Service -Name "CapabilityAccessManagerService" -ErrorAction SilentlyContinue
if ($camService) {
    if ($camService.Status -ne "Running") {
        Start-Service "CapabilityAccessManagerService"
        Write-Host-Color "Kamera servisleri başlatıldı." "Green"
    } else {
        Write-Host-Color "Kamera servisleri zaten çalışıyor." "Green"
    }
}

# 6. Excalibur Control Center Kontrolü
Write-Host-Color "`n[5/5] Özel Yazılım Kontrolü..." "Yellow"
$ccService = Get-Service -Name "*ControlCenter*" -ErrorAction SilentlyContinue
if ($ccService) {
    Write-Host "Control Center servisi bulundu: $($ccService.Name)"
    # Bazı sürümlerde servis takılı kalabiliyor
    Restart-Service $ccService.Name -Force -ErrorAction SilentlyContinue
    Write-Host-Color "Control Center servisi yeniden başlatıldı." "Green"
}

Write-Host "`n------------------------------------------"
Write-Host-Color "İŞLEM TAMAMLANDI!" "Cyan"
Write-Host "`nÖnemli Notlar:"
Write-Host "1. Eğer hala çalışmıyorsa, 'Excalibur Control Center' uygulamasını açın ve Kamera simgesinin 'Açık' olduğundan emin olun."
Write-Host "2. Klavyenizdeki Fn + F10 tuşlarına basarak kamerayı donanımsal olarak açmayı deneyin."
Write-Host "3. Bilgisayarı yeniden başlatmanız önerilir."
Write-Host "------------------------------------------"
