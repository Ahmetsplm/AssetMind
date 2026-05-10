import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Google Sign In (Requires native setup in GCP and Supabase Dashboard)
  Future<void> signInWithGoogle() async {
    try {
      // NOTE: This is the structure for Google Sign In. 
      // It requires the google_sign_in package for native tokens on Android/iOS,
      // or using signInWithOAuth for web. For a mobile app, it's typically:
      // final googleSignIn = GoogleSignIn();
      // final googleUser = await googleSignIn.signIn();
      // final googleAuth = await googleUser!.authentication;
      // await _client.auth.signInWithIdToken(
      //   provider: OAuthProvider.google,
      //   idToken: googleAuth.idToken!,
      //   accessToken: googleAuth.accessToken,
      // );
      
      throw UnimplementedError('Google Sign-In native altyapısı kurulduğunda bu metot aktif edilecek.');
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
      final data = await _client.from('profiles').select('full_name').eq('id', user.id).maybeSingle();
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
