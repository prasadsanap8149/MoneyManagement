# Minimal ProGuard rules for release build compatibility
# Only essential rules to prevent build failures

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Android classes
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep app classes
-keep class com.prasadSanap.secure_money_management.** { *; }

# Keep Google Play Services and Firebase
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Fix for missing Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Fix for missing OkHttp classes
-dontwarn com.squareup.okhttp.**
-dontwarn okio.**

# Fix for missing reflection classes  
-dontwarn java.lang.reflect.AnnotatedType

# Fix for missing gRPC classes
-dontwarn io.grpc.**

# Fix for missing common classes
-dontwarn com.google.common.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Essential attributes for debugging
-keepattributes SourceFile,LineNumberTable

# Don't obfuscate (helps with debugging)
-dontobfuscate
