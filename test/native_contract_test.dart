import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native SDKs pin latest verified official stable releases exactly', () {
    expect(
      File('ios/tiktok_events_sdk.podspec').readAsStringSync(),
      contains("s.dependency 'TikTokBusinessSDK', '1.7.2'"),
    );
    expect(
      File('ios/tiktok_events_sdk/Package.swift').readAsStringSync(),
      contains('exact: "1.7.2"'),
    );
    expect(
      File('android/build.gradle.kts').readAsStringSync(),
      contains('tiktok-business-android-sdk:1.7.1'),
    );
  });

  test('CocoaPods compiles the complete shared Swift implementation', () {
    final podspec = File('ios/tiktok_events_sdk.podspec').readAsStringSync();
    expect(
      podspec,
      contains("'tiktok_events_sdk/Sources/tiktok_events_sdk/**/*.swift'"),
    );
    final source = File(
      'ios/tiktok_events_sdk/Sources/tiktok_events_sdk/TiktokEventsSdkPlugin.swift',
    ).readAsStringSync();
    for (final method in [
      'initialize',
      'identify',
      'logout',
      'sendEvent',
      'startTrack',
      'isAlreadyInitialized',
      'setTrackingEnabled',
      'isTrackingEnabled',
      'flush',
      'updateAccessToken',
      'getIdfa',
      'setCustomUserAgent',
    ]) {
      expect(source, contains('case TikTokMethodName.$method:'));
    }
  });

  test('Android honors host Kotlin opt-out without injecting build tools', () {
    final build = File('android/build.gradle.kts').readAsStringSync();
    expect(build, contains('android.builtInKotlin'));
    expect(build, isNot(contains('classpath(')));
    expect(build, isNot(contains('ben-manes')));
  });

  test('Android explicitly maps false auto IAP selection', () {
    final source = File(
      'android/src/main/kotlin/com/example/tiktok_events_sdk/TikTokUtils.kt',
    ).readAsStringSync();
    expect(source, contains('false -> disableAutoIapTrack()'));
  });

  test('native initialization uses callbacks and rejects repeat attempts', () {
    final android = File(
      'android/src/main/kotlin/com/example/tiktok_events_sdk/TikTokMethod.kt',
    ).readAsStringSync();
    expect(android, contains('object : TikTokBusinessSdk.TTInitCallback'));
    expect(android, contains('INIT_ALREADY_ATTEMPTED'));
    expect(android, contains('"nativeCode" to nativeCode'));
    final ios = File(
      'ios/tiktok_events_sdk/Sources/tiktok_events_sdk/InitializeHandler.swift',
    ).readAsStringSync();
    expect(ios, contains('INIT_ALREADY_ATTEMPTED'));
    expect(ios, contains('guard success else'));
    expect(ios, contains('INIT_TIMEOUT'));
    expect(ios, contains('watchdog?.cancel()'));
    expect(android, contains('INIT_TIMEOUT'));
    expect(android, contains('removeCallbacks(watchdog)'));
    expect(android, contains('by lazy'));
    expect(android, contains('if (success) setIsInitialized(true)'));
    expect(ios, contains('if success && error == nil { setIsInitialized(true) }'));
  });
}
