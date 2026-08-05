plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cashark.cashark"
    compileSdk = 35
    ndkVersion = "26.1.10909125"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.cashark.cashark"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 64-bit only — required for modern store distribution
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    packaging {
        jniLibs {
            // Prefer uncompressed native libs for 16KB page-size devices (Android 15+)
            useLegacyPackaging = false
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
