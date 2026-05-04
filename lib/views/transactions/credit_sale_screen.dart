import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(localizations.creditSale)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerDetails(localizations),
            const SizedBox(height: 16),
            _buildItemForm(localizations),
            const SizedBox(height: 16),
            _buildPaymentSchedule(localizations),
            const SizedBox(height: 16),
            _buildSaleDate(localizations),
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

  Widget _buildCustomerDetails(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextFormField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: localizations.customer,
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerMobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: localizations.phone,
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildItemForm(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextFormField(
            controller: _itemNameController,
            decoration: InputDecoration(labelText: localizations.item),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _itemPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.price,
                  prefixText: 'Rs ',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _itemQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: localizations.quantity),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _addItem,
            child: Text(localizations.addItem),
          ),
          if (_items.isNotEmpty) ...[
            const Divider(),
            ..._items.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              return ListTile(
                title: Text(item['name']),
                subtitle: Text('Rs ${item['price']} x ${item['quantity']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs ${item['total']}'),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Text(
              '${localizations.total}: ${CurrencyFormatter.formatLKR(_totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ]
        ]),
      ),
    );
  }

  Widget _buildPaymentSchedule(AppLocalizations localizations) {
    return Card(
      child: SwitchListTile(
        title: Text(localizations.setDueDate),
        value: _setDueDate,
        onChanged: (v) => setState(() => _setDueDate = v),
      ),
    );
  }

  Widget _buildSaleDate(AppLocalizations localizations) {
    return Card(
      child: ListTile(
        title: Text('${localizations.date}: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
        trailing: const Icon(Icons.calendar_today),
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
    final price = double.tryParse(_itemPriceController.text) ?? 0;
    final quantity = double.tryParse(_itemQuantityController.text) ?? 0;
    if (price > 0 && quantity > 0) {
      setState(() {
        final total = price * quantity;
        _items.add({
          'name': _itemNameController.text,
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
  }

  void _removeItem(int index) {
    setState(() {
      _totalAmount -= _items[index]['total'];
      _items.removeAt(index);
    });
  }

  Future<void> _saveTransaction() async {
    final localizations = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user!.id;
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.creditSale,
          amount: _totalAmount,
          category: 'Credit Sales',
          description: 'Credit sale to ${_customerNameController.text}',
          date: _selectedDate,
          customerName: _customerNameController.text,
          customerMobile: _customerMobileController.text,
          items: _items,
          isPaid: false,
          dueDate: _setDueDate ? _selectedDueDate : null,
        );
        await Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction, userId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.error}: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}