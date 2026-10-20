# Flutter wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve signatures and annotations for JNI/reflection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,MethodParameters

# Pigeon JNI and Kotlin Coroutine rules (prevents R8 from mangling Continuation signatures)
-keep class kotlin.Unit { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.** { *; }
-keep interface kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }

# SharedPreferences plugin and Pigeon JNI interfaces
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesAsyncApiRegistrar { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesApiRegistrar { *; }
-keep interface io.flutter.plugins.sharedpreferences.** { *; }

# Path Provider plugin
-keep class io.flutter.plugins.pathprovider.** { *; }

# Suppress warnings for optional Play Store split install classes referenced by Flutter engine
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

