import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';

class CreditSaleScreen extends StatefulWidget {
  const CreditSaleScreen({super.key});

  @override
  State<CreditSaleScreen> createState() => _CreditSaleScreenState();
}

class _CreditSaleScreenState extends State<CreditSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerMobileController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemQuantityController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  bool _setDueDate = false;

  List<Map<String, dynamic>> _items = [];
  double _totalAmount = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(localizations.creditSale)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          children: [
            _buildCustomerDetails(localizations, isSmallScreen),
            const SizedBox(height: 16),
            _buildItemForm(localizations, isSmallScreen),
            const SizedBox(height: 16),
            _buildDueDateSection(localizations, isSmallScreen),
            const SizedBox(height: 16),
            _buildSaleDate(localizations, isSmallScreen),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_items.isEmpty || _isLoading) ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(localizations.recordSale),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(AppLocalizations localizations, bool isSmallScreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.customer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: '${localizations.customer} *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter customer name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerMobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: localizations.phone,
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemForm(AppLocalizations localizations, bool isSmallScreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppColors.credit),
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
                  foregroundColor: AppColors.credit,
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
                    CurrencyFormatter.formatLKR(_totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.credit),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSection(AppLocalizations localizations, bool isSmallScreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localizations.setDueDate),
              value: _setDueDate,
              activeColor: AppColors.credit,
              onChanged: (v) {
                setState(() {
                  _setDueDate = v;
                  if (!v) _selectedDueDate = null;
                });
              },
            ),
            if (_setDueDate) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDueDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.credit),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDueDate != null
                            ? '${localizations.dueDate}: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                            : localizations.selectPeriod,
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDueDate != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedDueDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaleDate(AppLocalizations localizations, bool isSmallScreen) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
        title: Text('${localizations.date}: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
        trailing: const Icon(Icons.edit_calendar),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) setState(() => _selectedDate = date);
        },
      ),
    );
  }

  void _addItem() {
    final localizations = AppLocalizations.of(context);
    final name = _itemNameController.text.trim();
    final price = double.tryParse(_itemPriceController.text) ?? 0;
    final quantity = double.tryParse(_itemQuantityController.text) ?? 0;

    if (name.isEmpty || price <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseFillItemDetails)),
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
      _totalAmount -= _items[index]['total'] as double;
      _items.removeAt(index);
    });
  }

  Future<void> _saveTransaction() async {
    final localizations = AppLocalizations.of(context);

    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterCustomerName)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user!.id;

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        type: TransactionType.creditSale,
        amount: _totalAmount,
        category: 'Credit Sales',
        description: 'Credit sale to ${_customerNameController.text.trim()}',
        date: _selectedDate,
        customerName: _customerNameController.text.trim(),
        customerMobile: _customerMobileController.text.trim().isEmpty
            ? null
            : _customerMobileController.text.trim(),
        items: _items,
        isPaid: false,
        dueDate: _setDueDate ? _selectedDueDate : null,
      );

      await Provider.of<TransactionProvider>(context, listen: false)
          .addTransaction(transaction, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.creditSale} ${localizations.save} ${localizations.success}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error saving credit sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.error}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}