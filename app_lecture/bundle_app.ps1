$bundleDir = "build/windows/bundle"
$binDir = "build/windows/x64/runner/Release"
$flutterDir = "windows/flutter/ephemeral"
$pluginsDir = "build/windows/x64/plugins"

# Create directories
if (!(Test-Path $bundleDir)) { New-Item -ItemType Directory -Path $bundleDir }
if (!(Test-Path "$bundleDir/data")) { New-Item -ItemType Directory -Path "$bundleDir/data" }

Write-Host "--- Bundling App ---"

# 1. Main Executable
Copy-Item "$binDir/app_lecture.exe" "$bundleDir/"

# 2. Flutter Engine & ICU
Copy-Item "$flutterDir/flutter_windows.dll" "$bundleDir/"
Copy-Item "$flutterDir/icudtl.dat" "$bundleDir/data/"

# 3. Plugins DLLs
# Audioplayers
Copy-Item "$pluginsDir/audioplayers_windows/Release/audioplayers_windows_plugin.dll" "$bundleDir/" 
# Flutter TTS
Copy-Item "$pluginsDir/flutter_tts/Release/flutter_tts_plugin.dll" "$bundleDir/"
# Permission Handler
Copy-Item "$pluginsDir/permission_handler_windows/Release/permission_handler_windows_plugin.dll" "$bundleDir/"
# Speech to Text
Copy-Item "$pluginsDir/speech_to_text_windows/Release/speech_to_text_windows_plugin.dll" "$bundleDir/"
# Vosk
Copy-Item "$pluginsDir/vosk_flutter/Release/vosk_flutter_plugin.dll" "$bundleDir/"
# Vosk Extra Dependencies
$voskLibs = "$flutterDir/.plugin_symlinks/vosk_flutter/windows/libs"
Copy-Item "$voskLibs/libvosk.dll" "$bundleDir/"
Copy-Item "$voskLibs/libgcc_s_seh-1.dll" "$bundleDir/"
Copy-Item "$voskLibs/libstdc++-6.dll" "$bundleDir/"
Copy-Item "$voskLibs/libwinpthread-1.dll" "$bundleDir/"

# 4. Assets (flutter_assets)
$assetsSrc = "$binDir/data/flutter_assets"
if (Test-Path $assetsSrc) {
    Copy-Item -Recurse -Force $assetsSrc "$bundleDir/data/"
} else {
    Write-Host "⚠️ Warning: Assets not found at $assetsSrc"
}

# 5. Kernel (app.so)
$kernelSrc = "$binDir/data/app.so"
if (Test-Path $kernelSrc) {
    Copy-Item $kernelSrc "$bundleDir/data/"
} else {
    # Check fallback location from previous scripts
    if (Test-Path "build/windows/app.so") {
        Copy-Item "build/windows/app.so" "$bundleDir/data/"
    }
}

Write-Host "Bundle created at $bundleDir"
