import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/colors.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryType type;
  const AddCategoryScreen({super.key, required this.type});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = '📦';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Category Name'), validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCategory,
              child: _isLoading ? const CircularProgressIndicator() : const Text('ADD CATEGORY'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user!.id;
        final category = CategoryModel(id: const Uuid().v4(), name: _nameController.text.trim(), type: widget.type, icon: _selectedIcon, isDefault: false);
        await Provider.of<CategoryProvider>(context, listen: false).addCategory(category, userId);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
