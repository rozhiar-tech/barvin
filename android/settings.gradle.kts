pluginManagement {
    val flutterSdkPath: String =
        System.getenv("FLUTTER_ROOT")
            ?: System.getenv("FLUTTER_SDK")
            ?: run {
                val properties = java.util.Properties()
                val localProperties = file("local.properties")
                if (localProperties.exists()) {
                    localProperties.inputStream().use { properties.load(it) }
                    properties.getProperty("flutter.sdk")
                } else {
                    null
                }
            }
            ?: error(
                "Flutter SDK path not found. Define FLUTTER_ROOT/FLUTTER_SDK or set flutter.sdk in android/local.properties."
            )

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
