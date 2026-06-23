# Flutter ProGuard Rules

# Keep Flutter embedding classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep database helper / sqflite classes if any
-keep class com.tekartik.sqflite.** { *; }

# Suppress ProGuard warnings
-dontwarn io.flutter.embedding.**
