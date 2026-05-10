import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _displayName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get displayName => _displayName;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _authService.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchDisplayName();
      } else {
        _displayName = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchDisplayName() async {
    final name = await _authService.getUserFullName();
    if (_displayName != name) {
      _displayName = name;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      await fetchDisplayName();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Beklenmeyen bir hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String fullName) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signUpWithEmail(email: email, password: password, fullName: fullName);
      await fetchDisplayName();
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Beklenmeyen bir hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signInWithGoogle();
      await fetchDisplayName();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signOut();
      notifyListeners();
    } catch (e) {
      _setError('Çıkış yaparken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
