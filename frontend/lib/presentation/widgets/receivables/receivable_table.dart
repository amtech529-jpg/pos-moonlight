import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/receivables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ReceivablesTable extends StatelessWidget {
  final Function(Receivable) onEdit;
  final Function(Receivable) onDelete;
  final Function(Receivable) onViewDetails;

  const ReceivablesTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.borderRadius('large')),
                topRight: Radius.circular(context.borderRadius('large')),
              ),
            ),
            child: _buildResponsiveHeaderRow(context),
          ),
          Expanded(
            child: Consumer<ReceivablesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: SizedBox(
                      width: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 8.w,
                        small: 6.w,
                        medium: 5.w,
                        large: 4.w,
                        ultrawide: 3.w,
                      ),
                      height: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 8.w,
                        small: 6.w,
                        medium: 5.w,
                        large: 4.w,
                        ultrawide: 3.w,
                      ),
                      child: const CircularProgressIndicator(
                        color: AppTheme.primaryMaroon,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                }

                if (provider.receivables.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  itemCount: provider.receivables.length,
                  itemBuilder: (context, index) {
                    final receivable = provider.receivables[index];
                    return _buildResponsiveTableRow(context, receivable, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveHeaderRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final receivableColumnFlexes = ResponsiveBreakpoints.responsive(
      context,
      tablet: [1, 2, 1, 1, 1, 1, 1, 1],
      small: [1, 2, 2, 1, 1, 1, 1, 1],
      medium: [1, 2, 2, 2, 1, 1, 1, 2],
      large: [1, 2, 2, 3, 2, 1, 1, 2],
      ultrawide: [1, 2, 2, 3, 2, 1, 1, 2],
    );

    return Row(
      children: [
        Expanded(
          flex: receivableColumnFlexes[0],
          child: _buildHeaderCell(context, l10n.id),
        ),
        Expanded(
          flex: receivableColumnFlexes[1],
          child: _buildHeaderCell(context, context.isTablet ? l10n.debtor : l10n.debtorDetails),
        ),
        Expanded(
          flex: receivableColumnFlexes[2],
          child: _buildHeaderCell(context, l10n.amounts),
        ),
        if (!context.shouldShowCompactLayout) ...[
          Expanded(
            flex: receivableColumnFlexes[3],
            child: _buildHeaderCell(context, l10n.reasonItem),
          ),
        ],
        if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
          Expanded(
            flex: receivableColumnFlexes[4],
            child: _buildHeaderCell(context, context.shouldShowFullLayout ? l10n.dates : l10n.returnDate),
          ),
        ],
        if (context.shouldShowFullLayout) ...[
          Expanded(
            flex: receivableColumnFlexes[5],
            child: _buildHeaderCell(context, l10n.progress),
          ),
        ],
        if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
          Expanded(
            flex: receivableColumnFlexes[6],
            child: _buildHeaderCell(context, l10n.status),
          ),
        ],
        Expanded(
          flex: receivableColumnFlexes[7],
          child: _buildHeaderCell(context, l10n.actions),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.bodyFontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.charcoalGray,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildResponsiveTableRow(BuildContext context, Receivable receivable, int index) {
    final l10n = AppLocalizations.of(context)!;

    final receivableColumnFlexes = ResponsiveBreakpoints.responsive(
      context,
      tablet: [1, 2, 1, 1, 1, 1, 1, 1],
      small: [1, 2, 2, 1, 1, 1, 1, 1],
      medium: [1, 2, 2, 2, 1, 1, 1, 2],
      large: [1, 2, 2, 3, 2, 1, 1, 2],
      ultrawide: [1, 2, 2, 3, 2, 1, 1, 2],
    );

    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2.5),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppTheme.pureWhite
            : AppTheme.lightGray.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: receivableColumnFlexes[0],
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding,
                vertical: context.smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                receivable.id,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryMaroon,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: context.smallPadding),

          Expanded(
            flex: receivableColumnFlexes[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receivable.debtorName,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (context.shouldShowCompactLayout) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    receivable.debtorPhone,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'PKR ${receivable.balanceRemaining.toStringAsFixed(0)} ${l10n.remaining}',
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: receivable.balanceRemaining > 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.smallPadding),

          Expanded(
            flex: receivableColumnFlexes[2],
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding,
                vertical: context.smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: Colors.blue,
                        size: context.iconSize('small'),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          'PKR ${receivable.amountGiven.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (!context.shouldShowCompactLayout && receivable.amountReturned > 0) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down_rounded,
                          color: Colors.green,
                          size: context.iconSize('small'),
                        ),
                        SizedBox(width: context.smallPadding / 2),
                        Expanded(
                          child: Text(
                            'PKR ${receivable.amountReturned.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: context.smallPadding),

          if (!context.shouldShowCompactLayout) ...[
            Expanded(
              flex: receivableColumnFlexes[3],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receivable.reasonOrItem,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.charcoalGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (receivable.notes != null && receivable.notes!.isNotEmpty) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      receivable.notes!,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
            Expanded(
              flex: receivableColumnFlexes[4],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receivable.formattedExpectedReturnDate,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: receivable.isOverdue ? Colors.red : AppTheme.charcoalGray,
                    ),
                  ),
                  if (context.shouldShowFullLayout) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      '${l10n.lent}: ${receivable.formattedDateLent}',
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  if (receivable.isOverdue) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      '${receivable.daysOverdue} ${l10n.daysOverdue}',
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          if (context.shouldShowFullLayout) ...[
            Expanded(
              flex: receivableColumnFlexes[5],
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: receivable.returnPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      receivable.isFullyPaid ? Colors.green : Colors.orange,
                    ),
                    minHeight: 6,
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    '${receivable.returnPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w500,
                      color: receivable.isFullyPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
            Expanded(
              flex: receivableColumnFlexes[6],
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: receivable.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(
                    color: receivable.statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: receivable.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Expanded(
                      child: Text(
                        receivable.statusText,
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w500,
                          color: receivable.statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          Expanded(
            flex: receivableColumnFlexes[7],
            child: ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildCompactActions(context, receivable),
              small: _buildCompactActions(context, receivable),
              medium: _buildStandardActions(context, receivable),
              large: _buildExpandedActions(context, receivable),
              ultrawide: _buildExpandedActions(context, receivable),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActions(BuildContext context, Receivable receivable) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit(receivable);
        } else if (value == 'delete') {
          onDelete(receivable);
        } else if (value == 'details') {
          onViewDetails(receivable);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.edit,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Colors.green,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.viewDetails,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.deleteText,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.all(context.smallPadding),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
        ),
        child: Icon(
          Icons.more_vert,
          size: context.iconSize('small'),
          color: AppTheme.charcoalGray,
        ),
      ),
    );
  }

  Widget _buildStandardActions(BuildContext context, Receivable receivable) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(receivable),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.blue,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onViewDetails(receivable),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.visibility_outlined,
                color: Colors.green,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDelete(receivable),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedActions(BuildContext context, Receivable receivable) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onEdit(receivable),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      l10n.edit,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding / 2),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onViewDetails(receivable),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: Colors.green,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      l10n.view,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding / 2),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDelete(receivable),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.smallPadding,
                  vertical: context.smallPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      l10n.deleteText,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 5.w,
              small: 5.w,
              medium: 5.w,
              large: 5.w,
              ultrawide: 5.w,
            ),
            height: ResponsiveBreakpoints.responsive(
              context,
              tablet: 5.w,
              small: 5.w,
              medium: 5.w,
              large: 5.w,
              ultrawide: 5.w,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: context.iconSize('xl'),
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.noReceivablesFound,
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
              l10n.startByAddingFirstReceivable,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
