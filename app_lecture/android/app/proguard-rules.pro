# ─────────────────────────────────────────────────────────────────────────────
# JNA (Java Native Access) — utilisé par vosk_flutter
# CRITIQUE : R8 supprime/renomme les champs natifs (peer, etc.) ce qui cause
# un UnsatisfiedLinkError au runtime en mode release.
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.sun.jna.** { *; }
-keepclassmembers class com.sun.jna.** { *; }
-keepattributes *Annotation*
-dontwarn com.sun.jna.**

# ─────────────────────────────────────────────────────────────────────────────
# Vosk (vosk_flutter) — bibliothèque de reconnaissance vocale offline
# ─────────────────────────────────────────────────────────────────────────────
-keep class org.vosk.** { *; }
-keepclassmembers class org.vosk.** { *; }
-dontwarn org.vosk.**

# ─────────────────────────────────────────────────────────────────────────────
# Hive — base de données locale (utilise la réflexion pour les adapters)
# ─────────────────────────────────────────────────────────────────────────────
-keep class * extends com.google.flatbuffers.Table { *; }
-keep class io.hive.** { *; }
-keep class ** implements io.flutter.plugin.common.PluginRegistry { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Flutter TTS — Android TextToSpeech bridge
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# ─────────────────────────────────────────────────────────────────────────────
# speech_to_text — Android SpeechRecognizer bridge
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# ─────────────────────────────────────────────────────────────────────────────
# audioplayers — lecteur audio
# ─────────────────────────────────────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# ─────────────────────────────────────────────────────────────────────────────
# permission_handler
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ─────────────────────────────────────────────────────────────────────────────
# Flutter engine — ne jamais minifier les classes internes Flutter
# ─────────────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
