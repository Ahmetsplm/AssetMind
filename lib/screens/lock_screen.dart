import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  final Widget child; // The app to show if unlocked

  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final AuthService _auth = AuthService();
  bool _isLocked = true;
  bool _canCheckBiometrics = false;
  bool _isverifying = false;
  DateTime? _lastAuthTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isverifying) {
      if (_lastAuthTime != null &&
          DateTime.now().difference(_lastAuthTime!) <
              const Duration(seconds: 2)) {
        return;
      }
      _checkLockStatus();
    }
  }

  Future<void> _checkLockStatus() async {
    final enabled = await _auth.isLockEnabled();
    if (!enabled) {
      if (mounted) setState(() => _isLocked = false);
      return;
    }

    if (!_isLocked) {
      setState(() => _isLocked = true);
    }

    final supported = await _auth.isDeviceSupported();
    if (mounted) setState(() => _canCheckBiometrics = supported);

    if (supported && !_isverifying) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isverifying) return;
    _isverifying = true;

    WidgetsBinding.instance.removeObserver(this);

    try {
      final authenticated = await _auth.authenticate();
      if (authenticated && mounted) {
        _lastAuthTime = DateTime.now();
        setState(() => _isLocked = false);
      }
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addObserver(this);
      }
      _isverifying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              "AssetMind Kilitli",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Devam etmek için doğrulayın",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: 48),
            if (_canCheckBiometrics)
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text(
                  "Giriş Yap",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
