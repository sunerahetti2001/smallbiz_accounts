import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/sqlite_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';
import '../home/home_screen.dart';

class BusinessNameScreen extends StatefulWidget {
  final String userName;
  final String currency;
  final double openingBalance;
  final String accountType;

  const BusinessNameScreen({
    super.key,
    required this.userName,
    required this.currency,
    required this.openingBalance,
    required this.accountType,
  });

  @override
  State<BusinessNameScreen> createState() => _BusinessNameScreenState();
}

class _BusinessNameScreenState extends State<BusinessNameScreen> {
  final _businessController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.businessDetails)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.businessNameQuestion, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(localizations.businessNameDesc, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 32),
              Text(localizations.businessName, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessController,
                decoration: InputDecoration(
                  hintText: localizations.businessNameHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(localizations.completeSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    final localizations = AppLocalizations.of(context);

    if (_businessController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseEnterBusinessName),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.createUser(
        name: widget.userName,
        businessName: _businessController.text.trim(),
        currency: widget.currency.split(' ')[0],
        openingBalance: widget.openingBalance,
        accountType: widget.accountType,
      );

      if (userProvider.user == null) {
        throw Exception('User creation failed');
      }

      // Initialize default categories for new user
      final userId = userProvider.user!.id;
      final sqlite = SqliteService();
      await sqlite.initDefaultCategories(userId);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _businessController.dispose();
    super.dispose();
  }
}