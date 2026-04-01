import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import 'package:firebase_core/firebase_core.dart';
=======
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
import 'providers/user_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'utils/theme.dart';
import 'views/onboarding/welcome_screen.dart';
import 'views/home/home_screen.dart';
<<<<<<< HEAD
import 'services/sqlite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize SQLite
  final sqlite = SqliteService();
  await sqlite.database;
  await sqlite.initDefaultCategories();

=======

void main() {
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MaterialApp(
        title: 'SmallBiz Accounts',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppLoader(),
      ),
    );
  }
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load user data after the first frame to ensure providers are ready
<<<<<<< HEAD
    WidgetsBinding.instance.addPostFrameCallback((_) async {
=======
    await Future.microtask(() async {
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUser();

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userProvider.isOnboarded) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}