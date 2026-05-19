make run
flutter run
Launching lib/main.dart on sdk gphone64 x86 64 in debug mode...

FAILURE: Build failed with an exception.

* Where:
Settings file '/Users/mac/Desktop/MY/Flutter_Realtime_Workspace/Flutter_Realtime_Workspace/android/settings.gradle' line: 20

* What went wrong:
Error resolving plugin [id: 'dev.flutter.flutter-plugin-loader', version: '1.0.0']
> A problem occurred configuring project ':gradle'.
   > Could not resolve all artifacts for configuration ':gradle:classpath'.
      > Failed to transform gradle-kotlin-dsl-plugins-4.5.0.jar (org.gradle.kotlin:gradle-kotlin-dsl-plugins:4.5.0) to match attributes {artifactType=jar, org.gradle.category=library, org.gradle.dependency.bundling=external, org.gradle.internal.instrumented=instrumented-and-upgraded, org.gradle.jvm.environment=standard-jvm, org.gradle.jvm.version=8, org.gradle.libraryelements=jar, org.gradle.status=release, org.gradle.usage=java-runtime, org.jetbrains.kotlin.platform.type=jvm}.
         > Execution failed for MergeInstrumentationAnalysisTransform: /Users/mac/.gradle/caches/8.10.2/transforms/5b168cec19863bb1cc821bbf36e39f10/transformed/analysis/instrumentation-dependencies.bin.
            > com.google.common.util.concurrent.UncheckedExecutionException: java.lang.IllegalStateException: Could not deserialize analysis from a file: /Users/mac/.gradle/caches/8.10.2/transforms/5b168cec19863bb1cc821bbf36e39f10/transformed/analysis/instrumentation-hierarchy.bin

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 1m 25s
Running Gradle task 'assembleDebug'...                             87.0s
Error: Gradle task assembleDebug failed with exit code 1
make: *** [run] Error 1