plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 从环境变量读取签名配置
fun getEnvOrProperty(name: String): String? {
    return System.getenv(name) ?: project.findProperty(name) as String?
}

android {
    namespace = "run.daodao.chatmcp"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // 签名配置
    signingConfigs {
        create("release") {
            keyAlias = getEnvOrProperty("SIGNING_KEY_ALIAS")
            keyPassword = getEnvOrProperty("SIGNING_KEY_PASSWORD")
            storeFile = getEnvOrProperty("SIGNING_STORE_PATH")?.let { file(it) }
            storePassword = getEnvOrProperty("SIGNING_STORE_PASSWORD")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "run.daodao.chatmcp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk = flutter.minSdkVersion
        minSdkVersion(24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 使用release签名配置，如果配置不完整则回退到debug签名
            val releaseSigningConfig = signingConfigs.getByName("release")
            signingConfig = if (releaseSigningConfig.storeFile != null &&
                                releaseSigningConfig.keyAlias != null &&
                                releaseSigningConfig.keyPassword != null &&
                                releaseSigningConfig.storePassword != null) {
                releaseSigningConfig
            } else {
                println("Warning: Release signing config is incomplete, using debug signing")
                signingConfigs.getByName("debug")
            }
            
            // 开启代码压缩和混淆
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}
