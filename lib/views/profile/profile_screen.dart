import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../onboarding/welcome_screen.dart';
import '../onboarding/email_auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _businessController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _businessController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _loadUserData() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null && mounted) {
      _nameController.text = user.name;
      _businessController.text = user.businessName;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user!;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.profile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(radius: 50, child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40))),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            // Show email
            if (user.email != null && user.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    user.email!,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  userProvider.isGuest ? Icons.person_outline : Icons.verified_user,
                  size: 18,
                  color: userProvider.isGuest ? Colors.amber : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  userProvider.isGuest ? 'Guest Account' : '${user.accountType} Account',
                  style: TextStyle(
                    fontSize: 15,
                    color: userProvider.isGuest ? Colors.amber : AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (userProvider.isGuest)
              Card(
                color: Colors.amber.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.amber),
                  title: Text(localizations.guestWarning.split('.')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(localizations.guestWarning),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Navigate to sign up page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmailAuthScreen(isLogin: false)),
                      );
                    },
                    child: Text(localizations.connect),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: localizations.name)),
            const SizedBox(height: 16),
            TextField(controller: _businessController, decoration: InputDecoration(labelText: localizations.businessName)),

            const SizedBox(height: 24),
            // Language selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(localizations.selectLanguage),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Provider.of<LanguageProvider>(context).isSinhala ? 'සිංහල' : 'English',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showLanguageDialog(context, localizations),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving ? const CircularProgressIndicator() : Text(localizations.updateProfile),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _handleLogout(userProvider, localizations),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: Text(localizations.logout),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final localizations = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updated = userProvider.user!.copyWith(
        name: _nameController.text,
        businessName: _businessController.text,
      );
      await userProvider.updateUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.profileUpdated)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.error}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout(UserProvider userProvider, AppLocalizations localizations) async {
    bool clearData = false;
    if (userProvider.isGuest) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.warning),
          content: Text(localizations.logoutWarning),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(localizations.logoutClear, style: const TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (result != true) return;
      clearData = true;
    }
    await userProvider.logout(clearGuestData: clearData);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
      );
    }
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations localizations) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(localizations.english),
                trailing: !languageProvider.isSinhala
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(dialogContext);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
                title: Text(localizations.sinhala),
                trailing: languageProvider.isSinhala
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('si');
                  Navigator.pop(dialogContext);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    super.dispose();
  }
}