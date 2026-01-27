# Excalibur G870 Low-Level Camera Fix (Super Reset)
# This script is written without Turkish characters to avoid encoding issues.

function Write-Host-Color($text, $color) {
    Write-Host $text -ForegroundColor $color
}

Write-Host-Color "=== Excalibur G870 Aggressive Camera Fix ===" "Cyan"

# 1. Stop and Disable Windows Camera Frame Server
Write-Host-Color "[1/4] Stopping Windows Camera Frame Server..." "Yellow"
Stop-Service -Name "FrameServer" -Force -ErrorAction SilentlyContinue
Set-Service -Name "FrameServer" -StartupType Disabled -ErrorAction SilentlyContinue

# Stop Capability Access Manager Service (Handles privacy/access)
Stop-Service -Name "CapabilityAccessManagerService" -Force -ErrorAction SilentlyContinue

# 2. Reset Camera Device
Write-Host-Color "[2/4] Resetting Camera device states..." "Yellow"
# Query Camera and Image classes separately to avoid ObjectNotFound errors
$devs = @()
try { $devs += Get-PnpDevice -Class Camera -ErrorAction SilentlyContinue } catch {}
try { $devs += Get-PnpDevice -Class Image -ErrorAction SilentlyContinue } catch {}

$camera = $devs | Where-Object { $_.FriendlyName -like "*Webcam*" -or $_.FriendlyName -like "*Camera*" }

if ($camera) {
    foreach ($dev in $camera) {
        Write-Host "Resetting: $($dev.FriendlyName)"
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host-Color "Device $($dev.FriendlyName) has been re-enabled." "Green"
    }
} else {
    Write-Host-Color "WARNING: No camera device found in PnP classes." "Red"
}

# 3. Intel IPU (Image Processing Unit) and Control Logic Reset
Write-Host-Color "[3/4] Checking Intel Image Processing Unit..." "Yellow"
$ipuDevs = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Intel*IPU*" -or $_.FriendlyName -like "*Control Logic*" -or $_.FriendlyName -like "*CSI2*" }
if ($ipuDevs) {
    foreach ($i in $ipuDevs) {
        Write-Host "Resetting IPU component: $($i.FriendlyName)"
        Disable-PnpDevice -InstanceId $i.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Enable-PnpDevice -InstanceId $i.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "IPU component not found, skipping..."
}

# 4. Low-Level Registry Enforcement (Direct Hardware Access)
Write-Host-Color "[4/4] Removing hardware restrictions in Registry..." "Yellow"
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\Platform",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Media Foundation\Platform"
)
foreach ($path in $regPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    # EnableFrameServerMode = 0 forces apps to use DirectShow/Direct access bypass
    Set-ItemProperty -Path $path -Name "EnableFrameServerMode" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name "EnableAutoRotation" -Value 0 -ErrorAction SilentlyContinue
}

# 5. Clear Media Foundation Cache
$cachePath = "$env:LOCALAPPDATA\Microsoft\Windows\WebcamCache"
if (Test-Path $cachePath) {
    Remove-Item -Path "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host-Color "Webcam cache cleared." "Green"
}

Write-Host-Color "`nOPERATION COMPLETED!" "Green"
Write-Host "------------------------------------------"
Write-Host "Instructions:"
Write-Host "1. Close Discord and all camera apps completely."
Write-Host "2. Press Fn + F10 to cycle the hardware privacy switch."
Write-Host "3. IMPORTANT: RESTART your computer now."
Write-Host "   The Frame Server disable only takes full effect after a reboot."
Write-Host "------------------------------------------"
