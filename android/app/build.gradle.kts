import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")       // ← correct Kotlin plugin id
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore if present
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.barvin.barvin.barvin"

    // Either keep Flutter’s values or hardcode; both are fine.
    // compileSdk = 35
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.2.12479018"
    compileOptions {
        // AGP 8.x runs on Java 17; compile/target on 17 to avoid toolchain warnings.
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.barvin.barvin.barvin"
        // min/target can come from Flutter; or set explicitly (21/35+).
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only create release config if key.properties exists
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if available; fall back to debug to keep CI happy
            signingConfig = if (signingConfigs.findByName("release") != null)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // Optional but recommended for Play:
            // isMinifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )

            // If you previously hit “failed to strip debug symbols”, try removing any FULL level.
            // ndk { debugSymbolLevel = "SYMBOL_TABLE" } // enable only if you plan to upload native symbols
        }
    }
}

flutter {
    source = "../.."
}