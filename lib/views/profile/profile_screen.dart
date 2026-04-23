import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
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
  bool _isEditing = false;
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
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final user = userProvider.user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(radius: 50, child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40))),
            const SizedBox(height: 24),
            if (userProvider.isGuest)
              Card(
                color: Colors.amber.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.amber),
                  title: const Text('Guest Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Connect to email to secure your data.'),
                  trailing: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                    child: const Text('CONNECT'),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _businessController, decoration: const InputDecoration(labelText: 'Business Name')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(onPressed: _isSaving ? null : _saveProfile, child: _isSaving ? const CircularProgressIndicator() : const Text('UPDATE PROFILE')),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _handleLogout(userProvider),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              child: const Text('LOG OUT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final updated = userProvider.user!.copyWith(name: _nameController.text, businessName: _businessController.text);
      await userProvider.updateUser(updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout(UserProvider userProvider) async {
    bool clearData = false;
    if (userProvider.isGuest) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout Warning'),
          content: const Text('Your guest data will be permanently cleared. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOGOUT & CLEAR', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (result != true) return;
      clearData = true;
    }
    await userProvider.logout(clearGuestData: clearData);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
    }
  }
}
