library force_update;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

// --- Shared private utility functions ---

/// Compares current version string with the required minimum version string.
bool _isUpdateRequired(String current, String required) {
  try {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> requiredParts = required.split('.').map(int.parse).toList();

    int maxLen = currentParts.length > requiredParts.length
        ? currentParts.length
        : requiredParts.length;

    for (int i = 0; i < maxLen; i++) {
      int currentP = currentParts.length > i ? currentParts[i] : 0;
      int requiredP = requiredParts.length > i ? requiredParts[i] : 0;

      if (currentP < requiredP) {
        return true; // Update is required
      } else if (currentP > requiredP) {
        return false; // Current version is newer
      }
    }
    return false; // Same version
  } catch (e) {
    print('ForceUpdateChecker: Error comparing versions: $e. Returning false.');
    return false;
  }
}

/// Displays the platform-specific force exit dialog (Cupertino or Material).
void _showForceExitDialog(
    BuildContext context,
    bool? barrierDismissible,
    String title,
    String message,
    String buttonText,
    String laterButtonText,
    String storeUrl) {
  showDialog(
    context: context,
    barrierDismissible:
        barrierDismissible ?? false, // Prevents closing by tapping outside
    builder: (BuildContext dialogContext) {
      return PopScope(
        canPop: barrierDismissible ??
            false, // Prevents closing with the back button
        child: Platform.isIOS
            ? CupertinoAlertDialog(
                // iOS native interface
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text(buttonText),
                    onPressed: () async {
                      await launchUrl(Uri.parse(storeUrl),
                          mode: LaunchMode.externalApplication);
                      exit(0);
                    },
                  ),
                  if (barrierDismissible == true)
                    CupertinoDialogAction(
                      child: Text(laterButtonText),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                ],
              )
            : AlertDialog(
                // Android/Material Design interface
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(buttonText),
                    onPressed: () async {
                      await launchUrl(Uri.parse(storeUrl),
                          mode: LaunchMode.externalApplication);
                      exit(0);
                    },
                  ),
                  if (barrierDismissible == true)
                    TextButton(
                      child: Text(laterButtonText),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                ],
              ),
      );
    },
  );
}

// --- 2. Unified Logic Helpers ---

/// Fetches and activates Remote Config with minimumFetchInterval set to zero.
Future<FirebaseRemoteConfig> _fetchConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ),
  );
  await remoteConfig.fetchAndActivate();
  return remoteConfig;
}

/// Helper function that implements the core version comparison logic
Future<bool> _fetchAndCheckVersion(
  String? minimumVersionOverride,
  String minimumVersionKey,
) async {
  try {
    final remoteConfig = await _fetchConfig();

    // 1. Get required version from Firebase (This returns an empty string if not found)
    final remoteVersion = remoteConfig.getString(minimumVersionKey);

    // 2. Determine the version to use: Firebase first, then Override as fallback.
    final String requiredVersion;

    if (remoteVersion.isNotEmpty) {
      // Priority 1: Value from Firebase
      requiredVersion = remoteVersion;
    } else if (minimumVersionOverride != null &&
        minimumVersionOverride.isNotEmpty) {
      // Priority 2: Override value
      requiredVersion = minimumVersionOverride;
    } else {
      // No value available, assume no mandatory update is required.
      return false;
    }

    // 3. Get current app version
    final PackageInfo info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    print('ForceUpdateManager: Current version: $currentVersion, '
        'Required minimum version: $requiredVersion');
    // 4. Compare
    return _isUpdateRequired(currentVersion, requiredVersion);
  } catch (e) {
    print('ForceUpdateManager Error during check: $e');
    return false; // Assume no update required on failure
  }
}

// --- 3. Main Manager for UI Integration (Unified) ---

class ForceUpdateManager {
  /// Checks if a mandatory update is required for the current platform
  /// by comparing the current app version with the minimum required version
  /// from Firebase Remote Config.
  ///
  /// This function does NOT display any UI and returns the required status immediately.
  /// Requires Firebase to be initialized.
  static Future<bool> checkForUpdate({
    /// [minimumVersionRemoteConfigKey] is the key used to retrieve the minimum required
    /// version string (e.g., '2.5.0') from Firebase Remote Config.
    /// This key MUST be set up in your Firebase Console.
    required String minimumVersionRemoteConfigKey,

    /// [minimumVersionOverride] is an optional value used for local testing
    /// or as an immediate fallback. If [minimumVersionRemoteConfigKey] is not
    /// set in Firebase, the package falls back to this value.
    String? minimumVersionOverride,
  }) async {
    // If platform is not Android or iOS, no check is needed.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    return await _fetchAndCheckVersion(
        minimumVersionOverride, minimumVersionRemoteConfigKey);
  }

  /// Performs the actual forced update process (displaying the dialog and enforcing exit).
  ///
  /// This function MUST be called only if [checkForUpdate] returns true.
  /// It is safe to call from `initState` as it wraps the logic in a post-frame callback.
  ///
  /// [context] is required to display the dialog.
  static Future<void> performForceUpdate(
    BuildContext context, {
    required String androidStoreUrl,
    required String iosStoreUrl,
    bool?
        barrierDismissible, // Optional: Allow dismissing dialog by tapping outside
    String dialogTitle = 'Required Update',
    String dialogMessage =
        'A critical update is required to continue using the app. Please update now to the latest version.',
    String updateButtonText = 'Update Now',
    String laterButtonText = 'later', // display when barrierDismissible is true
  }) async {
    // Determine the correct store URL
    final storeUrl = Platform.isIOS ? iosStoreUrl : androidStoreUrl;

    // Display the unified dialog
    _showForceExitDialog(context, barrierDismissible, dialogTitle,
        dialogMessage, updateButtonText, laterButtonText, storeUrl);
  }
}
