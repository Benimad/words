# R8 / ProGuard rules for release builds.
#
# Flutter and its first-party plugins ship their own consumer rules, so this
# file only needs to cover the gaps that actually bite in practice.

# --- Flutter engine ---------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# --- Google Mobile Ads ------------------------------------------------------
# The SDK reflects over these when loading mediation adapters.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# --- Play Core / deferred components ---------------------------------------
# Flutter references these classes even when split install is unused; without
# the -dontwarn, R8 fails the build on a missing-class error.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# --- Kotlin / coroutines ----------------------------------------------------
-dontwarn kotlin.**
-dontwarn kotlinx.**

# --- Keep annotations used for reflection ----------------------------------
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# --- Useful stack traces in Play Console crash reports ---------------------
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
