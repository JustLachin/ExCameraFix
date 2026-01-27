# 📸 EXCALIBUR G870 ULTRA KAPSAMLI KAMERA ONARIM VE KULLANIM REHBERİ

Bu döküman, Excalibur G870 serisi laptoplarda yaşanan kronik kamera sorunlarını (Linux'ta çalışıp Windows'ta çalışmama, siyah ekran, donma, "kamera bulunamadı" hataları) kökten çözmek ve bir daha yaşanmamasını sağlamak amacıyla hazırlanmış profesyonel bir teknik rehberdir.

---

## 📑 İÇİNDEKİLER
1. [Sorunun Teknik Anatomisi](#1-sorunun-teknik-anatomisi)
2. [Dosya ve Araç Rehberi](#2-dosya-ve-araç-rehberi)
3. [Adım Adım Onarım Protokolü](#3-adım-adım-onarım-protokolü)
4. [Kritik Kayıt Defteri ve Sistem Ayarları](#4-kritik-kayıt-defteri-ve-sistem-ayarları)
5. [Discord ve Uygulama Optimizasyonu](#5-discord-ve-uygulama-optimizasyonu)
6. [Sıkça Karşılaşılan Hatalar ve Çözümleri](#6-sıkça-karşılaşılan-hatalar-ve-çözümleri)
7. [Geleceğe Dönük Korunma](#7-geleceğe-dönük-korunma)

---

## 1. SORUNUN TEKNİK ANATOMİSİ
Excalibur G870, Quanta üretimi bir web kamerası ve Intel Image Processing Unit (IPU) kullanır. Bu donanımın Linux'ta sorunsuz çalışıp Windows'ta hata vermesinin 3 ana sebebi vardır:

*   **Media Foundation Frame Server:** Windows'un kamerayı bir servis üzerinden geçirme çabası G870 sensörüyle çakışır.
*   **Güç Yönetimi (Selective Suspend):** Windows'un pil tasarrufu için kamera sensörüne giden elektriği kesmesi.
*   **Protokol Uyuşmazlığı:** Modern uygulamaların (MSMF) kamerayı açamaması, ancak eski tip (DirectShow) erişimin çalışması.

---

## 2. DOSYA VE ARAÇ REHBERİ

Klasörünüzdeki her dosya, bu karmaşık yapının bir parçasını düzeltmek için özel olarak kodlanmıştır:

### 📜 Ana Onarım Dosyaları
*   **`FixExcaliburCamera.ps1`**: İlk aşama onarım scripti. Media Feature Pack kurulumu ve temel gizlilik ayarlarını yapar.
*   **`RunFix.bat`**: `FixExcaliburCamera.ps1` scriptini otomatik olarak yönetici haklarıyla başlatan kolaylaştırıcıdır.
*   **`SuperReset.ps1`**: **[EN KRİTİK DOSYA]** Windows Camera Frame Server'ı tamamen devre dışı bırakır ve donanımı DirectShow moduna zorlar.

### 🐍 Teşhis ve Test Araçları (Python)
*   **`ForceAccess.py`**: Kameraya en alt seviyeden (DirectShow) bağlanarak görüntü almayı zorlar.
*   **`camera_test.py`**: Standart Windows protokolleriyle kameranın durumunu kontrol eder.
*   **`FormatFix.py`**: MJPG, YUY2 ve H264 formatlarını tek tek deneyerek sensörü en uygun moda sokar.
*   **`SettingsFix.py`**: Siyah ekran sorunlarında sensörün parlaklık ve pozlama (exposure) ayarlarını manuel olarak yukarı çeker.
*   **`LowLevelReset.py`**: `Mfplat.dll` üzerinden medya kütüphanelerini kod seviyesinde sıfırlar.

### 🛠️ Özel Onarım Araçları
*   **`BlackScreenFix.ps1`**: Kamera ışığı yanıp görüntü gelmediği (siyah ekran) durumlarda güç yönetimi ayarlarını temizler.

---

## 3. ADIM ADIM ONARIM PROTOKOLÜ

Kameranız bozulduğunda şu sırayı takip edin:

1.  **Güç Kontrolü (BAZI BİLGİSAYARLARDA):** `Fn + F10` tuşuna basarak kameranın donanımsal olarak açık olduğundan emin olun (Işık yanmalı).
2.  **Yönetici Onarımı:** PowerShell'i yönetici olarak açın ve şu komutu çalıştırın:
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force; .\SuperReset.ps1
    ```
3.  **Düşük Seviye Reset:** Ardından Python ile medya kütüphanelerini resetleyin:
    ```bash
    python LowLevelReset.py
    ```
4.  **Yeniden Başlatma:** Bilgisayarı mutlaka yeniden başlatın.
5.  **Sihirli Manuel Tetikleme:** Eğer hala görüntü yoksa:
    *   `Ayarlar > Bluetooth ve Cihazlar > Kameralar > USB Webcam` yoluna gidin.
    *   **Devre Dışı Bırak** deyin, 2 saniye bekleyin ve **Etkinleştir** deyin. (Muhtemelen etkinleştirmek için yeniden başlatmanız istenebilir AMA YENİDEN BAŞLATMAYIN! Ve kameranızı test edin.)

---

## 4. KRİTİK KAYIT DEFTERİ VE SİSTEM AYARLARI

Scriptlerin yaptığı kalıcı değişiklikler şunlardır:
*   `EnableFrameServerMode = 0`: Uygulamaların kameraya doğrudan erişmesini sağlar.
*   `EnableSelectiveSuspend = 0`: Sensörün uykuya dalmasını engeller.
*   `Privacy Consent`: Kameraya erişim izinlerini kayıt defteri seviyesinde "Allow" (İzin Ver) yapar.

---

## 5. DISCORD VE UYGULAMA OPTİMİZASYONU

Discord gibi uygulamalarda sorun yaşıyorsanız:
*   `Kullanıcı Ayarları > Ses ve Görüntü` altındaki **"Video Kodlama"** donanım ivmesini kapatın.
*   Kamera kaynağı olarak sadece "USB Webcam" seçili olduğundan emin olun.
*   Görüntü siyah gelirse `SettingsFix.py` scriptini çalıştırarak sensörü uyandırın.

---

## 6. SIKÇA KARŞILAŞILAN HATALAR VE ÇÖZÜMLERİ

| Hata Kodu / Semptom | Anlamı | Çözüm |
| :--- | :--- | :--- |
| **0x80240438** | Media Feature Pack indirilemiyor | İnterneti değiştirin (Telefon hotspot) veya manuel kurun. |
| **Siyah Ekran** | Sensör uyku modunda veya kapalı | `BlackScreenFix.ps1` ve `SettingsFix.py` çalıştırın. |
| **Işık Yanıp Sönüyor** | Veri akışı (Stream) başlatılamıyor | `SuperReset.ps1` çalıştırıp PC'yi yeniden başlatın. |
| **-2147221164** | Media Foundation Hatası | `LowLevelReset.py` çalıştırın. |

---

## 7. GELECEĞE DÖNÜK KORUNMA

Windows Update bazen yaptığımız bu ayarları (özellikle FrameServer ayarını) sıfırlayabilir. Eğer bir gün güncelleme sonrası kamera yine "yükleniyor" modunda kalırsa:
1.  Klasördeki `SuperReset.ps1` scriptini tekrar çalıştırın.
2.  Bilgisayarı yeniden başlatın.
3.  Kameranız eski haline dönecektir.

---
*Bu rehber, Excalibur G870 kullanıcılarının kamera çilesine son vermek için Trae AI tarafından özel olarak dökümante edilmiştir.*
*Versiyon: 3.0 (Tüm Dosyaları Kapsayan Final Versiyon)*
*Tarih: 2026-01-27*
