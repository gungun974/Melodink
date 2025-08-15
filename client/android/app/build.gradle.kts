plugins {
  id("com.android.application")
  id("kotlin-android")
  // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
  id("dev.flutter.flutter-gradle-plugin")
}

android {
  namespace = "fr.gungun974.melodink"
  compileSdk = flutter.compileSdkVersion
  ndkVersion = "27.0.12077973"

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
  }

  kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

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

flutter { source = "../.." }

val buildMelodinkPlayer by
    tasks.register<Exec>("buildMelodinkPlayer") {
      workingDir = file("../../melodink_player")
      commandLine("zig", "build", "-Dtarget=arm-linux-android", "-Doptimize=ReleaseFast")
      isIgnoreExitValue = false
      doFirst { println("Running: zig build -Dtarget=arm-linux-android -Doptimize=ReleaseFast") }
    }

tasks.configureEach {
  if (name == "assembleDebug" || name == "assembleRelease") {
    dependsOn(buildMelodinkPlayer)
  }
}
