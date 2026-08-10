# Flutter engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Play Core classes are only referenced by Flutter's deferred-components support,
# which this app doesn't use. Without this, R8 fails the build with
# "Missing classes detected while running R8" for com.google.android.play.core.*.
-dontwarn com.google.android.play.core.**
