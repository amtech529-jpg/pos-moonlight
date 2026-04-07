import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';

class DeleteVendorDialog extends StatefulWidget {
  final VendorModel vendor;

  const DeleteVendorDialog({
    super.key,
    required this.vendor,
  });

  @override
  State<DeleteVendorDialog> createState() => _DeleteVendorDialogState();
}

class _DeleteVendorDialogState extends State<DeleteVendorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isPermanentDelete = false;
  bool _confirmationChecked = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDelete() async {
    if (!_confirmationChecked) {
      _showErrorSnackbar("Please confirm the checkbox first.");
      return;
    }

    _processDelete();
  }

  Future<void> _processDelete() async {
    final provider = Provider.of<VendorProvider>(context, listen: false);

    bool success;
    if (_isPermanentDelete) {
      success = await provider.deleteVendor(widget.vendor.id);
    } else {
      success = await provider.softDeleteVendor(widget.vendor.id);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isPermanentDelete
              ? "Vendor Deleted Permanently"
              : "Vendor Deactivated Successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        final error = provider.errorMessage?.toLowerCase() ?? "";
        if (error.contains("use") ||
            error.contains("purchase") ||
            error.contains("foreign")) {
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
                "This vendor is linked to records and cannot be permanently deleted. Would you like to deactivate it instead?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
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
                    child: const Text("Yes, Deactivate",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
                ],
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

                  // Vendor Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.vendor.displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon),
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
                        onTap: () => setState(() {
                          _isPermanentDelete = false;
                          _confirmationChecked = false;
                        }),
                      ),
                      const SizedBox(width: 12),
                      _ModeBtn(
                        title: "Permanent",
                        isSelected: _isPermanentDelete,
                        color: Colors.red,
                        onTap: () => setState(() {
                          _isPermanentDelete = true;
                          _confirmationChecked = false;
                        }),
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
                      border: Border.all(
                          color: (_isPermanentDelete ? Colors.red : Colors.orange).withOpacity(0.1)),
                    ),
                    child: Text(
                      _isPermanentDelete
                          ? "Warning: This vendor and all related history will be permanently erased."
                          : "Archive: This will hide the vendor but keep all existing data safe.",
                      style: TextStyle(
                          fontSize: 13,
                          color: (_isPermanentDelete ? Colors.red : Colors.orange[800]),
                          fontWeight: FontWeight.w500),
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
                          backgroundColor: Colors.grey[600],
                          textColor: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<VendorProvider>(
                          builder: (context, provider, child) {
                            return PremiumButton(
                              text: _isPermanentDelete ? "Delete" : "Confirm",
                              onPressed: provider.isLoading ? null : _handleDelete,
                              isLoading: provider.isLoading,
                              backgroundColor: _isPermanentDelete ? Colors.red : Colors.orange,
                              height: 48,
                            );
                          },
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

  const _ModeBtn({
    required this.title,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

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
            border: Border.all(
                color: isSelected ? color : Colors.grey[400]!,
                width: isSelected ? 2 : 1),
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
