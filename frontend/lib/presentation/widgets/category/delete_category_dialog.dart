import 'package:flutter/material.dart';
import 'package:frontend/src/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/category_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_button.dart';

class DeleteCategoryDialog extends StatefulWidget {
  final Category category;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPermanentDelete = false; 
  bool _confirmationChecked = false;
  int _usageCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    // Check usage count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final productProvider = context.read<ProductProvider>();
        final count = productProvider.allProducts
            .where((p) => p.categoryId == widget.category.id)
            .length;
        setState(() {
          _usageCount = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    if (!_confirmationChecked) {
      _showErrorSnackbar("Confirm the checkbox first.");
      return;
    }

    if (_isPermanentDelete && _usageCount > 0) {
      _showSoftDeleteSuggestion();
      return;
    }

    _processDelete();
  }

  Future<void> _processDelete() async {
    final provider = Provider.of<CategoryProvider>(context, listen: false);

    bool success;
    if (_isPermanentDelete) {
      success = await provider.deleteCategory(widget.category.id);
    } else {
      success = await provider.softDeleteCategory(widget.category.id);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isPermanentDelete ? "Deleted Permanently" : "Deactivated Successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        final error = provider.errorMessage?.toLowerCase() ?? "";
        if (error.contains("use") || error.contains("product") || error.contains("foreign")) {
          _showSoftDeleteSuggestion();
        } else {
          _showErrorSnackbar(provider.errorMessage ?? "Action failed");
        }
      }
    }
  }

  void _showSoftDeleteSuggestion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 40),
              const SizedBox(height: 16),
              const Text(
                "Action Required",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              const Text(
                "This category is in use and cannot be permanently deleted. Would you like to deactivate it instead?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _isPermanentDelete = false);
                      _processDelete();
                    },
                    child: const Text("Yes, Deactivate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPermanentDelete ? Icons.delete_forever : Icons.visibility_off,
                      color: _isPermanentDelete ? Colors.red : Colors.orange,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    _isPermanentDelete ? "Permanent Delete" : "Deactivate",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),

                  // Category Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode Toggle
                  Row(
                    children: [
                      _ModeBtn(
                        title: "Soft Delete",
                        isSelected: !_isPermanentDelete,
                        color: Colors.orange,
                        onTap: () => setState(() => _isPermanentDelete = false),
                      ),
                      const SizedBox(width: 12),
                      _ModeBtn(
                        title: "Permanent",
                        isSelected: _isPermanentDelete,
                        color: Colors.red,
                        onTap: () => setState(() => _isPermanentDelete = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Warning Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1)),
                    ),
                    child: Text(
                      _isPermanentDelete 
                        ? "Warning: This category and its history will be erased forever."
                        : "Archive: This will hide the category but keep old data safe.",
                      style: TextStyle(fontSize: 13, color: (_isPermanentDelete ? Colors.red : Colors.orange[800]), fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirmation checkbox
                  InkWell(
                    onTap: () => setState(() => _confirmationChecked = !_confirmationChecked),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _confirmationChecked,
                          onChanged: (v) => setState(() => _confirmationChecked = v ?? false),
                          activeColor: _isPermanentDelete ? Colors.red : Colors.orange,
                        ),
                        const Text(
                          "I confirm this action",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: PremiumButton(
                          text: "Cancel",
                          onPressed: () => Navigator.pop(context),
                          isOutlined: true,
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PremiumButton(
                          text: _isPermanentDelete ? "Delete" : "Confirm",
                          onPressed: _handleDelete,
                          backgroundColor: _isPermanentDelete ? Colors.red : Colors.orange,
                          height: 48,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeBtn({required this.title, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : Colors.grey[400]!, width: isSelected ? 2 : 1),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isSelected ? color : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
