import cv2
import sys

def test_camera(index=0):
    print(f"Kamera indeksi {index} deneniyor...")
    cap = cv2.VideoCapture(index)
    
    if not cap.isOpened():
        print(f"Hata: Kamera (indeks {index}) açılamadı.")
        return False
    
    ret, frame = cap.read()
    if ret:
        print(f"Başarılı! Kamera (indeks {index}) görüntüsü alındı.")
        cv2.imwrite("camera_test_result.jpg", frame)
        print("Test görüntüsü 'camera_test_result.jpg' olarak kaydedildi.")
        cap.release()
        return True
    else:
        print(f"Hata: Kamera (indeks {index}) görüntüsü okunamadı.")
        cap.release()
        return False

if __name__ == "__main__":
    found = False
    # Birden fazla indeksi dene (bazen harici kameralar veya sanal kameralar olabilir)
    for i in range(5):
        if test_camera(i):
            found = True
            break
    
    if not found:
        print("\nHiçbir kamera kaynağından görüntü alınamadı.")
        sys.exit(1)
    else:
        print("\nKamera testi başarıyla tamamlandı.")
        sys.exit(0)
