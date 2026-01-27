# 📸 EXCALIBUR G870 ULTRA KAPSAMLI KAMERA ONARIM VE KULLANIM REHBERİ

Bu döküman, Excalibur G870 serisi laptoplarda yaşanan kronik kamera sorunlarını (Linux'ta çalışıp Windows'ta çalışmama, siyah ekran, donma, "kamera bulunamadı" hataları) kökten çözmek ve bir daha yaşanmamasını sağlamak amacıyla hazırlanmış profesyonel bir teknik rehberdir.

---

## 📑 İÇİNDEKİLER
1. [Sorunun Teknik Anatomisi](#1-sorunun-teknik-anatomisi)
2. [Sistem Bileşenleri ve Dosya Görevleri](#2-sistem-bileşenleri-ve-dosya-görevleri)
3. [Adım Adım Onarım Protokolü](#3-adım-adım-onarım-protokolü)
4. [Siyah Ekran ve Sensör Sorunları](#4-siyah-ekran-ve-sensör-sorunları)
5. [Discord ve Uygulama Optimizasyonu](#5-discord-ve-uygulama-optimizasyonu)
6. [Kayıt Defteri (Registry) Derin Analiz](#6-kayıt-defteri-registry-derin-analiz)
7. [Donanım Kilitleri (Fn Kombinasyonları)](#7-donanım-kilitleri-fn-kombinasyonları)
8. [Windows Update Sonrası Korunma](#8-windows-update-sonrası-korunma)
9. [Gelişmiş Hata Kodları ve Anlamları](#9-gelişmiş-hata-kodları-ve-anlamları)
10. [Sıkça Sorulan Sorular (SSS)](#10-sıkça-sorulan-sorular-sss)

---

## 1. SORUNUN TEKNİK ANATOMİSİ
Excalibur G870, Quanta üretimi bir web kamerası ve Intel Image Processing Unit (IPU) kullanır. Bu donanımın Linux'ta tak-çalıştır (plug-and-play) olarak çalışıp Windows'ta nazlanmasının temel sebebi şudur:

*   **Media Foundation Frame Server:** Windows, kamerayı doğrudan uygulamaya vermek yerine bu servis üzerinden geçirir. Bu servis, G870'in sensörüyle konuşurken zaman zaman "Deadlock" (ölümcül kilitlenme) yaşar.
*   **UVC Protokol Çakışması:** Windows, kamerayı modern bir "UVC 1.5" cihazı gibi görmeye çalışırken, donanım aslında daha stabil olan "UVC 1.1" modunda çalışmak ister.
*   **Güç Tasarrufu (Selective Suspend):** Windows, boşta gördüğü kamera sensörünün elektriğini keser. Sensör bir kez "derin uykuya" daldığında, uygulama açılsa bile uyanamaz ve siyah ekran verir.

---

## 2. SİSTEM BİLEŞENLERİ VE DOSYA GÖREVLERİ

Klasörünüzdeki her dosya, bu karmaşık yapının bir parçasını düzeltmek için özel olarak kodlanmıştır:

### A. Onarım Scriptleri (PowerShell)
*   **`SuperReset.ps1`:** 
    *   Sistemdeki `FrameServer` servisini durdurur.
    *   Kayıt defterine `EnableFrameServerMode = 0` anahtarını işleyerek Windows'u eski tip (stabil) görüntü alma moduna zorlar.
    *   Kamera cihazını PnP (Plug and Play) seviyesinde kapatıp açarak sürücüyü tazelemeye zorlar.
*   **`BlackScreenFix.ps1`:**
    *   Kameranın donanımsal ID'sini (VID_0408&PID_209D) hedef alır.
    *   `EnableSelectiveSuspend` ve `EnhancedPowerManagementEnabled` değerlerini sıfırlar. Sensörün elektriğinin kesilmesini engeller.

### B. Test ve Teşhis Araçları (Python)
*   **`ForceAccess.py`:** 
    *   OpenCV kütüphanesini kullanarak `CAP_DSHOW` (DirectShow) protokolü üzerinden kameraya erişir.
    *   Windows'un kendi Kamera uygulamasının bile göremediği durumlarda görüntü alabilir.
*   **`SettingsFix.py`:**
    *   Sensörün parlaklık, kontrast ve pozlama (exposure) ayarlarını yazılımsal olarak en üst seviyeye çeker. Siyah ekran sorununda sensörü "ışık almaya" zorlar.
*   **`LowLevelReset.py`:**
    *   `ctypes` kullanarak doğrudan `Mfplat.dll` (Media Foundation Platform) kütüphanesini yükler ve `MFStartup` komutuyla sistemi kod seviyesinde resetler.

---

## 3. ADIM ADIM ONARIM PROTOKOLÜ

Kamera bozulduğunda veya yeni bir Windows kurulumu sonrası şu sırayı takip edin:

1.  **Yönetici Yetkisi Sağlayın:** Tüm `.ps1` dosyaları sistem ayarlarını değiştirdiği için mutlaka PowerShell'i "Yönetici Olarak Çalıştır" seçeneğiyle açmalısınız.
2.  **Scripti Tetikleyin:**
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force; .\SuperReset.ps1
    ```
3.  **Hizmetleri Kontrol Edin:** Script bittikten sonra `Görev Yöneticisi > Hizmetler` sekmesinden `FrameServer` (Kamera Çerçeve Sunucusu) hizmetinin "Durduruldu" olduğundan emin olun.
4.  **Kritik Yeniden Başlatma:** Windows çekirdeği (Kernel), kayıt defteri değişikliklerini ancak açılışta tamamen uygular. Bu adımı asla atlamayın.

---

## 4. SİYAH EKRAN VE SENSÖR SORUNLARI

Kamera ışığı yanıyor ama görüntü gelmiyorsa (siyah ekran):

*   **Neden:** Sensör pozlama süresi (Exposure) 0'da kalmış veya lens kapağı fiziksel olarak kapalı olabilir.
*   **Çözüm:** `SettingsFix.py` dosyasını çalıştırın. Bu dosya kamerayı açacak ve 5 saniye boyunca parlaklık ayarlarını manuel olarak yukarı itecektir.
*   **Donanım Reset:** Senin keşfettiğin yöntem olan "Ayarlar > Kameralar > Devre Dışı Bırak > Etkinleştir" döngüsü, sensöre giden elektriği anlık kesip verdiği için en etkili manuel çözümdür.

---

## 5. DISCORD VE UYGULAMA OPTİMİZASYONU

Discord gibi uygulamalar kamerayı kullanırken ekstra yük bindirir:

*   **Donanım İvmesi:** `Discord Ayarları > Ses ve Görüntü > Gelişmiş > Görüntü İşleme` altındaki seçenekleri tek tek deneyin. Genellikle "OpenH264" ayarını kapatmak stabiliteyi artırır.
*   **Video Codec:** Discord bazen kamerayı `YUY2` formatında açmaya çalışır, G870 ise `MJPG` formatında daha stabildir. Bizim scriptlerimiz sistemi `MJPG` önceliğine çeker.

---

## 6. KAYIT DEFTERİ (REGISTRY) DERİN ANALİZ

Scriptlerin değiştirdiği kritik anahtarlar şunlardır (Manuel kontrol etmek isterseniz):

*   `HKLM\SOFTWARE\Microsoft\Windows Media Foundation\Platform` -> `EnableFrameServerMode` (0 olmalı)
*   `HKLM\SYSTEM\CurrentControlSet\Enum\USB\VID_0408&PID_209D...\Device Parameters` -> `EnableSelectiveSuspend` (0 olmalı)

Bu değerler 0 olduğunda, Windows kamerayı "akıllı bir servis" olarak değil, "basit bir USB cihazı" olarak görür ve bu da Excalibur için en sorunsuz moddur.

---

## 7. DONANIM KİLİTLERİ (FN KOMBİNASYONLARI)

Excalibur G870'de kamera sadece yazılımsal değil, donanımsal bir kilit mekanizmasına da sahiptir:

*   **Fn + F10:** Bu kombinasyon kameranın "Donanım Gizlilik Modu"dur.
*   **Durum Işığı:** Işık hiç yanmıyorsa, Windows cihazı hiç görmüyordur. Bu durumda `Fn + F10` tuşuna basıp `Aygıt Yöneticisi`'ni yenileyin.
*   **Kamera Sürücüsü:** Aygıt yöneticisinde "Kameralar" altında "USB Webcam" görünmelidir. Eğer "Bilinmeyen Cihaz" varsa, `SuperReset.ps1` sürücüyü yeniden eşleştirecektir.

---

## 8. WINDOWS UPDATE SONRASI KORUNMA

Windows Update, "Sürücü Güncelleştirmeleri" adı altında bizim stabil sürücümüzü bozup yerine hatalı bir Intel IPU sürücüsü yükleyebilir:

1.  `Gelişmiş Sistem Ayarları > Donanım > Cihaz Yükleme Ayarları` kısmına gidin.
2.  "Hayır" seçeneğini işaretleyerek Windows'un kafasına göre sürücü değiştirmesini engelleyin.
3.  Eğer güncelleme sonrası kamera giderse, `SuperReset.ps1` dosyasını bir kez çalıştırmak tüm ayarları geri getirecektir.

---

## 9. GELİŞMİŞ HATA KODLARI VE ANLAMLARI

*   **0x80070005 (Access Denied):** Gizlilik ayarlarından kameraya izin verilmemiş.
*   **-2147221164 (Class not registered):** Media Foundation dosyaları bozuk. (Çözüm: `SuperReset.ps1`)
*   **0xA00F4244 (NoCamerasAreAttached):** Donanım kilidi (Fn+F10) kapalı veya kablo temassızlığı.

---

## 10. SIKÇA SORULAN SORULAR (SSS)

**S: Görüntü hala çok karlı veya düşük FPS, ne yapmalıyım?**
C: USB portundaki güç yetersizliği olabilir. Laptop şarja takılıyken test edin ve `BlackScreenFix.ps1` scriptinin çalıştığından emin olun.

**S: Python dosyalarını çalıştıramıyorum, "cv2 bulunamadı" diyor.**
C: `pip install opencv-python numpy` komutuyla gerekli kütüphaneleri yükleyebilirsiniz.

**S: Scriptleri her açılışta çalıştırmalı mıyım?**
C: Hayır, bir kez çalıştırmak ve bilgisayarı yeniden başlatmak yeterlidir. Ayarlar kalıcıdır. Sadece Windows büyük bir güncelleme yaparsa tekrar gerekebilir.

---

*Bu rehber, Excalibur kullanıcılarının kamera sorunlarını çözmek için topluluk deneyimleri ve teknik analizler birleştirilerek oluşturulmuştur.*
*Döküman Versiyonu: 2.0 (Ultra Kapsamlı)*
*Son Güncelleme: 2026-01-27*
