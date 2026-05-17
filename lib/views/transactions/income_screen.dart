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
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemQuantityController = TextEditingController();

  CategoryModel? _selectedCategory;
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Map<String, dynamic>> _items = [];
  double _totalAmount = 0;
  bool _isSalesCategory = false;

  final List<String> _paymentMethods = ['Cash', 'Bank', 'Card'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;
    final userId = userProvider.user!.id;
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.loadCategories(userId);

    if (!mounted) return;

    if (categoryProvider.incomeCategories.isNotEmpty) {
      setState(() {
        _selectedCategory = categoryProvider.incomeCategories.first;
        _checkSalesCategory();
      });
    }
  }

  void _checkSalesCategory() {
    if (_selectedCategory != null) {
      _isSalesCategory = _selectedCategory!.name.toLowerCase() == 'sales';
    }
  }

  void _addItem() {
    final localizations = AppLocalizations.of(context);
    final name = _itemNameController.text.trim();
    final price = double.tryParse(_itemPriceController.text) ?? 0;
    final quantity = double.tryParse(_itemQuantityController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterDescription)),
      );
      return;
    }
    if (price <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterValidPriceQuantity)),
      );
      return;
    }

    setState(() {
      final total = price * quantity;
      _items.add({
        'name': name,
        'price': price,
        'quantity': quantity,
        'total': total,
      });
      _totalAmount += total;
      _itemNameController.clear();
      _itemPriceController.clear();
      _itemQuantityController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _totalAmount -= (_items[index]['total'] as double);
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.income)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          children: [
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
                onChanged: (v) {
                  setState(() {
                    _selectedCategory = v;
                    _checkSalesCategory();
                    _items = [];
                    _totalAmount = 0;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            if (_isSalesCategory) ...[
              _buildItemizedSalesForm(localizations, isSmallScreen),
              const SizedBox(height: 16),
            ],

            if (!_isSalesCategory) ...[
              Text(localizations.amount, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return localizations.pleaseEnterAmount;
                  if (double.tryParse(value) == null) return 'Please enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            Text(localizations.description, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _isSalesCategory ? 'e.g., Daily sales, Evening batch' : localizations.description,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return localizations.pleaseEnterDescription;
                return null;
              },
            ),
            const SizedBox(height: 16),

            Text(localizations.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
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
                      Radio<String>(
                        value: method,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                        activeColor: AppColors.primary,
                      ),
                      Flexible(child: Text(displayMethod, style: TextStyle(fontSize: isSmallScreen ? 10 : 12))),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isSalesCategory ? localizations.recordSale : localizations.saveIncome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemizedSalesForm(AppLocalizations localizations, bool isSmallScreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppColors.income),
                const SizedBox(width: 8),
                Text(localizations.items, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _itemNameController,
              decoration: InputDecoration(
                labelText: localizations.item,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _itemPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${localizations.price} (Rs)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _itemQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: localizations.quantity,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: Text(localizations.addItem),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.income,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              ..._items.asMap().entries.map((e) {
                final index = e.key;
                final item = e.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['name'] as String, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    'Rs ${item['price']} x ${item['quantity']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs ${(item['total'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => _removeItem(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localizations.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    'Rs ${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.income),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final localizations = AppLocalizations.of(context);

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseSelectCategory)),
      );
      return;
    }

    if (_isSalesCategory) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.addItem)),
        );
        return;
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterDescription)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user!.id;

      final amount = _isSalesCategory ? _totalAmount : double.parse(_amountController.text);

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        type: TransactionType.income,
        amount: amount,
        category: _selectedCategory!.name,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        items: _isSalesCategory ? _items : null,
      );

      await Provider.of<TransactionProvider>(context, listen: false)
          .addTransaction(transaction, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.income} ${localizations.save} ${localizations.success}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error saving income: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.error}: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }
}