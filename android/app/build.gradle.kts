import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.srhdp.markdown_reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.srhdp.markdown_reader"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyFileProp = keystoreProperties.getProperty("storeFile")
            if (!keyFileProp.isNullOrBlank()) {
                val f = file(keyFileProp)
                storeFile = if (f.isAbsolute) {
                    f
                } else if (f.exists()) {
                    f
                } else if (rootProject.file(keyFileProp).exists()) {
                    rootProject.file(keyFileProp)
                } else {
                    rootProject.file("../$keyFileProp")
                }
            }
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            val hasValidKeystore = keystorePropertiesFile.exists() &&
                releaseSigning.storeFile?.exists() == true &&
                !releaseSigning.storePassword.isNullOrBlank()

            signingConfig = if (hasValidKeystore) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
