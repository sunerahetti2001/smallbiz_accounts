import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';
import '../home/home_screen.dart';
import 'basic_info_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  final bool isLogin;
  const EmailAuthScreen({super.key, this.isLogin = true});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isLogin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      if (_isLogin) {
        // LOGIN flow
        await userProvider.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        _handlePostAuth(userProvider);
      } else {
        // SIGN UP flow
        await userProvider.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        _handlePostAuth(userProvider);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('] ')) {
          errorMessage = errorMessage.split('] ').last;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.signInWithGoogle();

      if (!mounted) return;

      debugPrint('EmailAuthScreen: Google auth complete. isOnboarded=${userProvider.isOnboarded}, needsOnboarding=${userProvider.needsOnboarding}');

      _handlePostAuth(userProvider);
    } catch (e) {
      if (mounted) {
        debugPrint('Google Sign In error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePostAuth(UserProvider userProvider) {
    debugPrint('_handlePostAuth: isLogin=$_isLogin, isOnboarded=${userProvider.isOnboarded}, needsOnboarding=${userProvider.needsOnboarding}, isGuest=${userProvider.isGuest}');

    if (_isLogin) {
      // LOGIN: If user exists in SQLite -> Home, else -> Onboarding
      if (userProvider.isOnboarded) {
        debugPrint('Login: User onboarded -> HomeScreen');
        _navigateToHome();
      } else if (userProvider.needsOnboarding) {
        debugPrint('Login: User needs onboarding -> BasicInfoScreen');
        _navigateToOnboarding();
      } else {
        // No change - stay on screen
        debugPrint('Login: No state change');
      }
    } else {
      // SIGN UP: Always go to onboarding
      debugPrint('SignUp: Going to onboarding');
      _navigateToOnboarding();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BasicInfoScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? localizations.login : localizations.signUp),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  _isLogin ? localizations.welcomeBack : localizations.startJourney,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to access your account' : 'Create an account to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: localizations.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: localizations.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isLogin ? localizations.login.toUpperCase() : localizations.signUp.toUpperCase()),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(localizations.or, style: const TextStyle(color: Colors.grey)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                _buildGoogleButton(localizations),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin ? localizations.dontHaveAccount : localizations.alreadyHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(AppLocalizations localizations) {
    return OutlinedButton(
      onPressed: _isLoading ? null : _continueWithGoogle,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/google_logo.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4285F4), width: 2),
              ),
              child: const Center(
                child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isLogin ? localizations.continueWithGoogle : localizations.signUpWithGoogle,
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}