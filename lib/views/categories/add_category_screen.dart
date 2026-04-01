import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../utils/colors.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryType type;

  const AddCategoryScreen({
    super.key,
    required this.type,
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = '📦';
  bool _isLoading = false;

  final List<String> _emojis = [
    '💰', '💵', '📝', '🛒', '🌾', '🌽', '🫘', '🍚', '🥥',
    '⚡', '⛽', '🏠', '👥', '☕', '🚗', '📱', '🏛️', '🔧',
    '💡', '💧', '📦', '🛍️', '🏪', '🧾', '📊', '💹', '💳',
    '🍕', '🥤', '📚', '✏️', '🎁', '🔨', '🧹', '🧺', '🪴',
  ];

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = widget.type == CategoryType.expense
        ? AppColors.expense
        : AppColors.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add ${widget.type == CategoryType.expense ? 'Expense' : 'Income'} Category',
        ),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Name
            const Text(
              'Category Name',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Electricity, Sales, Rent',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter category name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Icon Selection
            const Text(
              'Choose Icon',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Selected icon preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Selected Icon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _selectedIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emoji grid
            Container(
              height: 250,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = emoji;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIcon == emoji
                            ? categoryColor
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedIcon == emoji
                              ? categoryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ADD CATEGORY'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final category = CategoryModel(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          type: widget.type,
          icon: _selectedIcon,
          isDefault: false,
        );

        await Provider.of<CategoryProvider>(
          context,
          listen: false,
        ).addCategory(category);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${category.name} added successfully'),
              backgroundColor: AppColors.success,
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
    _nameController.dispose();
    super.dispose();
  }
}