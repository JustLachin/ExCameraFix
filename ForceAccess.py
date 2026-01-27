import cv2
import time
import os

def force_camera_open():
    print("=== Düşük Seviyeli Kamera Erişim Denemesi ===")
    
    # Denenecek backendler (DSHOW = DirectShow, MSMF = Media Foundation)
    backends = [
        (cv2.CAP_DSHOW, "DirectShow (Eski ama stabil)"),
        (cv2.CAP_MSMF, "Media Foundation (Modern Windows)"),
        (cv2.CAP_ANY, "Otomatik Seçim")
    ]
    
    for backend_id, backend_name in backends:
        print(f"\n--- {backend_name} deneniyor ---")
        # 0 genellikle ana kameradır
        cap = cv2.VideoCapture(0 + backend_id)
        
        if not cap.isOpened():
            print(f"Hata: {backend_name} üzerinden kamera açılamadı.")
            continue
            
        # Bazı kameralarda formatı manuel zorlamak gerekir
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
        
        print("Kamera açıldı, görüntü bekleniyor (5 saniye)...")
        start_time = time.time()
        
        success = False
        while time.time() - start_time < 5:
            ret, frame = cap.read()
            if ret:
                print(f"BAŞARILI! {backend_name} ile görüntü alındı.")
                filename = f"success_{backend_name.split()[0]}.jpg"
                cv2.imwrite(filename, frame)
                print(f"Görüntü kaydedildi: {filename}")
                success = True
                break
            time.sleep(0.5)
            print(".", end="", flush=True)
            
        cap.release()
        if success:
            return True
            
    return False

if __name__ == "__main__":
    if not force_camera_open():
        print("\n\n!!! TÜM DENEMELER BAŞARISIZ OLDU !!!")
        print("Semptom Analizi:")
        print("1. Işık yanıyor ama görüntü yoksa: Windows 'Frame Server' servisi takılmış.")
        print("2. Işık yanıp sönüyorsa: Donanım başlatılıyor ama veri akışı (Stream) gelmiyor.")
        print("\nÇözüm: SuperReset.ps1 scriptini çalıştırıp bilgisayarı yeniden başlatın.")
    else:
        print("\nKamera başarıyla çalıştırıldı!")
