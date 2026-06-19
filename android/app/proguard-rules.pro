# Flutter / Play Core
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Mantém nomes usados por reflexão em (de)serialização
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
