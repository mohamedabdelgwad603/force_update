
# force_update

A simple and effective Flutter package that enforces **mandatory updates** for your application on both **Android** and **iOS** by controlling the minimum required version exclusively via **Firebase Remote Config**.

---
<img width="512" height="1080" alt="Simulator Screenshot - iPhone 16 Pro Max - 2025-10-22 at 10 40 58" src="https://github.com/user-attachments/assets/65edf2a1-6bcc-4da3-9276-d5945ddca8e7" />
<img width="512" height="1080" alt="Screenshot_1761050279" src="https://github.com/user-attachments/assets/0e56287c-f098-4be3-8c1f-363e9f031e06" />


## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Installation](#installation)
- [Firebase Initialization](#firebase-initialization)
- [Firebase Remote Config Setup](#firebase-remote-config-setup)
- [Usage](#usage)
  - [Example (SplashScreen)](#example-splashscreen)
  - [Detailed Usage Breakdown](#detailed-usage-breakdown)
- [Behavior & Modes](#behavior--modes)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

`force_update` provides an easy way to force users to update their app by checking a remotely controlled `minimum_version` value stored in **Firebase Remote Config**. If the installed app version is lower than the required minimum, the package shows a platform-specific dialog that prevents further usage until the user updates the app.

---

## Key Features

- **Firebase Exclusive**: Retrieves minimum required version using a single Remote Config key.
- **Platform Support**: Android and iOS supported.
- **Remote Control**: Set the minimum required app version remotely through Firebase.
- **True Force Update**: Shows a dialog that blocks app usage until update (hard update).
- **Soft Update Option**: Optional "Later" button for non-critical updates.

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # The required package
  force_update: ^1.0.0 # Use the actual version number

  # Direct dependency required for Firebase initialization
  firebase_core: ^latest_version
```

> **Important**: The package expects Firebase to be initialized before performing update checks.

---

## Firebase Initialization

Initialize Firebase **before** running any update check, typically in `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // REQUIRED: Initialize Firebase before running the app
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

---

## Firebase Remote Config Setup

The package relies on a single key in the Firebase Remote Config to determine the minimum required version.

1. Go to the Firebase Console → Remote Config.
2. Click **Add parameter**.
3. Add the key you will use in your code, for example: `minimum_version`.
4. Set a baseline value under **Default for all users** (e.g., `1.0.0`) as a safe fallback.
5. Publish a higher value (e.g., `2.5.0`) to enforce updates on older app versions.

**Example parameter**

| Key              | Current Value | Description                                |
|------------------|---------------|--------------------------------------------|
| `minimum_version`| `2.5.0`       | The minimum required version to run the app |

---

## Usage

Call the check function in your `SplashScreen` or before navigating to the main screen.

### Example (SplashScreen)

```dart
import 'package:force_update/force_update.dart';
import 'package:flutter/material.dart';

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the check process immediately
     @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkAndUpdate();
    });
    super.initState();
  }
  }

  void _checkAndUpdate() async {
    // 1. Check if the update is required (Firebase key required)
    bool requiredUpdate = await ForceUpdateManager.checkForUpdate(
      // The key defined in the Firebase Console
      minimumVersionRemoteConfigKey: "minimum_version",
      // Optional fallback for testing or initial safety if Firebase value is missing
      minimumVersionOverride: '2.5.0',
    );

    if (requiredUpdate) {
      // 2. If the update is mandatory, display the dialog
      ForceUpdateManager.performForceUpdate(
        context,
        androidStoreUrl: "YOUR_ANDROID_STORE_LINK",
        iosStoreUrl: "YOUR_IOS_STORE_LINK",
        // Customizing the dialog text (optional)
        dialogTitle: 'Update Required',
        dialogMessage: 'A critical update is needed to continue using our services. Please update now.',
        updateButtonText: 'Update Now',
        // --- SOFT UPDATE MODE (Optional) ---
        // If barrierDismissible is true, the user can dismiss the dialog and continue.
        // barrierDismissible: true,
        // laterButtonText: 'Later',
      );
    } else {
      // 3. If no update is required, navigate to the main screen
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // ... Navigation logic to the main screen
  }
}
```

---

## Detailed Usage Breakdown

### Step 1: `ForceUpdateManager.checkForUpdate`

```dart
bool requiredUpdate = await ForceUpdateManager.checkForUpdate(
  minimumVersionRemoteConfigKey: "minimum_version",
  minimumVersionOverride: '2.5.0',
);
```

**Purpose**: Retrieves the minimum required version from Firebase Remote Config and compares it with the installed app version.

**Parameters**:

- `minimumVersionRemoteConfigKey` (required `String`): The Remote Config key (e.g., `"minimum_version"`).
- `minimumVersionOverride` (`String?`): Optional fallback used when Firebase fails to provide a valid value.

**Returns**: `Future<bool>` — `true` if the installed app version is less than the required minimum.

---

### Step 2: `ForceUpdateManager.performForceUpdate`

```dart
ForceUpdateManager.performForceUpdate(
  context,
  androidStoreUrl: "YOUR_ANDROID_STORE_LINK",
  iosStoreUrl: "YOUR_IOS_STORE_LINK",
  barrierDismissible: false,
  dialogTitle: 'Required Update',
  dialogMessage: 'A critical update is required...',
  updateButtonText: 'Update Now',
  laterButtonText: 'Later',
);
```

**Purpose**: Displays a platform-specific dialog (Material on Android, Cupertino on iOS) that:

- Navigates the user to the app store via the provided `androidStoreUrl` or `iosStoreUrl`.
- Optionally allows dismissal (soft update) if `barrierDismissible: true`.
- Blocks app usage (hard update) if `barrierDismissible: false` (default).

**Parameters**:

- `context` (`BuildContext`) — required to show the dialog.
- `androidStoreUrl` (`String`) — Google Play store link.
- `iosStoreUrl` (`String`) — Apple App Store link.
- `barrierDismissible` (`bool?`) — `true` for soft update (default `false`).
- `dialogTitle`, `dialogMessage`, `updateButtonText`, `laterButtonText` — UI text customizations.

---

## Behavior & Modes

- **Hard/Strict Update** (default): Dialog cannot be dismissed. The user must update or exit the app.
- **Soft Update**: Enable `barrierDismissible: true` and show a `Later` button to allow users to skip the update temporarily.

---


## Contributing

Contributions, issues and feature requests are welcome — feel free to open an issue or submit a pull request.

---

## License

Specify your license here (e.g., MIT).  
