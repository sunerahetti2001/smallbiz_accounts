import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../services/sqlite_service.dart';
import '../services/backup_service.dart';
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
                // Existing user → load and go to Home
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
                // New user → check for cloud backup, then decide
                return FutureBuilder<bool>(
                  future: () async {
                    final backupService = BackupService();
                    final hasBackup = await backupService.hasCloudBackup();
                    if (hasBackup && mounted) {
                      final shouldRestore = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Restore Data'),
                          content: const Text('We found your backed up data. Would you like to restore it?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Skip')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
                          ],
                        ),
                      );
                      if (shouldRestore == true) {
                        await backupService.restoreFromCloud();
                        final userProvider = context.read<UserProvider>();
                        await userProvider.loadUserByUid(uid);
                        return true; // restored, go to Home
                      }
                    }
                    return false;
                  }(),
                  builder: (context, restoreSnapshot) {
                    if (restoreSnapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    final restored = restoreSnapshot.data == true;
                    if (restored) {
                      return const HomeScreen();
                    }
                    // No backup or user skipped → onboarding
                    return FutureBuilder(
                      future: context.read<UserProvider>().prepareForOnboarding(),
                      builder: (context, _) {
                        if (_.connectionState != ConnectionState.done) {
                          return const Scaffold(body: Center(child: CircularProgressIndicator()));
                        }
                        return const BasicInfoScreen();
                      },
                    );
                  },
                );
              }
            },
          );
        } else {
          // No Firebase user → check guest mode
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