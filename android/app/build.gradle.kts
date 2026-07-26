import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from `android/key.properties`, which is git-ignored.
// When that file is absent (fresh clone, CI without secrets) the build falls
// back to the debug keystore so `flutter build apk --release` still succeeds —
// it just produces an artifact that cannot be uploaded to Play.
// See README.md → "Building a release".
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // Must stay in sync with `applicationId` below — see the note there.
    namespace = "com.app.wordquest"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // This is the app's permanent identity on Google Play and CANNOT be
        // changed after the first release — a different value is a different
        // app, with no upgrade path for existing installs.
        //
        // It also seeds the authority of every ContentProvider merged in by
        // libraries (androidx-startup, mobileadsinitprovider, ...). Play
        // rejects an upload whose authorities collide with another developer's
        // app, so this value must be one you actually own.
        applicationId = "com.app.wordquest"

        // google_mobile_ads 5.x requires API 23+.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Code shrinking / obfuscation is deliberately OFF.
            //
            // R8 is what usually breaks a release build in ways debug never
            // shows (stripped reflection targets in the ads SDK, missing
            // Play Core classes), so the release artifact here is byte-for-byte
            // predictable. The trade-off is a larger download.
            //
            // To turn it back on later: flip both flags to `true` — the rules
            // in proguard-rules.pro are already written and kept up to date.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }

        debug {
            // Lets a debug build sit alongside a release build on one device.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
}

flutter {
    source = "../.."
}
