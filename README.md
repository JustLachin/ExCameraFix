# 📸 EXCALIBUR G870: NİHAİ KAMERA ONARIM VE TEKNİK DÖKÜMANTASYON REHBERİ (V4.0)

> **DOSYALARI İNDİR:** [https://github.com/JustLachin/ExCameraFix/archive/refs/heads/main.zip](https://github.com/JustLachin/ExCameraFix/archive/refs/heads/main.zip)

Bu döküman, Excalibur G870 serisi cihazlarda yaşanan ve Windows 10/11 işletim sistemlerinde kronikleşen kamera sorunlarını çözmek için geliştirilen tüm yöntemleri, kodları ve teknik mantığı içeren **en kapsamlı rehberdir.**

---

## � 1. TEKNİK SORUN ANALİZİ (Neden Çalışmıyor?)

Excalibur G870 kamerası Linux'ta tak-çalıştır (plug-and-play) olarak çalışırken Windows'ta şu sebeplerle kilitlenir:
1.  **Media Foundation Frame Server (MFT):** Windows, kamerayı bir "aracı servis" üzerinden uygulamalara sunar. G870'in sensörü bu aracı servisle (FrameServer) konuştuğunda kilitlenir.
2.  **Güç Yönetimi (UVC Power Management):** Windows, pil ömrünü uzatmak için USB kamera sensörünü "Selective Suspend" moduna sokar. Sensör bu moddan çıkamaz ve siyah ekran verir.
3.  **Kayıt Defteri Hataları:** Yanlış driver kurulumları veya Windows güncellemeleri, kameranın erişim izinlerini bozar.

---

## 💻 2. TÜM SCRIPTLER VE İÇERDİĞİ KODLAR

### 🚀 A. [SuperReset.ps1](https://github.com/JustLachin/ExCameraFix/blob/main/SuperReset.ps1) - Sistem Seviyesi Onarım
Bu dosya, Windows'un kamera işleme mimarisini kökten değiştirir.

**İçerdiği Kritik Komutlar:**
```powershell
# 1. Windows Kamera Servislerini Durdurma ve Devre Dışı Bırakma
Stop-Service -Name "FrameServer" -Force
Set-Service -Name "FrameServer" -StartupType Disabled

# 2. Kayıt Defterinde Frame Server Modunu Baypas Etme (32-bit ve 64-bit)
$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\Platform",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation\Platform"
)
foreach ($path in $paths) {
    if (!(Test-Path $path)) { New-Item -Path $path -Force }
    Set-ItemProperty -Path $path -Name "EnableFrameServerMode" -Value 0
}
```

### ⚡ B. [FullReset.ps1](https://github.com/JustLachin/ExCameraFix/blob/main/FullReset.ps1) - Agresif Donanım Sıfırlama
Bu script, kameranın bağlı olduğu USB yollarını "elektriksel" olarak resetler.

**İçerdiği Kritik Komutlar:**
```powershell
# 1. Kamera Cihazını Bul ve Kapat/Aç
$camera = Get-PnpDevice -Class Camera | Where-Object { $_.FriendlyName -like "*Webcam*" }
Disable-PnpDevice -InstanceId $camera.InstanceId -Confirm:$false
Enable-PnpDevice -InstanceId $camera.InstanceId -Confirm:$false

# 2. USB Root Hub'ları Resetle (Sensörü Uyandırmak İçin)
Get-PnpDevice -Class USB | Where-Object { $_.FriendlyName -like "*Root Hub*" } | ForEach-Object {
    Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
    Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
}
```

### 👁️ C. [ForceAccess.py](https://github.com/JustLachin/ExCameraFix/blob/main/ForceAccess.py) - Görüntü Yakalama Testi
Kamerayı standart Windows uygulamaları dışında, en alt seviye (DirectShow) protokolüyle açar.

**Kod Mantığı:**
```python
import cv2
# CAP_DSHOW: Windows'un modern (ve hatalı) Media Foundation katmanını atlar.
cap = cv2.VideoCapture(0 + cv2.CAP_DSHOW)
# MJPG: Sıkıştırılmış görüntü formatını zorlar (G870 için en stabil format).
cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
```

### 🌙 D. [BlackScreenFix.ps1](https://github.com/JustLachin/ExCameraFix/blob/main/BlackScreenFix.ps1) - Siyah Ekran Çözümü
Sensörün ışığı yanıyor ama görüntü gelmiyorsa bu script güç ayarlarını ezer.

**İçerdiği Kritik Komutlar:**
```powershell
# USB Seçici Askıya Alma (Selective Suspend) özelliğini kapatır
Set-ItemProperty -Path $cameraPath -Name "EnableSelectiveSuspend" -Value 0
Set-ItemProperty -Path $cameraPath -Name "EnhancedPowerManagementEnabled" -Value 0
```

---

## ⌨️ 3. KULLANILAN TERMİNAL KOMUTLARI (Özet)

Bu süreçte kullanılan ve her kullanıcının bilmesi gereken komutlar:

| Komut | Amacı |
| :--- | :--- |
| `Get-PnpDevice -Class Camera` | Kameranın donanımsal durumunu kontrol eder. |
| `Get-Service FrameServer` | Kamera servisinin çalışıp çalışmadığını gösterir. |
| `python camera_test.py` | Kameradan görüntü alınıp alınamadığını test eder. |
| `pip install opencv-python` | Görüntü yakalama kütüphanesini kurar. |

---

## 🛠️ 4. ONARIM PROTOKOLÜ (Kesin Çözüm İçin İzle)

Eğer kameran çalışmıyorsa şu sırayı asla bozma:

1.  **Scripti Çalıştır:** PowerShell'i yönetici olarak aç ve `SuperReset.ps1` dosyasını çalıştır.
2.  **Agresif Reset:** Eğer siyah ekran devam ediyorsa `FullReset.ps1` dosyasını çalıştır.
3.  **Kritik Kapatma:** Bilgisayarı **Yeniden Başlatma.** Bilgisayarı tamamen **KAPAT (Shut Down)**. 10 saniye bekle ve sonra tekrar aç. (Bu, sensörün voltajını sıfırlayan tek yoldur).
4.  **Manuel Tetikleme (Gerekirse):** Bilgisayar açıldığında hala görüntü yoksa:
    *   Ayarlar > Bluetooth ve Cihazlar > Kameralar > USB Webcam yoluna git.
    *   **Devre Dışı Bırak** de, 2 saniye bekle ve tekrar **Etkinleştir.** (Muhtemelen etkinleştirmek için yeniden başlatmanız istenebilir AMA YENİDEN BAŞLATMAYIN! Ve kameranızı test edin.)

---

## � 5. TÜM DOSYALARIN LİSTESİ VE GÖREVLERİ

1.  **`FullReset.ps1`**: En ağır donanım resetleme scripti.
2.  **`SuperReset.ps1`**: Frame Server engelini kaldıran ana script.
3.  **`BlackScreenFix.ps1`**: Siyah ekran ve güç yönetimi onarıcı.
4.  **`ForceAccess.py`**: Düşük seviye (DirectShow) kamera erişim testi.
5.  **`SettingsFix.py`**: Sensör parlaklık/pozlama ayarlarını sıfırlayıcı.
6.  **`FormatFix.py`**: Desteklenen görüntü formatlarını (MJPG/YUY2) test edici.
7.  **`LowLevelReset.py`**: Windows Medya kütüphanesini (`Mfplat.dll`) sıfırlayıcı.
8.  **`camera_test.py`**: Basit kamera açma testi.
9.  **`RunFix.bat`**: PowerShell scriptlerini yönetici olarak başlatan tetikleyici.

---

*Bu rehber ve beraberindeki kodlar, Excalibur G870 kullanıcılarının yaşadığı mağduriyeti gidermek için özel olarak hazırlanmıştır.*
*Sürüm: 4.0 (Final)*
*Hazırlayan: Trae AI & Lachin*
