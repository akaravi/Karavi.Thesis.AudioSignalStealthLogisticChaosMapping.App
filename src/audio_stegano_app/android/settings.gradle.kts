pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://repo.huaweicloud.com/repository/maven/") }
        maven {
            val storageBase =
                System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
            url = uri("$storageBase/download.flutter.io/")
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://repo.huaweicloud.com/repository/maven/") }
        val storageBase =
            System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
        maven { url = uri("$storageBase/download.flutter.io/maven2/") }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io/") }
    }
}

include(":app")

// After global init scripts (e.g. Aliyun mirrors), ensure Flutter engine Maven is reachable.
gradle.settingsEvaluated {
    dependencyResolutionManagement {
        repositories {
            val storageBase =
                System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
            maven { url = uri("$storageBase/download.flutter.io/maven2/") }
            maven { url = uri("https://storage.googleapis.com/download.flutter.io/") }
        }
    }
}
