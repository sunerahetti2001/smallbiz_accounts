import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/sqlite_service.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Business Details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What\'s your business called?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              const Text('Business Name', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessController,
                decoration: InputDecoration(hintText: 'e.g., My Store', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    if (_businessController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter business name'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.createUser(
        name: widget.userName,
        businessName: _businessController.text,
        currency: widget.currency.split(' ')[0],
        openingBalance: widget.openingBalance,
        accountType: widget.accountType,
      );

      final userId = userProvider.user!.id;
      final sqlite = SqliteService();
      await sqlite.initDefaultCategories(userId);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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
