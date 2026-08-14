import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

final _notificationService = NotificationService();

// Simple in-memory nav key so a background notification tap can push a
// screen even from outside the widget tree (deep-link bonus feature).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init();
  await _notificationService.init();

  _notificationService.onNotificationTapped = (data) {
    final postId = data['postId'] as String?;
    if (postId == null) return;
    // In a full implementation this would fetch the post by id and push
    // PostDetailScreen. Left as a hook here since it depends on a
    // fetch-by-id method not otherwise needed by the mini-project spec.
    debugPrint('Notification tapped for postId=$postId — wire up fetch-by-id to deep link.');
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ASL Mobile — Week 4',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _AuthGate(),
    );
  }
}

/// Routes to HomeScreen if a Supabase session already exists, otherwise
/// LoginScreen. Also requests the notification permission and links the
/// OneSignal subscription once a user is signed in.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((state) async {
      if (_authService.isSignedIn) {
        await _notificationService.requestPermission();
        await _notificationService.linkToUser(_authService.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _authService.isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
