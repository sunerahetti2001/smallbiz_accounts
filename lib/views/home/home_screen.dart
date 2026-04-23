import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_item.dart';
import '../transactions/transaction_type_screen.dart';
import '../transactions/credit_payment_screen.dart';
import '../categories/categories_screen.dart';
import '../reports/comparison_screen.dart';
import '../reports/three_month_analysis_screen.dart';
import '../reports/monthly_statements_screen.dart';
import '../profile/profile_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../transactions/income_screen.dart';
import '../transactions/expense_screen.dart';
import '../transactions/credit_sale_screen.dart';
import '../onboarding/email_auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showAddMenu = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions(userProvider.user!.id);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    if (userProvider.user == null || !_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      _buildHomeScreen(userProvider, transactionProvider),
      const CategoriesScreen(),
      const ComparisonScreen(),
      const ThreeMonthAnalysisScreen(),
      const MonthlyStatementsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _showAddMenu = false;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0 ? _buildFloatingButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_showAddMenu) _buildQuickActionsMenu(),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () => setState(() => _showAddMenu = !_showAddMenu),
          backgroundColor: AppColors.secondary,
          child: Icon(_showAddMenu ? Icons.close : Icons.add, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _buildQuickActionsMenu() {
    final actions = [
      {'label': 'Income', 'path': 'income', 'icon': Icons.trending_up, 'color': AppColors.income},
      {'label': 'Expense', 'path': 'expense', 'icon': Icons.trending_down, 'color': AppColors.expense},
      {'label': 'Credit Sale', 'path': 'credit_sale', 'icon': Icons.receipt, 'color': AppColors.credit},
      {'label': 'Payment', 'path': 'credit_payment', 'icon': Icons.payment, 'color': AppColors.primary},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () {
              setState(() => _showAddMenu = false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _getTransactionScreen(action['path'] as String)),
              ).then((_) => _loadData());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: (action['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action['icon'] as IconData, color: action['color'] as Color, size: 18),
                  const SizedBox(width: 8),
                  Text(action['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: action['color'] as Color)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getTransactionScreen(String path) {
    switch (path) {
      case 'income': return const IncomeScreen();
      case 'expense': return const ExpenseScreen();
      case 'credit_sale': return const CreditSaleScreen();
      case 'credit_payment': return const CreditPaymentScreen();
      default: return const TransactionTypeScreen();
    }
  }

  Widget _buildHomeScreen(UserProvider userProvider, TransactionProvider transactionProvider) {
    final user = userProvider.user!;
    final pendingCredits = transactionProvider.transactions
        .where((t) => t.type == TransactionType.creditSale && !t.isPaid)
        .toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user),
            if (userProvider.isGuest) _buildGuestReminder(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: StatCard(title: 'Income Today', value: transactionProvider.todaySummary['income'] ?? 0, icon: Icons.trending_up, color: AppColors.income)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: 'Expense Today', value: transactionProvider.todaySummary['expense'] ?? 0, icon: Icons.trending_down, color: AppColors.expense)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBalanceCard(transactionProvider),
                  
                  if (pendingCredits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildPendingCreditsSection(pendingCredits),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildRecentTransactions(transactionProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestReminder(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Using as Guest. Connect an account to save your data permanently.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
            child: const Text('CONNECT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,', style: TextStyle(fontSize: 14, color: Colors.white70)),
                Text('Hi ${user.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(user.businessName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            GestureDetector(
              onTap: _showProfileSheet,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A4D8C))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Rs ${provider.currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Credit:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              Text('Rs ${provider.creditOutstanding.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCreditsSection(List<TransactionModel> credits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pending Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditPaymentScreen())),
              child: const Text('VIEW ALL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: credits.length,
            itemBuilder: (context, index) {
              final credit = credits[index];
              final bool isOverdue = credit.dueDate != null && credit.dueDate!.isBefore(DateTime.now());
              
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isOverdue ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(credit.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text('Rs ${credit.amount.toStringAsFixed(2)}', style: TextStyle(color: isOverdue ? Colors.red : AppColors.credit, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (credit.dueDate != null)
                      Text(
                        'Due: ${credit.dueDate!.day}/${credit.dueDate!.month}',
                        style: TextStyle(fontSize: 11, color: isOverdue ? Colors.red : Colors.grey),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(TransactionProvider provider) {
    final recent = provider.getRecentTransactions(limit: 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (recent.isEmpty) const Center(child: Text('No transactions yet'))
        else ...recent.map((t) => TransactionItem(transaction: t)),
      ],
    );
  }
}

class ProfileBottomSheet extends StatelessWidget {
  const ProfileBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user!;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 40, child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 32))),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user.businessName, style: TextStyle(color: Colors.grey[600])),
          const Divider(height: 40),
          if (userProvider.isGuest)
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text('Connect Account'),
              subtitle: const Text('Save your data to the cloud'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuthScreen()));
              },
            ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              bool clearData = false;
              if (userProvider.isGuest) {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout Warning'),
                    content: const Text('You are using a guest account. Your data will be permanently cleared if you logout without connecting an account. Do you wish to continue?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOGOUT & CLEAR', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (result != true) return;
                clearData = true;
              }
              
              await userProvider.logout(clearGuestData: clearData);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
