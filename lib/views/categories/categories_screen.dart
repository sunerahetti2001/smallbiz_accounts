import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/gradient_background.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    await provider.loadCategories(userProvider.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      body: Column(
        children: [
          GradientBackground(
            hasBottomRadius: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categories', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Manage your income and expense categories', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
          ),
          TabBar(controller: _tabController, indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary, tabs: const [Tab(text: 'EXPENSE'), Tab(text: 'INCOME')]),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(categories: provider.expenseCategories, type: CategoryType.expense),
                _buildCategoryList(categories: provider.incomeCategories, type: CategoryType.income),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddCategoryScreen(type: _tabController.index == 0 ? CategoryType.expense : CategoryType.income))).then((_) => _loadCategories()),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList({required List<CategoryModel> categories, required CategoryType type}) {
    if (categories.isEmpty) return const Center(child: Text('No categories yet'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          child: ListTile(
            leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
            title: Text(category.name),
            subtitle: Text(category.isDefault ? 'Default' : 'Custom'),
            trailing: category.isDefault ? null : IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(category)),
          ),
        );
      },
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    await provider.deleteCategory(category.id, userProvider.user!.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
