import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Wraps Supabase Auth (GoTrue). This is the Week 3 auth carried forward —
/// included here so the Week 4 device features have a signed-in user to
/// attach uploads and location to.
class AuthService {
  final GoTrueClient _auth = SupabaseService.client.auth;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
