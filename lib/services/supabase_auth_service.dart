import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gso;

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Supabase'de yazdığımız trigger (handle_new_user)
      // bu metadata bilgisini yakalayıp profiles tablosuna otomatik yazacaktır.
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final googleSignIn = gso.GoogleSignIn(
        serverClientId:
            '38711545080-gob5lpe5tnjqu3aj3f09hj8htmp0qf6m.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google ile giriş işlemi iptal edildi.');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
            'Google ID Token alınamadı. SHA-1 veya Web Client ID ayarlarını kontrol edin.');
      }

      return await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserFullName() async {
    final user = currentUser;
    if (user == null) return null;

    if (user.userMetadata?['full_name'] != null) {
      return user.userMetadata!['full_name'] as String;
    }

    try {
      final data = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && data['full_name'] != null) {
        return data['full_name'] as String;
      }
    } catch (_) {}
    return null;
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
