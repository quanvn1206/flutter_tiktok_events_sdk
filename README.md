# TikTok Events SDK Flutter Plugin

## Fork integration fixes and limitations

This fork shares the complete SwiftPM Swift implementation with CocoaPods and
pins both iOS dependency managers to native 1.7.2. Android uses native 1.7.1;
build tool versions come from the host app. For AGP 9 hosts opting out of built-in
Kotlin, `android.builtInKotlin=false` applies the host Kotlin Android plugin. Hosts
must make JitPack available for group `com.github.tiktok`.

Initialization now reports native callback success/failure, completes Flutter
results on the main thread and rejects further process initialization attempts
with `INIT_ALREADY_ATTEMPTED`, including after failure. This intentionally avoids
retrying partially initialized native state; restart the process for a new attempt.
A missing native callback completes with `INIT_TIMEOUT` after 15 seconds. Timeout
only bounds the Flutter wait: native work may continue and retry remains blocked.

`enableAutoIapTrack=false` now calls native `disableAutoIapTrack()`. **This is not a
privacy guarantee.** Inspected official native purchase paths permit remote
configuration to control collection; iOS payment tracking may likewise override
the client preference. Runtime send switches are not durable consent boundaries.
Do not initialize this SDK where purchase/EDP collection is forbidden without
separately validating native collection vetoes, consent/revocation and device
traffic. Linking a dependency is not proof of network silence.

Regression checks in `test/native_contract_test.dart` verify source/build wiring,
not native execution or privacy behavior. Native build and device validation are
still required before deployment. The legacy `ios/Classes` tree is unused by both
build paths; the shared source lives under `ios/tiktok_events_sdk/Sources`.

[![pub package](https://img.shields.io/pub/v/tiktok_events_sdk.svg)](https://pub.dev/packages/tiktok_events_sdk)

A Flutter plugin for integrating the **TikTok Events SDK** into your Flutter app. This plugin allows you to track in-app events, measure user engagement, and optimize your TikTok ad campaigns. It supports both **Android** and **iOS** platforms.

Learn more about TikTok Events SDK:

- [TikTok Events Manager Overview](https://business-api.tiktok.com/portal/docs?id=1739585434183746)
- [TikTok Events SDK for iOS](https://business-api.tiktok.com/portal/docs?id=1739585432134657)
- [TikTok Events SDK for Android](https://business-api.tiktok.com/portal/docs?id=1739585432134658)

---

# TikTok Events SDK for Flutter

A **Flutter** plugin that integrates the [TikTok Events SDK](https://ads.tiktok.com/marketing_api/docs?rid=a0ovbtrvukp&id=1737172325924866) to help you easily initialize the TikTok SDK, identify users, log events, and handle user logout. This plugin supports both **Android** and **iOS**.

---

## Requirements

> **Flutter `>=3.38.0` and Dart `^3.10.0` required.** Starting from `1.2.0` the iOS plugin is migrated to the new `UIScene` lifecycle introduced in Flutter 3.38. If you cannot upgrade Flutter yet, pin to `1.1.5`.

### Android

Have to added the normal permission `com.google.android.gms.permission.AD_ID` to the SDK's AndroidManifest, to allow the SDK to collect the Android Advertising ID on apps targeting API 33.
If your app is targeting children, you need to revoke this permission to comply with Google's Data policy.

Add the Internet and AD_ID permissions to your AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="com.google.android.gms.permission.AD_ID" />
```

Make sure you are using the latest version of Play Services and Gradle that support com.google.android.gms.permission.AD_ID.

⚠️ If your app targets children, revoke this permission to comply with Google’s data policy.

#### Add JitPack Repository

To ensure proper dependency resolution, add JitPack to your project's settings.gradle or build.gradle file.

For projects using settings.gradle (Recommended)
In your android/settings.gradle, add the following inside dependencyResolutionManagement → repositories:

```gradle
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
    maven { url 'https://jitpack.io' } // Add JitPack repository
  }
}
```

For older projects using build.gradle
If your project uses build.gradle (Project-level) instead of settings.gradle, add the JitPack repository inside the allprojects.repositories block:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }  // Add JitPack repository
    }
}
```

### iOS

iOS (App Tracking Transparency in iOS 14+)
Starting from iOS 14, App Tracking Transparency (ATT) permission is required to share IDFA (Identifier for Advertisers) with TikTok. If the user does not grant permission, the IDFA will be zeroed out, which may affect attribution and retargeting audience building.

📌 How to enable ATT on iOS?
1️⃣ Add the NSUserTrackingUsageDescription key to Info.plist:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Your app uses IDFA to improve ad personalization.</string>
```

## Features

- **Log Events**: Track user actions such as purchases, add-to-cart, content views, and more for deeper insights into user behavior.
- **Identify user**: Easily associate events with specific users through custom identifiers and parameters.
- **Debug Mode**: Test your event tracking before releasing your app.
- **Logout**: Effortlessly clear user identification across both Android and iOS.
- **Runtime send preference**: `setTrackingEnabled` is not a durable consent or collection boundary; remote configuration may override it.
- **Manual flush**: Force-flush pending events with `flush()` before the app backgrounds or terminates.
- **Access token rotation**: Update the access token at runtime with `updateAccessToken` — no re-initialization needed.
- **Limited Data Use (LDU)**: Enable LDU mode at init to restrict data collection in privacy-sensitive jurisdictions.

---

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  tiktok_events_sdk: ^1.3.0
```

## Usage

### Initialize the SDK

You must initialize the SDK with your TikTok configuration details. This can be done in main.dart or wherever you set up your app:

```dart
// iOS options example
final iosOptions = TikTokIosOptions(
  disableTracking: false, // true would disable ALL tracking
  disableAutomaticTracking: true,
  disableSKAdNetworkSupport: true,
);

// Android options example
final androidOptions = TikTokAndroidOptions(
  enableAutoIapTrack: true, // purchase collection permitted by app policy only
  disableAdvertiserIDCollection: false,
);

// Pass these options to the initialize method
await TikTokEventsSdk.initSdk(
  androidAppId: 'YOUR_ANDROID_APP_ID',
  tikTokAndroidId: 'YOUR_TIKTOK_ANDROID_ID',
  iosAppId: 'YOUR_IOS_APP_ID',
  tiktokIosId: 'YOUR_TIKTOK_IOS_ID',
  isDebugMode: true,
  logLevel: TikTokLogLevel.debug,
  androidOptions: androidOptions,
  iosOptions: iosOptions,
);
```

> **Warning:** `disableAutoStart` defers a native send path only. Configuration traffic and collection may still occur; do not initialize before consent or treat this flag as a privacy boundary.

#### Deferred start (manual consent flow)

This only defers a native send path, not collection or configuration requests. Initialize only after consent; this is not a pre-consent integration pattern.

```dart
final androidOptions = TikTokAndroidOptions(
  disableAutoStart: true, // SDK will NOT track until startTrack() is called
);

await TikTokEventsSdk.initSdk(
  // ...same as above
  androidOptions: androidOptions,
);

// Later, after the user grants consent:
await TikTokEventsSdk.startTrack();
```

### In-App Purchase (IAP)

Only enable IAP when purchase collection is permitted by app policy. False sends a disable preference, not a durable veto against remote configuration. If IAP is enabled, add the following dependency to android/app/build.gradle:

```gradle
dependencies {
    implementation 'com.android.billingclient:billing:6.1.0'
}
```

This is required for automatic IAP event reporting to work properly.

### Identify a User

If you need to associate events with a specific user, call identify:

```
await TikTokEventsSdk.identify(
  identifier: TikTokIdentifier(
    externalId: '12345',
    externalUserName: 'john_doe',
    phoneNumber: '+1234567890',
    email: 'john.doe@example.com',
  ),
);
```

### Log Events

The TikTok SDK allows you to log both **custom** and **predefined** events to track user actions within your app. You can add optional metadata such as `eventId` and `properties` to give more context about the event.

**Basic Example:**

```dart
import 'package:tiktok_events_sdk/tiktok_events_sdk.dart';

/// Log a custom event with only a name
await TikTokEventsSdk.logEvent(
  event: TikTokEvent(
    eventName: 'custom_event_name',
  ),
);
```

#### Passing Additional properties

To enrich your events with extra data (like pricing, product names, user attributes, etc.), you can pass properties. First, create an EventProperties object with key/value pairs of your choice:

```dart
const event = EventProperties(
  value: 200,
  description: 'product price',
  contentId: 'product_page',
  quantity: 1,
  contentType: '',
);
```

```dart
import 'package:tiktok_events_sdk/tiktok_events_sdk.dart';

await TikTokEventsSdk.logEvent(
      event: TikTokEvent(
        eventName: 'click_product_card',
        eventId: 'event_id',
        properties: const EventProperties(
          contentId: '12345',
          brand: 'Brand Name',
          contentName: 'Category',
          value: 100.0,
          customProperties: {
            'custom_key': 'custom_value',
          },
        ),
      ),
    );
```

### Runtime Tracking Controls

Runtime tracking switches are send preferences, not durable consent boundaries. Collection may continue and remote configuration may override them.

```dart
// User opts out — stop sending events.
await TikTokEventsSdk.setTrackingEnabled(enabled: false);

// User opts back in — resume tracking.
await TikTokEventsSdk.setTrackingEnabled(enabled: true);

// Read current state.
final isEnabled = await TikTokEventsSdk.isTrackingEnabled();
```

On iOS this maps to `TikTokBusiness.setTrackingEnabled`. On Android it maps to `TikTokBusinessSdk.setSdkGlobalSwitch`.

### Manual Flush

Force any queued events to be sent immediately — useful before backgrounding or terminating the app:

```dart
await TikTokEventsSdk.flush();
```

Maps to `TikTokBusiness.explicitlyFlush()` on iOS and `TikTokBusinessSdk.flush()` on Android.

### Update Access Token

Rotate the access token without re-initializing the SDK:

```dart
await TikTokEventsSdk.updateAccessToken(accessToken: 'NEW_ACCESS_TOKEN');
```

### Advanced Initialization Options

Both `TikTokAndroidOptions` and `TikTokIosOptions` expose additional native SDK knobs for fine-tuning behavior.

**Cross-platform (Android + iOS):**

- `disableAutoEnhancedDataPostbackEvent` — opt out of Auto Enhanced Data Postback (EDP) collection.
- `isLowPerformanceDevice` — tell the SDK to skip non-essential background work on lower-end devices.

**Android-only:**

- `flushTimeIntervalSeconds` — change the flush interval (defaults to the SDK's own 15s).

**iOS-only:**

- `initialFlushDelaySeconds` — initial delay before the first flush.
- `attUserAuthorizationDelaySeconds` — delay (in seconds) before the SDK requests ATT permission.
- `customUserAgent` — custom User-Agent for SDK network requests.

```dart
final androidOptions = TikTokAndroidOptions(
  disableAutoEnhancedDataPostbackEvent: true,
  isLowPerformanceDevice: false,
  flushTimeIntervalSeconds: 30,
);

final iosOptions = TikTokIosOptions(
  disableAutoEnhancedDataPostbackEvent: true,
  isLowPerformanceDevice: false,
  initialFlushDelaySeconds: 5,
  attUserAuthorizationDelaySeconds: 10,
  customUserAgent: 'MyApp/1.0',
);
```

### iOS-only Runtime Helpers

These two helpers exist because they have no direct counterpart in the Android SDK. On Android the calls are silently no-op (or return `null`) so your shared Dart code can call them without platform branching.

```dart
// Read the device IDFA (iOS only). Returns null on Android, or on iOS when
// the user has not granted ATT permission.
final idfa = await TikTokEventsSdk.getIdfa();

// Override the SDK's User-Agent at runtime (iOS only).
await TikTokEventsSdk.setCustomUserAgent(userAgent: 'MyApp/1.0');
```

### Limited Data Use (LDU)

For users in privacy-sensitive jurisdictions (e.g., California under CCPA, or the EU under GDPR), enable LDU at init to restrict how TikTok processes the collected data:

```dart
final androidOptions = TikTokAndroidOptions(
  enableLimitedDataUse: true,
);

final iosOptions = TikTokIosOptions(
  enableLDUMode: true,
);

await TikTokEventsSdk.initSdk(
  // ...your IDs
  androidOptions: androidOptions,
  iosOptions: iosOptions,
);
```

### Logout User

When a user logs out of your app, you can clear the identification data:

```dart
await TikTokEventsSdk.logout();
```

## Troubleshooting

Events not showing up in the TikTok Events Manager? Before opening an issue, check the four most common causes below — they account for the vast majority of "events are not arriving" reports.

### 1. You're testing on the iOS Simulator

The TikTok Business SDK does **not** send events from the iOS Simulator. The simulator has no IDFA, no valid device fingerprint, and no SKAdNetwork support, so the native SDK silently drops the events.

**Fix:** Always test on a physical iOS device. The Android emulator works for basic testing, but real devices are still recommended.

### 2. You're looking at the wrong tab in the dashboard

When you initialize the SDK with `isDebugMode: true`, events are sent to the **Test Event** tab of the TikTok Ads Manager, **not** to the **Event Activity** tab.

**Fix:** In the TikTok Ads Manager, go to **Tools → Events**, open your app, and switch to the **Test event** tab (shown below). If you want events to appear in **Event Activity** instead, set `isDebugMode: false` in a release build.

![TikTok Ads Manager — Test event tab](doc/images/tiktok-test-events-tab.png)

### 3. Your app is still pending verification on TikTok

If your app has not been verified yet on the TikTok Events platform, only **Test Events** will work. The **Event Activity** tab stays empty until verification is complete.

**Fix:** Complete the app verification process in the TikTok Business Center, then test again with `isDebugMode: false` on a physical device.

### 4. You set `disableAutoStart: true` but never call `startTrack()`

On Android, `disableAutoStart` controls a send path, not all collection or configuration traffic. It is not a reliable consent boundary.

**Fix:** Either remove `disableAutoStart: true` from your `TikTokAndroidOptions` (the SDK then starts automatically), or call `await TikTokEventsSdk.startTrack()` once the user has granted consent. See the [Deferred start](#deferred-start-manual-consent-flow) section above.

### Still not working?

If you've checked all four above and events are still missing:

- Confirm your `androidAppId`, `tikTokAndroidId`, `iosAppId` and `tiktokIosId` match exactly what is shown in the TikTok Events Manager (no extra whitespace).
- Set `logLevel: TikTokLogLevel.debug` and `isDebugMode: true` and look for native log lines tagged `TikTokBusinessSdk` (Android Logcat) or `TikTok` (iOS Console).
- Make sure your network is not blocking `*.tiktokv.com` / `*.tiktokw.us` requests.
- Open an issue with the full log output, your initialization call (with the IDs redacted), and the platform/device you are testing on.

## Contributions

🍺 Pull requests are welcome!

Feel free to contribute to this project.
