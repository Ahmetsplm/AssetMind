import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lock_screen.dart';

class AuthWrapper extends StatelessWidget {
  final int initialTab;
  const AuthWrapper({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return LockScreen(child: HomeScreen(initialIndex: initialTab));
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
