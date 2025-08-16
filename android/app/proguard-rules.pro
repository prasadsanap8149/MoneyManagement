# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
-renamesourcefileattribute SourceFile

# Keep Flutter and Dart classes
-keep class io.flutter.** { *; }
-keep class androidx.** { *; }

# Keep all model classes for serialization/deserialization
-keep class com.prasadSanap.secure_money_management.** { *; }

# Keep classes with JSON serialization - specifically for TransactionModel
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep all classes that might be used for JSON serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all public and private methods in model classes that might be used for reflection
-keepclassmembers class * {
    public <methods>;
    private <methods>;
}

# Keep SharedPreferences related classes
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$** { *; }

# Keep classes used for encryption/decryption
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Kotlin metadata for proper serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,RuntimeVisibleTypeAnnotations

# Keep names for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Firebase specific rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# R8 specific rules to fix missing classes
# Don't warn about Google Play Core classes (we don't use them directly)
-dontwarn com.google.android.play.core.**

# Fix for OkHttp classes
-dontwarn com.squareup.okhttp.**
-dontwarn okio.**

# Fix for Java reflection classes
-dontwarn java.lang.reflect.**
-dontwarn java.lang.reflect.AnnotatedType

# Fix for gRPC classes
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# Fix for Google Common classes
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**

# Generic Android and Google Play services rules
-keep class * extends java.util.ListResourceBundle {
    protected java.lang.Object[][] getContents();
}

-keep public class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}

-keepnames @com.google.android.gms.common.annotation.KeepName class *
-keepclassmembernames class * {
    @com.google.android.gms.common.annotation.KeepName *;
}

-keepnames class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Aggressive keep rules for critical classes
-keep class * extends java.lang.Object {
    public <fields>;
    public <methods>;
}

# Don't warn about missing classes that are platform-specific
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# Keep annotation classes
-keep class * extends java.lang.annotation.Annotation { *; }

# Disable obfuscation for critical data handling
-dontobfuscate

# Google Mobile Ads SDK
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Sometimes needed for mediation adapters
-keep class com.google.android.gms.common.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
