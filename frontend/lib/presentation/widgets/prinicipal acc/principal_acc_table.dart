import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/prinicipal_acc_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/models/principal_account/principal_account_model.dart';
import '../../../l10n/app_localizations.dart';

class PrincipalAccountTable extends StatefulWidget {
  final Function(PrincipalAccount) onEdit;
  final Function(PrincipalAccount) onDelete;
  final Function(PrincipalAccount) onView;

  const PrincipalAccountTable({super.key, required this.onEdit, required this.onDelete, required this.onView});

  @override
  State<PrincipalAccountTable> createState() => _PrincipalAccountTableState();
}

class _PrincipalAccountTableState extends State<PrincipalAccountTable> {
  // Define separate controllers for robust scrolling (copied from purchases table)
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Link the header and content scrolling (Two-way sync) - copied from purchases table
    _headerHorizontalController.addListener(() {
      if (_contentHorizontalController.hasClients &&
          _headerHorizontalController.offset != _contentHorizontalController.offset) {
        _contentHorizontalController.jumpTo(_headerHorizontalController.offset);
      }
    });

    _contentHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients &&
          _contentHorizontalController.offset != _headerHorizontalController.offset) {
        _headerHorizontalController.jumpTo(_contentHorizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _contentHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum size
          children: [
            Consumer<PrincipalAccountProvider>(
              builder: (context, provider, _) => _buildBalanceHeader(context, provider),
            ),
            // --- Table Header (Fixed Top) ---
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightGray.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Container(
                  width: _calculateTotalWidth(),
                  padding: EdgeInsets.symmetric(
                    vertical: context.cardPadding * 0.75,
                  ),
                  child: _buildTableHeader(context),
                ),
              ),
            ),

            // --- Table Body (Scrollable Vertical & Horizontal) ---
            Flexible( // Use Flexible instead of Expanded
              child: Consumer<PrincipalAccountProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(
                      child: SizedBox(
                        width: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
                        height: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
                        child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
                      ),
                    );
                  }

                  if (provider.accounts.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        controller: _contentHorizontalController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) => notification.depth == 1,
                        child: SingleChildScrollView(
                          controller: _contentHorizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: Container(
                            width: _calculateTotalWidth(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Use minimum size
                              children: provider.accounts.asMap().entries.map((entry) {
                                return _buildTableRow(context, entry.value, entry.key);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, PrincipalAccountProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentBalance,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.pureWhite.withOpacity(0.9),
                  ),
                ),
                Text(
                  'PKR ${provider.currentBalance?.currentBalance.toStringAsFixed(0) ?? '0'}',
                  style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w700, color: AppTheme.pureWhite),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Text(
              '${provider.accounts.length} ${l10n.transactions}',
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  // --- Configuration ---
  // Define exact widths for columns to ensure alignment (copied from purchases table)
  List<double> get _colWidths => [
    130.0, // Entry ID
    150.0, // Source Module
    300.0, // Description
    120.0, // Type
    140.0, // Amount
    150.0, // Balance After
    160.0, // Handled By
    130.0, // Date
    120.0, // Time
    260.0, // Actions
  ];

  double _calculateTotalWidth() => _colWidths.reduce((a, b) => a + b);

  double _getTableWidth(BuildContext context) {
    return _calculateTotalWidth();
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(width: columnWidths[0], child: _buildHeaderCell(context, l10n.entryID)),
        Container(width: columnWidths[1], child: _buildHeaderCell(context, l10n.sourceModule)),
        Container(width: columnWidths[2], child: _buildHeaderCell(context, l10n.description)),
        Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.type)),
        Container(width: columnWidths[4], child: _buildHeaderCell(context, l10n.amount)),
        Container(width: columnWidths[5], child: _buildHeaderCell(context, l10n.balanceAfter)),
        Container(width: columnWidths[6], child: _buildHeaderCell(context, l10n.handledBy)),
        Container(width: columnWidths[7], child: _buildHeaderCell(context, l10n.date)),
        Container(width: columnWidths[8], child: _buildHeaderCell(context, l10n.time)),
        Container(width: columnWidths[9], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    return _colWidths;
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, PrincipalAccount account, int index) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2.5),
      child: Row(
        children: [
          // Entry ID
          Container(
            width: columnWidths[0],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              account.id,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
            ),
          ),

          // Source Module
          Container(
            width: columnWidths[1],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getSourceModuleIcon(account.sourceModule), color: account.sourceModuleColor, size: context.iconSize('small')),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    account.sourceModule.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: account.sourceModuleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Description
          Container(
            width: columnWidths[2],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              account.description,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Type
          Container(
            width: columnWidths[3],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(account.typeIcon, color: account.typeColor, size: context.iconSize('small')),
                const SizedBox(width: 4),
                Text(
                  account.type.toUpperCase(),
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w700, color: account.typeColor),
                ),
              ],
            ),
          ),

          // Amount
          Container(
            width: columnWidths[4],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'PKR ${account.amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: account.typeColor),
            ),
          ),

          // Balance After
          Container(
            width: columnWidths[5],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'PKR ${account.balanceAfter.toStringAsFixed(0)}',
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: Colors.blue[700]),
            ),
          ),

          // Handled By
          Container(
            width: columnWidths[6],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: account.handledBy != null
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: _getPersonColor(account.handledBy!), shape: BoxShape.circle),
                  child: Icon(Icons.person, color: AppTheme.pureWhite, size: 10),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    account.handledBy!,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: _getPersonColor(account.handledBy!),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
                : Text('-', style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey)),
          ),

          // Date
          Container(
            width: columnWidths[7],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.formattedDate,
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                Text(
                  account.relativeDate,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Time
          Container(
            width: columnWidths[8],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, color: Colors.purple, size: context.iconSize('small')),
                const SizedBox(width: 4),
                Text(
                  account.formattedTime,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.purple),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            width: columnWidths[9],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildActions(context, account),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, PrincipalAccount account) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onView(account),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.visibility_outlined, color: Colors.purple, size: context.iconSize('small')),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding / 2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onEdit(account),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding / 2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l10n.exportAccountEntry} ${account.id}'), backgroundColor: Colors.green),
              );
            },
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.download_outlined, color: Colors.green, size: context.iconSize('small')),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding / 2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDelete(account),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView( // Add SingleChildScrollView to prevent overflow
        child: ConstrainedBox( // Constrain the content
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5, // Max 50% of screen height
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use minimum size
            children: [
              Container(
                width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
                height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
                decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
                child: Icon(Icons.account_balance_wallet_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
              ),
              SizedBox(height: context.mainPadding),
              Text(
                l10n.noPrincipalAccountRecordsFound,
                style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              SizedBox(height: context.smallPadding),
              Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
                ),
                child: Text(
                  l10n.startByAddingYourFirstPrincipalAccountEntry,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSourceModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case 'sales':
        return Icons.point_of_sale_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'advance_payment':
        return Icons.schedule_send_rounded;
      case 'expenses':
        return Icons.receipt_long_rounded;
      case 'receivables':
        return Icons.account_balance_outlined;
      case 'payables':
        return Icons.money_off_outlined;
      case 'zakat':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getPersonColor(String person) {
    switch (person) {
      case 'Shahzain Baloch':
        return Colors.blue;
      case 'Huzaifa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
