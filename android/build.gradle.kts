allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some plugins (e.g. video_thumbnail) hardcode an older compileSdk that is
// below what their transitive AndroidX dependencies require. Force any such
// subproject to compile against a newer SDK to keep the build green.
// Registered before evaluationDependsOn so the hook is attached before the
// subproject is evaluated.
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.getByName("android")
                as com.android.build.gradle.BaseExtension
            val currentCompileSdk = androidExtension.compileSdkVersion
                ?.substringAfter("android-")
                ?.toIntOrNull()
            if (currentCompileSdk == null || currentCompileSdk < 34) {
                androidExtension.compileSdkVersion(36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
