plugins {
    id("com.android.application")
    id("kotlin-android") 
    id("dev.flutter.flutter-gradle-plugin") 
}
apply(plugin = "com.google.gms.google-services")
android { 
    namespace = "com.services.huystore"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {  
        applicationId = "com.services.huystore" 
        minSdkVersion(24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
dependencies {
    implementation("androidx.core:core-ktx:1.10.1") 
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") 
}

flutter {
    source = "../.."
}
