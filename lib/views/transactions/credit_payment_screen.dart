import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';

class CreditPaymentScreen extends StatefulWidget {
  const CreditPaymentScreen({super.key});

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  TransactionModel? _selectedCredit;
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _paymentMethods = ['Cash', 'Bank', 'Card'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCredits());
  }

  Future<void> _refreshCredits() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions(userProvider.user!.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final unpaidCredits = transactionProvider.transactions.where((t) => t.type == TransactionType.creditSale && !t.isPaid).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Credit Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Select Credit Sale', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(16)),
              child: DropdownButton<TransactionModel>(
                value: _selectedCredit,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Select customer'),
                items: unpaidCredits.map((c) => DropdownMenuItem(value: c, child: Text('${c.customerName} - ${CurrencyFormatter.formatLKR(c.amount)}'))).toList(),
                onChanged: (v) => setState(() { _selectedCredit = v; _amountController.text = v!.amount.toString(); }),
              ),
            ),
            if (_selectedCredit != null) ...[
              const SizedBox(height: 24),
              const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: '0.00', prefixText: 'Rs ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                validator: (value) => (value == null || (double.tryParse(value) ?? 0) <= 0) ? 'Enter valid amount' : null,
              ),
              const SizedBox(height: 16),
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: _paymentMethods.map((method) {
                  return Expanded(
                    child: Row(
                      children: [
                        Radio<String>(value: method, groupValue: _selectedPaymentMethod, onChanged: (v) => setState(() => _selectedPaymentMethod = v!), activeColor: AppColors.primary),
                        Text(method),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('RECORD PAYMENT'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user!.id;
        final payment = TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.creditPayment,
          amount: double.parse(_amountController.text),
          category: 'Credit Payment',
          description: 'Payment from ${_selectedCredit!.customerName}',
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          customerName: _selectedCredit!.customerName,
        );
        await Provider.of<TransactionProvider>(context, listen: false).addTransaction(payment, userId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
