import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
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

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
