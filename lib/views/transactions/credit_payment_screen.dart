import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
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
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCredits();
    });
  }

  Future<void> _refreshCredits() async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    await transactionProvider.loadTransactions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);

    final unpaidCredits = transactionProvider.transactions
        .where((t) => t.type == TransactionType.creditSale && !t.isPaid)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Credit Payment'),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Select Credit Sale',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<TransactionModel>(
                value: _selectedCredit,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text('Select customer'),
                items: unpaidCredits.map((credit) {
                  return DropdownMenuItem(
                    value: credit,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${credit.customerName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Amount: ${CurrencyFormatter.formatLKR(credit.amount)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        if (credit.dueDate != null)
                          Text(
                            'Due: ${credit.dueDate!.day}/${credit.dueDate!.month}/${credit.dueDate!.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: credit.dueDate!.isBefore(DateTime.now())
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCredit = value;
                    _amountController.text = value!.amount.toString();
                  });
                },
              ),
            ),

            if (_selectedCredit != null) ...[
              const SizedBox(height: 24),

              if (_selectedCredit!.dueDate != null &&
                  _selectedCredit!.dueDate!.isBefore(DateTime.now()))
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payment is overdue! Due date was ${_selectedCredit!.dueDate!.day}/${_selectedCredit!.dueDate!.month}/${_selectedCredit!.dueDate!.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Payment Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value) ?? 0;
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amount > _selectedCredit!.amount) {
                    return 'Amount cannot exceed ${CurrencyFormatter.formatLKR(_selectedCredit!.amount)}';
                  }
                  return null;
                },
              ),
              if (_selectedCredit != null && _amountController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Remaining: ${CurrencyFormatter.formatLKR(_selectedCredit!.amount - (double.tryParse(_amountController.text) ?? 0))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              const Text(
                'Payment Method',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _paymentMethods.map((method) {
                  return Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: method,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Text(method),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              const Text(
                'Date',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF475569)),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('RECORD PAYMENT'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final paymentAmount = double.parse(_amountController.text);
        final isFullPayment = paymentAmount >= _selectedCredit!.amount - 0.01;

        final payment = TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.creditPayment,
          amount: paymentAmount,
          category: 'Credit Payment',
          description: 'Payment received from ${_selectedCredit!.customerName}',
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
          customerName: _selectedCredit!.customerName,
        );

        final transactionProvider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );

        await transactionProvider.addTransaction(payment);

        // Force refresh to update the UI
        await transactionProvider.loadTransactions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFullPayment
                    ? '✓ Payment received successfully!'
                    : '✓ Partial payment recorded. Remaining: ${CurrencyFormatter.formatLKR(_selectedCredit!.amount - paymentAmount)}',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}