import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/colors.dart';
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
    // Load data after first frame to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_isInitialized) return;

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    await transactionProvider.loadTransactions();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _showProfileSheet() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileBottomSheet(
        userProvider: userProvider,
        transactionProvider: transactionProvider,
      ),
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
      _buildHomeScreen(userProvider.user!, transactionProvider),
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
      floatingActionButton: _currentIndex == 0
          ? _buildFloatingButton()
          : null,
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
          onPressed: () {
            setState(() {
              _showAddMenu = !_showAddMenu;
            });
          },
          backgroundColor: AppColors.secondary,
          elevation: 4,
          child: Icon(
            _showAddMenu ? Icons.close : Icons.add,
            color: Colors.white,
            size: 28,
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showAddMenu = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _getTransactionScreen(action['path'] as String),
                ),
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
                  Text(
                    action['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: action['color'] as Color,
                    ),
                  ),
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
      case 'income':
        return const IncomeScreen();
      case 'expense':
        return const ExpenseScreen();
      case 'credit_sale':
        return const CreditSaleScreen();
      case 'credit_payment':
        return const CreditPaymentScreen();
      default:
        return const TransactionTypeScreen();
    }
  }

  Widget _buildHomeScreen(dynamic user, TransactionProvider transactionProvider) {
    final pendingCredits = transactionProvider.transactions
        .where((t) => t.type == TransactionType.creditSale && !t.isPaid)
        .toList();
    final overdueCredits = pendingCredits.where((c) =>
    c.dueDate != null && c.dueDate!.isBefore(DateTime.now())).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Gradient Background
            _buildHeader(user, overdueCredits),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Income Today',
                          value: transactionProvider.todaySummary['income'] ?? 0,
                          icon: Icons.trending_down,
                          color: AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Expense Today',
                          value: transactionProvider.todaySummary['expense'] ?? 0,
                          icon: Icons.trending_up,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Balance Card
                  _buildBalanceCard(transactionProvider),
                  const SizedBox(height: 20),
                  // Recent Transactions
                  _buildRecentTransactions(transactionProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, List<TransactionModel> overdueCredits) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A4D8C),
            Color(0xFF1E3A8A),
            Color(0xFF1E1B4B),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hi ${user.name}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user.businessName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showProfileSheet,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A4D8C),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (overdueCredits.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildOverdueWarning(overdueCredits),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A4D8C),
            Color(0xFF1E3A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4D8C).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Available Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rs ${provider.currentBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Credit Outstanding:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs ${provider.creditOutstanding.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.credit,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueWarning(List<TransactionModel> overdueCredits) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overdueCredits.length} Overdue Payment${overdueCredits.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overdueCredits.length == 1
                      ? '${overdueCredits[0].customerName} - Due: ${overdueCredits[0].dueDate!.day}/${overdueCredits[0].dueDate!.month}/${overdueCredits[0].dueDate!.year}'
                      : 'Tap to view and settle overdue payments',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreditPaymentScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'VIEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionProvider provider) {
    final recent = provider.getRecentTransactions(limit: 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first transaction',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          )
        else
          Column(
            children: recent.map((transaction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionItem(
                  transaction: transaction,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ProfileBottomSheet class remains the same as before
class ProfileBottomSheet extends StatelessWidget {
  final UserProvider userProvider;
  final TransactionProvider transactionProvider;

  const ProfileBottomSheet({
    super.key,
    required this.userProvider,
    required this.transactionProvider,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A4D8C).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.businessName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Balance',
                          value: transactionProvider.currentBalance,
                          icon: Icons.account_balance_wallet,
                          color: const Color(0xFF1A4D8C),
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Transactions',
                          value: transactionProvider.transactions.length.toDouble(),
                          icon: Icons.receipt,
                          color: const Color(0xFF2E7D32),
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Credit',
                          value: transactionProvider.creditOutstanding,
                          icon: Icons.credit_card,
                          color: const Color(0xFFF97316),
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                _buildMenuTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.business_outlined,
                  title: 'Business Details',
                  subtitle: 'Manage business information',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Business details - Coming soon')),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help - Coming soon')),
                    );
                  },
                ),
                const Divider(),
                _buildMenuTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  subtitle: 'Sign out from your account',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    userProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                            (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  '© 2025 SmallBiz Accounts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFF1A4D8C).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF1A4D8C),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
    );
  }
}