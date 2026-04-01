import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/colors.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
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
<<<<<<< HEAD
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
=======
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
    await categoryProvider.loadCategories();

    if (categoryProvider.expenseCategories.isNotEmpty) {
      setState(() {
        _selectedCategory = categoryProvider.expenseCategories.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
<<<<<<< HEAD
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w500)),
=======
            // Amount
            const Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'Rs ',
<<<<<<< HEAD
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Enter amount' : null,
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
=======
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
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
<<<<<<< HEAD
=======
                hint: const Text('Select category'),
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
                items: categoryProvider.expenseCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text('${category.icon} ${category.name}'),
                  );
                }).toList(),
<<<<<<< HEAD
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What was this for?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: _paymentMethods.map((method) {
                return Expanded(
                  child: RadioListTile<String>(
                    title: Text(method, style: const TextStyle(fontSize: 12)),
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                    contentPadding: EdgeInsets.zero,
=======
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What is this expense for?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Method
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
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
                  ),
                );
              }).toList(),
            ),
<<<<<<< HEAD
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('SAVE EXPENSE'),
=======
            const SizedBox(height: 16),

            // Date
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
                    const Icon(Icons.calendar_today, color: AppColors.textSecondary),
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

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SAVE TRANSACTION'),
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
<<<<<<< HEAD
      setState(() => _isLoading = true);
=======
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      final amount = double.parse(_amountController.text);

      if (amount > transactionProvider.currentBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
      try {
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.expense,
<<<<<<< HEAD
          amount: double.parse(_amountController.text),
=======
          amount: amount,
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
          category: _selectedCategory!.name,
          description: _descriptionController.text,
          date: _selectedDate,
          paymentMethod: _selectedPaymentMethod,
        );

<<<<<<< HEAD
        await Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
=======
        await transactionProvider.addTransaction(transaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
>>>>>>> 04dddb84a6e13f1f04626f80d1dc7887fec4c35a
}