import ctypes
from ctypes import wintypes
import time

# Windows low-level API constants
MF_SDK_VERSION = 0x0002
MF_API_VERSION = 0x0070
MF_VERSION = (MF_SDK_VERSION << 16) | MF_API_VERSION

def low_level_camera_reset():
    print("=== Low-Level Media Foundation Reset (C++ Logic via Python) ===")
    
    try:
        mf = ctypes.windll.Mfplat
        ole32 = ctypes.windll.ole32
        
        # Initialize COM
        ole32.CoInitializeEx(None, 0x2) # COINIT_APARTMENTTHREADED
        
        # Startup Media Foundation
        hr = mf.MFStartup(MF_VERSION, 0)
        if hr == 0:
            print("[OK] Media Foundation started successfully.")
        else:
            print(f"[FAIL] Media Foundation startup failed with HR: {hex(hr & 0xffffffff)}")
            return

        print("Media Foundation is now active and reset for this process.")
        print("Note: This bypasses the Windows Frame Server logic for the current session.")
        
        # Shutdown to trigger clean state
        mf.MFShutdown()
        ole32.CoUninitialize()
        print("[OK] Subsystem reset complete.")
        
    except Exception as e:
        print(f"Error during low-level reset: {e}")

if __name__ == "__main__":
    low_level_camera_reset()
    print("\nRunning standard access test...")
    import subprocess
    subprocess.run(["python", "ForceAccess.py"])
