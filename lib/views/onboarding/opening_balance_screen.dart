import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import 'business_name_screen.dart';

class OpeningBalanceScreen extends StatefulWidget {
  final String userName;
  final String currency;

  const OpeningBalanceScreen({
    super.key,
    required this.userName,
    required this.currency,
  });

  @override
  State<OpeningBalanceScreen> createState() => _OpeningBalanceScreenState();
}

class _OpeningBalanceScreenState extends State<OpeningBalanceScreen> {
  final _balanceController = TextEditingController();
  String _selectedAccountType = 'Cash in Hand';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Opening Balance'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let\'s set up your starting cash',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account balance is currently 0. Add your initial cash to get started.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<String>(
                  value: _selectedAccountType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: AppConstants.accountTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Opening Balance *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter opening balance',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessNameScreen(
                              userName: widget.userName,
                              currency: widget.currency,
                              openingBalance: 0,
                              accountType: _selectedAccountType,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final balance = double.tryParse(_balanceController.text) ?? 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessNameScreen(
                              userName: widget.userName,
                              currency: widget.currency,
                              openingBalance: balance,
                              accountType: _selectedAccountType,
                            ),
                          ),
                        );
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }
}