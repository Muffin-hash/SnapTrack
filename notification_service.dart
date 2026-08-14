import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Wraps push notification setup and foreground/background handling.
///
/// Supabase does not provide a push notification service of its own, so
/// this project pairs it with OneSignal — it's free, doesn't require a
/// Firebase project, and gives the same three things FCM would:
/// a device push token/subscription id, a foreground-notification hook,
/// and a notification-tap (deep link) hook. See README > Push
/// Notifications for the full reasoning and setup steps.
class NotificationService {
  /// Call once, before runApp, with the OneSignal App ID from the
  /// OneSignal dashboard. Passed via --dart-define so it isn't hard-coded.
  static const String _oneSignalAppId =
      String.fromEnvironment('ONESIGNAL_APP_ID');

  /// Fired when a notification arrives while the app is in the
  /// foreground. Screens can use this to show an in-app banner instead
  /// of the default OS notification.
  void Function(OSNotification notification)? onForegroundNotification;

  /// Fired when the user taps a notification (app was backgrounded or
  /// terminated). Used for deep-linking to the relevant record.
  void Function(Map<String, dynamic> data)? onNotificationTapped;

  Future<void> init() async {
    assert(
      _oneSignalAppId.isNotEmpty,
      'ONESIGNAL_APP_ID must be supplied via --dart-define. '
      'See README > Environment Setup.',
    );

    OneSignal.initialize(_oneSignalAppId);

    // Foreground behavior: intercept and prevent the default OS
    // notification so the app can decide how to present it.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      onForegroundNotification?.call(event.notification);
    });

    // Background/terminated behavior: user tapped a notification while
    // the app was not in the foreground.
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData ?? <String, dynamic>{};
      onNotificationTapped?.call(data);
    });
  }

  /// Requests the OS-level notification permission. On iOS this triggers
  /// the system prompt; on Android 13+ it triggers the runtime prompt.
  Future<bool> requestPermission() async {
    return OneSignal.Notifications.requestPermission(true);
  }

  /// Links the OneSignal subscription to the signed-in Supabase user, so
  /// a server-side function can target notifications at a specific user
  /// (e.g. "your upload finished processing").
  Future<void> linkToUser(String supabaseUserId) async {
    await OneSignal.login(supabaseUserId);
  }

  Future<void> unlinkUser() async {
    await OneSignal.logout();
  }
}
