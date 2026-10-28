import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// Build tool versions are owned by the consuming Flutter application.
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://jitpack.io")
            content { includeGroup("com.github.tiktok") }
        }
    }
}

apply(plugin = "com.android.library")

val agpVersion: String = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION
val builtInKotlin = providers.gradleProperty("android.builtInKotlin")
    .map(String::toBoolean).getOrElse(true)
if (agpVersion.split(".")[0].toInt() < 9 || !builtInKotlin) {
    apply(plugin = "kotlin-android")
}

configure<LibraryExtension> {
    namespace = "com.example.tiktok_events_sdk"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()

            it.outputs.upToDateWhen { false }
            it.testLogging {
                events("passed", "skipped", "failed", "standardOut", "standardError")
                showStandardStreams = true
            }
        }
    }
}

tasks.withType<KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    "implementation"("com.github.tiktok:tiktok-business-android-sdk:1.7.1")
    "implementation"("androidx.lifecycle:lifecycle-process:2.10.0")
    "testImplementation"("org.jetbrains.kotlin:kotlin-test")
    "testImplementation"("org.mockito:mockito-core:5.23.0")
}
