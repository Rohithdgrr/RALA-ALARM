# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class com.example.alarm_app.** { *; }

# Keep audioplayers
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# Keep notification plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep provider
-keep class provider.** { *; }
-dontwarn provider.**

# Keep Google Play Core classes (required for deferred components)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Keep timezone data
-keep class org.threeten.** { *; }
-dontwarn org.threeten.**

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
