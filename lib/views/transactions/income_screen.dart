import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  CategoryModel? _selectedCategory;
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _paymentMethods = ['Cash', 'Bank', 'Card'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user!.id;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.loadCategories(userId);

    if (categoryProvider.incomeCategories.isNotEmpty) {
      setState(() {
        _selectedCategory = categoryProvider.incomeCategories.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.income)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(localizations.amount, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'Rs ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? localizations.pleaseEnterAmount : null,
            ),
            const SizedBox(height: 16),
            Text(localizations.selectCategory, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<CategoryModel>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                items: categoryProvider.incomeCategories.map((c) {
                  return DropdownMenuItem(value: c, child: Text('${c.icon} ${c.name}'));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            ),
            const SizedBox(height: 16),
            Text(localizations.description, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: localizations.description,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? localizations.pleaseEnterDescription : null,
            ),
            const SizedBox(height: 16),
            Text(localizations.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: _paymentMethods.map((method) {
                String displayMethod;
                switch (method) {
                  case 'Cash': displayMethod = localizations.cash;
                  case 'Bank': displayMethod = localizations.bank;
                  case 'Card': displayMethod = localizations.card;
                  default: displayMethod = method;
                }
                return Expanded(
                  child: Row(
                    children: [
                      Radio<String>(value: method, groupValue: _selectedPaymentMethod, onChanged: (v) => setState(() => _selectedPaymentMethod = v!), activeColor: AppColors.primary),
                      Text(displayMethod),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.income, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(localizations.saveIncome),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      setState(() => _isLoading = true);
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user!.id;
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.income,
          amount: double.parse(_amountController.text),
          category: _selectedCategory!.name,
          description: _descriptionController.text,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
        );
        await Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction, userId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizations.error}: $e'), backgroundColor: AppColors.error));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}