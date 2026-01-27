import cv2
import time

def test_camera_settings():
    print("=== Kamera Ayarları Zorlama Modu ===")
    
    # Try multiple indices just in case
    for index in [0, 1]:
        cap = cv2.VideoCapture(index, cv2.CAP_DSHOW)
        if not cap.isOpened():
            continue
            
        print(f"Kamera {index} açıldı. Ayarlar optimize ediliyor...")
        
        # Try to force exposure and brightness
        # Note: Some cameras don't support these via OpenCV, but we try anyway
        cap.set(cv2.CAP_PROP_BRIGHTNESS, 128)
        cap.set(cv2.CAP_PROP_CONTRAST, 128)
        cap.set(cv2.CAP_PROP_SATURATION, 128)
        cap.set(cv2.CAP_PROP_GAIN, 64)
        
        # Disable auto exposure and set a manual one
        cap.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0.25) # 0.25 usually means manual mode in some drivers
        cap.set(cv2.CAP_PROP_EXPOSURE, -5) # Lower value = longer exposure in some drivers
        
        print("Görüntü yakalanıyor (10 kare beklenecek)...")
        for i in range(10):
            ret, frame = cap.read()
            time.sleep(0.1)
            
        if ret:
            # Check if the frame is actually black
            import numpy as np
            mean_val = np.mean(frame)
            print(f"Ortalama parlaklık değeri: {mean_val}")
            
            if mean_val < 5:
                print("UYARI: Görüntü hala çok karanlık (Siyah ekran).")
            else:
                print(f"BAŞARILI! Parlaklık: {mean_val}")
                
            filename = f"settings_test_{index}.jpg"
            cv2.imwrite(filename, frame)
            print(f"Fotoğraf kaydedildi: {filename}")
        
        cap.release()

if __name__ == "__main__":
    test_camera_settings()
