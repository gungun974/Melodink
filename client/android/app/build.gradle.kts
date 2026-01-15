plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.security.MessageDigest
import java.net.URL
import java.io.InputStream

android {
    namespace = "fr.gungun974.melodink"
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
        applicationId = "fr.gungun974.melodink"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

val buildMelodinkPlayer by
    tasks.register<Exec>("buildMelodinkPlayer") {
      workingDir = file("../../melodink_player")
      commandLine("zig", "build", "-Dtarget=arm-linux-android", "-Doptimize=ReleaseFast")
      isIgnoreExitValue = false
      doFirst { println("Running: zig build -Dtarget=arm-linux-android -Doptimize=ReleaseFast") }
    }

val downloadSqlite3Libraries by
    tasks.register("downloadSqlite3Libraries") {
      val sqlite3Version = "3.1.3"
      val baseUrl = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite3Version"

      val libraries = mapOf(
        "armeabi-v7a" to mapOf(
          "file" to "libsqlite3.arm.android.so",
          "hash" to "1c5a8a32d83ddfd24c0301e9b02ed3ccb6526210b26543077f43f7821d83c53b"
        ),
        "arm64-v8a" to mapOf(
          "file" to "libsqlite3.arm64.android.so",
          "hash" to "a668d1e737597845655ab5a2fe8acee4ef286f08bb642988b7ab1ff183511171"
        ),
        "x86" to mapOf(
          "file" to "libsqlite3.ia32.android.so",
          "hash" to "4a7e25ba694ecb29317eb927eb2426370588c60127df4cc566f0327604c78386"
        ),
        "x86_64" to mapOf(
          "file" to "libsqlite3.x64.android.so",
          "hash" to "94bad470dad73ebd8bb205b2d773babe0a6189617d5385461377de28a68c9922"
        )
      )

      doLast {
        libraries.forEach { (arch, info) ->
          val fileName = info["file"] as String
          val expectedHash = info["hash"] as String
          val archDir = file("src/main/jniLibs/$arch")
          val outputFile = file("$archDir/libsqlite3.so")

          archDir.mkdirs()

          // Check if file exists and has correct hash
          if (outputFile.exists()) {
            val existingHash = MessageDigest.getInstance("SHA-256")
              .digest(outputFile.readBytes())
              .joinToString("") { byte -> "%02x".format(byte) }

            if (existingHash == expectedHash) {
              println("SQLite3 library for $arch already exists with correct hash")
              return@forEach
            } else {
              println("SQLite3 library for $arch has incorrect hash, re-downloading...")
            }
          }

          // Download the file
          val url = URL("$baseUrl/$fileName")
          println("Downloading $fileName for $arch...")

          url.openStream().use { input: InputStream ->
            outputFile.outputStream().use { output ->
              input.copyTo(output)
            }
          }

          // Verify hash
          val actualHash = MessageDigest.getInstance("SHA-256")
            .digest(outputFile.readBytes())
            .joinToString("") { byte -> "%02x".format(byte) }

          if (actualHash != expectedHash) {
            outputFile.delete()
            throw GradleException("Hash mismatch for $fileName: expected $expectedHash but got $actualHash")
          }

          println("Successfully downloaded and verified $fileName for $arch")
        }
      }
    }

tasks.configureEach {
  if (name == "assembleDebug" || name == "assembleRelease") {
    dependsOn(buildMelodinkPlayer)
    dependsOn(downloadSqlite3Libraries)
  }
}
