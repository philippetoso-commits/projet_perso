# Script de génération de fichiers audio WAV pour le testing
# Utilise l'API Windows Speech Synthesis (SAPI) native

# Configuration
$outputDir = "..\audio" # Relative to script location
$sourceFile = "source_words.md"
$format = "Wav" 

# Read words from source_words.md (Format: | word | syllable |)
if (-not (Test-Path $sourceFile)) {
    Write-Error "Fichier source introuvable: $sourceFile"
    exit 1
}

$wordsRaw = Get-Content $sourceFile -Encoding UTF8
$words = @()

foreach ($line in $wordsRaw) {
    if ($line.Trim().StartsWith("|")) {
        $parts = $line.Split("|")
        if ($parts.Length -ge 2) {
            $word = $parts[1].Trim()
            if ($word -ne "Mot" -and $word -ne "---") {
                $words += $word
            }
        }
    }
}

Write-Host "Chargé $($words.Count) mots depuis $sourceFile" -ForegroundColor Cyan

# Load Speech Assembly
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

# Configure Format: 16kHz, 16-bit, Mono (Required by Vosk)
# 16000 Hz, 16 bit, Mono = 16kHz * 16 bit * 1 channel / 8 bits = 32000 bytes/sec
# Enum value for verified 16-16-1 is 21 (Pcm16kHz16BitMono)
# See: https://learn.microsoft.com/en-us/dotnet/api/system.speech.synthesis.speechaudioformatinfo
$synth.SetOutputToDefaultAudioDevice()

# Select French Voice
$voices = $synth.GetInstalledVoices()
$frenchVoice = $voices | Where-Object { $_.VoiceInfo.Culture -like "fr-*" } | Select-Object -First 1

if ($frenchVoice) {
    $synth.SelectVoice($frenchVoice.VoiceInfo.Name)
    Write-Host "Voix sélectionnée : $($frenchVoice.VoiceInfo.Name)" -ForegroundColor Green
}
else {
    Write-Host "⚠️ Aucune voix française trouvée. Utilisation de la voix par défaut." -ForegroundColor Yellow
}

# Create Dir
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}


foreach ($word in $words) {
    if ([string]::IsNullOrWhiteSpace($word)) { continue }
    
    $cleanWord = $word.Trim()
    
    # Normalize filename: Transliterate accents (é -> e)
    # .NET normalization FormD splits chars and accents. We then regex remove non-spacing marks.
    $formD = $cleanWord.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    
    foreach ($c in $formD.ToCharArray()) {
        $cat = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($cat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    $asciiOnly = $sb.ToString().Normalize([System.Text.NormalizationForm]::FormC)

    # Sanitize remainder
    $filename = $asciiOnly -replace "[^a-zA-Z0-9]", "_"
    $filename = $filename.ToLower()
    
    $outputPath = Join-Path $outputDir "$filename.wav"
    
    Write-Host "Génération : $cleanWord -> $filename.wav"
    
    # Configure Output to File
    # We use valid WAV PCM 16kHz
    $synth.SetOutputToWaveFile($outputPath, [System.Speech.AudioFormat.SpeechAudioFormatInfo]::new(16000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono))
    
    # Speak
    $synth.Speak($cleanWord)
    
    # Reset to avoid lock?
    $synth.SetOutputToNull()
}

Write-Host "✅ Terminé ! Fichiers générés dans $outputDir" -ForegroundColor Cyan
