import cv2
import time
import numpy as np

def force_format_test():
    print("=== Gelişmiş Format ve Çözünürlük Zorlama ===")
    
    cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
    if not cap.isOpened():
        print("Kamera açılamadı!")
        return

    # Formats to try: MJPG, YUY2
    formats = [
        ('MJPG', cv2.VideoWriter_fourcc(*'MJPG')),
        ('YUY2', cv2.VideoWriter_fourcc(*'YUY2')),
        ('H264', cv2.VideoWriter_fourcc(*'H264'))
    ]

    for fmt_name, fmt_code in formats:
        print(f"\n--- {fmt_name} Formatı Deneniyor ---")
        cap.set(cv2.CAP_PROP_FOURCC, fmt_code)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        
        # Give sensor time to adjust
        time.sleep(1)
        
        for i in range(5):
            ret, frame = cap.read()
            
        if ret:
            mean_val = np.mean(frame)
            print(f"Ortalama Parlaklık: {mean_val}")
            cv2.imwrite(f"test_{fmt_name}.jpg", frame)
            if mean_val > 5:
                print(f"BAŞARILI! {fmt_name} formatında görüntü alındı.")
                cap.release()
                return
        else:
            print(f"{fmt_name} formatı desteklenmiyor veya görüntü alınamadı.")

    print("\nHiçbir formatta parlak görüntü alınamadı.")
    cap.release()

if __name__ == "__main__":
    force_format_test()
