import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../utils/colors.dart';
import '../../utils/currency_formatter.dart';
import '../../services/notification_service.dart';
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

    if (userProvider.user == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );
      }
      return;
    }

    debugPrint('HomeScreen: Loading transactions for user ${userProvider.user!.id}');
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

    if (userProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final actions = [
      {'label': localizations.income, 'path': 'income', 'icon': Icons.trending_up, 'color': AppColors.income},
      {'label': localizations.expense, 'path': 'expense', 'icon': Icons.trending_down, 'color': AppColors.expense},
      {'label': localizations.creditSale, 'path': 'credit_sale', 'icon': Icons.receipt, 'color': AppColors.credit},
      {'label': localizations.creditPayment, 'path': 'credit_payment', 'icon': Icons.payment, 'color': AppColors.primary},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(screenWidth < 360 ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Wrap(
        spacing: screenWidth < 360 ? 6 : 12,
        runSpacing: screenWidth < 360 ? 6 : 12,
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
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 360 ? 10 : 16,
                vertical: screenWidth < 360 ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: (action['color'] as Color).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action['icon'] as IconData, color: action['color'] as Color, size: screenWidth < 360 ? 16 : 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: action['color'] as Color,
                      ),
                      overflow: TextOverflow.ellipsis,
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
      case 'income': return const IncomeScreen();
      case 'expense': return const ExpenseScreen();
      case 'credit_sale': return const CreditSaleScreen();
      case 'credit_payment': return const CreditPaymentScreen();
      default: return const TransactionTypeScreen();
    }
  }

  Widget _buildHomeScreen(UserProvider userProvider, TransactionProvider transactionProvider) {
    final user = userProvider.user!;
    final localizations = AppLocalizations.of(context);
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
            _buildHeader(user, localizations),
            if (userProvider.isGuest) _buildGuestReminder(context, localizations),
            _buildCreditNotifications(transactionProvider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: StatCard(title: localizations.incomeToday, value: transactionProvider.todaySummary['income'] ?? 0, icon: Icons.trending_up, color: AppColors.income)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: localizations.expenseToday, value: transactionProvider.todaySummary['expense'] ?? 0, icon: Icons.trending_down, color: AppColors.expense)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBalanceCard(transactionProvider, localizations),
                  if (pendingCredits.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildPendingCreditsSection(pendingCredits, localizations),
                  ],
                  const SizedBox(height: 24),
                  _buildRecentTransactions(transactionProvider, localizations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditNotifications(TransactionProvider transactionProvider) {
    final localizations = AppLocalizations.of(context);
    final notificationService = NotificationService();
    notificationService.checkCreditReminders(transactionProvider.transactions);
    final pendingNotifications = notificationService.notifications
        .where((n) => !(n['isDismissed'] as bool))
        .toList();

    if (pendingNotifications.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: pendingNotifications.take(3).map((notification) {
          final isOverdue = notification['isOverdue'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverdue ? Colors.red.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.info_outline,
                  color: isOverdue ? Colors.red : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOverdue ? localizations.overduePayment : localizations.paymentDueTomorrow,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isOverdue ? Colors.red : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${notification['customerName']} - Rs ${(notification['amount'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      notificationService.dismissNotification(notification['id'] as int);
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGuestReminder(BuildContext context, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.guestWarning,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmailAuthScreen(isLogin: false)),
              ).then((_) {
                _loadData();
              });
            },
            child: Text(localizations.connect, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic user, AppLocalizations localizations) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, screenWidth < 360 ? 36 : 48, 20, screenWidth < 360 ? 24 : 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizations.welcomeBack, style: TextStyle(fontSize: screenWidth < 360 ? 12 : 14, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    '${localizations.hi} ${user.name}',
                    style: TextStyle(
                      fontSize: screenWidth < 360 ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    user.businessName,
                    style: TextStyle(fontSize: screenWidth < 360 ? 10 : 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showProfileSheet,
              child: CircleAvatar(
                radius: screenWidth < 360 ? 24 : 28,
                backgroundColor: Colors.white,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A4D8C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(TransactionProvider provider, AppLocalizations localizations) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth < 360 ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.availableBalance,
            style: TextStyle(color: Colors.white70, fontSize: screenWidth < 360 ? 12 : 14),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs ${provider.currentBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth < 360 ? 26 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: Text(
                  '${localizations.creditOutstanding}:',
                  style: TextStyle(color: Colors.white70, fontSize: screenWidth < 360 ? 11 : 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Rs ${provider.creditOutstanding.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 360 ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCreditsSection(List<TransactionModel> credits, AppLocalizations localizations) {
    // Get all transactions to compute payments received per customer
    final allTransactions = Provider.of<TransactionProvider>(context, listen: false).transactions;

    // Total payments per customer
    final Map<String, double> paymentsByCustomer = {};
    for (var t in allTransactions) {
      if (t.type == TransactionType.creditPayment && t.customerName != null) {
        paymentsByCustomer[t.customerName!] = (paymentsByCustomer[t.customerName!] ?? 0) + t.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.pendingPayments, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditPaymentScreen())),
              child: Text(localizations.viewAll, style: const TextStyle(fontSize: 12)),
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

              // Calculate remaining amount for this customer
              final double totalPayments = paymentsByCustomer[credit.customerName] ?? 0;
              final double remaining = (credit.amount - totalPayments).clamp(0.0, credit.amount);

              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.customerName ?? localizations.selectCustomer,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'Rs ${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : AppColors.credit,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (credit.dueDate != null)
                      Text(
                        '${localizations.dueDate}: ${credit.dueDate!.day}/${credit.dueDate!.month}',
                        style: TextStyle(fontSize: 10, color: isOverdue ? Colors.red : Colors.grey),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildRecentTransactions(TransactionProvider provider, AppLocalizations localizations) {
    final recent = provider.getRecentTransactions(limit: 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.recentActivity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text(localizations.noTransactions, style: const TextStyle(color: Colors.grey))),
          )
        else
          ...recent.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TransactionItem(transaction: t),
          )),
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
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user.businessName, style: TextStyle(color: Colors.grey[600])),

          if (user.email != null && user.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(user.email!, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ],

          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                userProvider.isGuest ? Icons.person_outline : Icons.verified_user,
                size: 16,
                color: userProvider.isGuest ? Colors.amber : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                userProvider.isGuest ? 'Guest Account' : 'Connected Account',
                style: TextStyle(
                  fontSize: 13,
                  color: userProvider.isGuest ? Colors.amber : AppColors.success,
                ),
              ),
            ],
          ),

          const Divider(height: 40),

          if (userProvider.isGuest)
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: Text(localizations.connectAccount),
              subtitle: const Text('Save your data to the cloud'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailAuthScreen(isLogin: false)),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(localizations.editProfile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: Text(localizations.selectLanguage),
            onTap: () {
              Navigator.pop(context);
              _showLanguageDialog(context, localizations);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(localizations.logout, style: const TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              bool clearData = false;
              if (userProvider.isGuest) {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(localizations.warning),
                    content: Text(localizations.logoutWarning),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(localizations.cancel)),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text(localizations.logoutClear, style: const TextStyle(color: Colors.red))),
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

  void _showLanguageDialog(BuildContext context, AppLocalizations localizations) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(localizations.english),
                trailing: !languageProvider.isSinhala
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(dialogContext);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
                title: Text(localizations.sinhala),
                trailing: languageProvider.isSinhala
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage('si');
                  Navigator.pop(dialogContext);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        );
      },
    );
  }
}