allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension is com.android.build.gradle.BaseExtension) {
                androidExtension.compileSdkVersion = "android-36"
                androidExtension.buildToolsVersion = "36.0.0"
                androidExtension.ndkVersion = "27.3.13750724"
                if (androidExtension.namespace == null) {
                    androidExtension.namespace = project.group.toString()
                }
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

subprojects {
    plugins.withId("com.android.library") {
        val extension = extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (extension != null) {
            if (extension.namespace == null) {
                extension.namespace = project.group.toString()
            }
        }
    }
}