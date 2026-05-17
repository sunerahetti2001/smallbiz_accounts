import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../services/sqlite_service.dart';
import '../views/onboarding/welcome_screen.dart';
import '../views/onboarding/basic_info_screen.dart';
import '../views/home/home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<bool> _isExistingUser(String uid) async {
    try {
      final user = await SqliteService().getUser(id: uid);
      return user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuest') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          return FutureBuilder<bool>(
            future: _isExistingUser(uid),
            builder: (context, existSnapshot) {
              if (!existSnapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (existSnapshot.data!) {
                return FutureBuilder(
                  future: context.read<UserProvider>().loadUserByUid(uid),
                  builder: (context, loadSnapshot) {
                    if (loadSnapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    return const HomeScreen();
                  },
                );
              } else {
                return FutureBuilder(
                  future: context.read<UserProvider>().prepareForOnboarding(),
                  builder: (context, _) {
                    if (_.connectionState != ConnectionState.done) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    return const BasicInfoScreen();
                  },
                );
              }
            },
          );
        } else {
          return FutureBuilder<bool>(
            future: _isGuest(),
            builder: (context, guestSnapshot) {
              if (!guestSnapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (guestSnapshot.data!) {
                return FutureBuilder(
                  future: context.read<UserProvider>().loadGuestUser(),
                  builder: (context, loadSnapshot) {
                    if (loadSnapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    if (loadSnapshot.hasError || context.read<UserProvider>().user == null) {
                      return const WelcomeScreen();
                    }
                    return const HomeScreen();
                  },
                );
              } else {
                return const WelcomeScreen();
              }
            },
          );
        }
      },
    );
  }
}