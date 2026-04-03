import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/labor/labor_model.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/confirmation_dialog.dart';

class LaborTableHelpers {
  final Function(LaborModel) onEdit;
  final Function(LaborModel) onDelete;
  final Function(LaborModel) onView;

  LaborTableHelpers({required this.onEdit, required this.onDelete, required this.onView});

  /// Build the actions row for each labor in the table
  Widget buildActionsRow(BuildContext context, LaborModel labor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onView(labor),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(Icons.visibility_outlined, color: Colors.purple, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(labor),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDelete(labor),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Quick Actions Dropdown
        PopupMenuButton<String>(
          onSelected: (value) => _handleQuickAction(context, labor, value),
          itemBuilder: (context) => _buildQuickActionMenuItems(context, labor),
          child: Container(
            padding: EdgeInsets.all(context.smallPadding * 0.5),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(Icons.more_vert, color: Colors.grey[600], size: context.iconSize('small')),
          ),
        ),
      ],
    );
  }

  /// Build quick action menu items based on labor state
  List<PopupMenuEntry<String>> _buildQuickActionMenuItems(BuildContext context, LaborModel labor) {
    final l10n = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<String>>[];

    // Status change actions
    if (labor.isActive) {
      items.add(
        PopupMenuItem(
          value: 'soft_delete',
          child: Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.orange, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(l10n.deactivate, style: TextStyle(fontSize: context.captionFontSize)),
            ],
          ),
        ),
      );
    } else {
      items.add(
        PopupMenuItem(
          value: 'restore',
          child: Row(
            children: [
              Icon(Icons.restore, color: Colors.green, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(l10n.restore, style: TextStyle(fontSize: context.captionFontSize)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  /// Handle quick action selection
  void _handleQuickAction(BuildContext context, LaborModel labor, String action) async {
    final provider = context.read<LaborProvider>();

    switch (action) {
      case 'soft_delete':
        await _handleSoftDelete(context, provider, labor);
        break;
      case 'restore':
        await _handleRestore(context, provider, labor);
        break;
    }
  }

  /// Handle soft delete (deactivate)
  Future<void> _handleSoftDelete(BuildContext context, LaborProvider provider, LaborModel labor) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: l10n.deactivateLabor,
            message: l10n.areYouSureDeactivateLabor(labor.name),
            actionText: l10n.deactivate,
            actionColor: Colors.orange,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.softDeleteLabor(labor.id);
      if (provider.hasError) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToDeactivateLabor);
      } else if (success) {
        _showSuccessSnackbar(context, l10n.laborDeactivatedSuccessfully);
      }
    }
  }

  /// Handle restore labor
  Future<void> _handleRestore(BuildContext context, LaborProvider provider, LaborModel labor) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ConfirmationDialog(
            title: l10n.restoreLabor,
            message: l10n.areYouSureRestoreLabor(labor.name),
            actionText: l10n.restore,
            actionColor: Colors.green,
          ),
        ) ??
            false;

    if (confirmed) {
      final success = await provider.restoreLabor(labor.id);
      if (provider.hasError) {
        _showErrorSnackbar(context, provider.errorMessage ?? l10n.failedToRestoreLabor);
      } else if (success) {
        _showSuccessSnackbar(context, l10n.laborRestoredSuccessfully);
      }
    }
  }

  /// Show success snackbar
  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              message,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  /// Build error state widget
  Widget buildErrorState(BuildContext context, LaborProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            height: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(Icons.error_outline, size: context.iconSize('xl'), color: Colors.red[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.failedToLoadLabors,
            style: TextStyle(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(
                context,
                tablet: 80.w,
                small: 70.w,
                medium: 60.w,
                large: 50.w,
                ultrawide: 40.w,
              ),
            ),
            child: Text(
              provider.errorMessage ?? l10n.unexpectedErrorOccurred,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.mainPadding),

          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  provider.clearError();
                  provider.refreshLabors();
                },
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.cardPadding * 0.6,
                    vertical: context.cardPadding / 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.pureWhite,
                        size: context.iconSize('medium'),
                      ),
                      SizedBox(width: context.smallPadding),
                      Text(
                        l10n.retry,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pureWhite,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            height: ResponsiveBreakpoints.responsive(
              context,
              tablet: 15.w,
              small: 20.w,
              medium: 12.w,
              large: 10.w,
              ultrawide: 8.w,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(Icons.engineering_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noLaborsFound,
            style: TextStyle(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(
                context,
                tablet: 80.w,
                small: 70.w,
                medium: 60.w,
                large: 50.w,
                ultrawide: 40.w,
              ),
            ),
            child: Text(
              l10n.startByAddingFirstLabor,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

        ],
      ),
    );
  }

  /// Get status color based on status string
  Color getStatusColor(String status) {
    if (status.toLowerCase() == 'active') {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}
