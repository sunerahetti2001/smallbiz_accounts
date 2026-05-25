import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../../services/backup_service.dart';
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
  bool _autoBackupEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _businessController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadBackupSettings();
    });
  }

  void _loadUserData() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null && mounted) {
      _nameController.text = user.name;
      _businessController.text = user.businessName;
      setState(() {});
    }
  }

  Future<void> _loadBackupSettings() async {
    final backupService = BackupService();
    final auto = await backupService.isAutoBackupEnabled();
    if (mounted) {
      setState(() {
        _autoBackupEnabled = auto;
      });
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

            if (user.email != null && user.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(user.email!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
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
                  style: TextStyle(fontSize: 15, color: userProvider.isGuest ? Colors.amber : AppColors.success),
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

            const SizedBox(height: 24),

            // --- Backup & Restore Section (only for logged-in users) ---
            if (!userProvider.isGuest) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Backup & Restore',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildBackupInfo(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _backupNow,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Backup Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _restoreFromCloud,
                              icon: const Icon(Icons.cloud_download),
                              label: const Text('Restore'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto backup'),
                        subtitle: const Text('Backup automatically when changes are made'),
                        value: _autoBackupEnabled,
                        onChanged: _setAutoBackup,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],

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

  Widget _buildBackupInfo() {
    return FutureBuilder<DateTime?>(
      future: BackupService().getLastBackupTime(),
      builder: (context, snapshot) {
        final text = snapshot.data != null
            ? 'Last backup: ${snapshot.data!.day}/${snapshot.data!.month}/${snapshot.data!.year} ${snapshot.data!.hour}:${snapshot.data!.minute}'
            : 'Last backup: Never';
        return Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13));
      },
    );
  }

  Future<void> _backupNow() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect an email to use backup')),
      );
      return;
    }
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
      return;
    }

    try {
      await BackupService().backupToCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup completed')),
        );
        setState(() {}); // refresh last backup time
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect an email to use backup')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('This will replace all local data with the cloud backup. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await BackupService().restoreFromCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully')),
        );
        // Reload providers
        final auth = FirebaseAuth.instance;
        final userId = auth.currentUser!.uid;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserByUid(userId);
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        await transactionProvider.loadTransactions(userId);
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.loadCategories(userId);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  void _setAutoBackup(bool value) async {
    await BackupService().setAutoBackup(value);
    setState(() => _autoBackupEnabled = value);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.error}: $e')),
        );
      }
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
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.logoutClear, style: const TextStyle(color: Colors.red))),
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