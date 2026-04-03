import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payment/payment_model.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class PaymentTable extends StatelessWidget {
  final Function(PaymentModel) onEdit;
  final Function(PaymentModel) onDelete;
  final Function(PaymentModel) onViewReceipt;

  const PaymentTable({super.key, required this.onEdit, required this.onDelete, required this.onViewReceipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
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
            child: Consumer<PaymentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: SizedBox(
                      width: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
                      height: ResponsiveBreakpoints.responsive(context, tablet: 8.w, small: 6.w, medium: 5.w, large: 4.w, ultrawide: 3.w),
                      child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
                    ),
                  );
                }

                if (provider.payments.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  itemCount: provider.payments.length,
                  itemBuilder: (context, index) {
                    final payment = provider.payments[index];
                    return _buildResponsiveTableRow(context, payment, index);
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

    final paymentColumnFlexes = ResponsiveBreakpoints.responsive(
      context,
      tablet: [1, 2, 1, 1, 1, 1, 1, 1],
      small: [1, 2, 2, 1, 1, 1, 1, 1],
      medium: [1, 2, 2, 2, 1, 1, 1, 2],
      large: [1, 2, 2, 3, 2, 1, 1, 2],
      ultrawide: [1, 2, 2, 3, 2, 1, 1, 2],
    );

    return Row(
      children: [
        Expanded(flex: paymentColumnFlexes[0], child: _buildHeaderCell(context, l10n.id)),
        Expanded(flex: paymentColumnFlexes[1], child: _buildHeaderCell(context, context.isTablet ? l10n.labor : l10n.laborDetails)),
        Expanded(flex: paymentColumnFlexes[2], child: _buildHeaderCell(context, l10n.amount)),
        if (!context.shouldShowCompactLayout) ...[Expanded(flex: paymentColumnFlexes[3], child: _buildHeaderCell(context, l10n.paymentInfo))],
        if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
          Expanded(flex: paymentColumnFlexes[4], child: _buildHeaderCell(context, context.shouldShowFullLayout ? l10n.dateAndTime : l10n.date)),
        ],
        if (context.shouldShowFullLayout) ...[Expanded(flex: paymentColumnFlexes[5], child: _buildHeaderCell(context, l10n.receipt))],
        if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
          Expanded(flex: paymentColumnFlexes[6], child: _buildHeaderCell(context, l10n.status)),
        ],
        Expanded(flex: paymentColumnFlexes[7], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray, letterSpacing: 0.2),
    );
  }

  Widget _buildResponsiveTableRow(BuildContext context, PaymentModel payment, int index) {
    final l10n = AppLocalizations.of(context)!;

    final paymentColumnFlexes = ResponsiveBreakpoints.responsive(
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
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: paymentColumnFlexes[0],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                payment.id,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: context.smallPadding),

          Expanded(
            flex: paymentColumnFlexes[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.laborName ?? l10n.notAvailable,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (context.shouldShowCompactLayout) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    payment.laborRole ?? l10n.notAvailable,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'PKR ${payment.netAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: Colors.green),
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.smallPadding),

          Expanded(
            flex: paymentColumnFlexes[2],
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    'PKR ${payment.netAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  if (!context.shouldShowCompactLayout && (payment.bonus > 0 || payment.deduction > 0)) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (payment.bonus > 0) ...[
                          Text(
                            '+${payment.bonus.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.blue),
                          ),
                        ],
                        if (payment.bonus > 0 && payment.deduction > 0) Text(' | ', style: TextStyle(fontSize: context.captionFontSize)),
                        if (payment.deduction > 0) ...[
                          Text(
                            '-${payment.deduction.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.red),
                          ),
                        ],
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
              flex: paymentColumnFlexes[3],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(payment.paymentMethodIcon, color: payment.paymentMethodColor, size: context.iconSize('small')),
                      SizedBox(width: context.smallPadding / 2),
                      Expanded(
                        child: Text(
                          payment.paymentMethod,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            color: payment.paymentMethodColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    '${payment.paymentMonth.day}/${payment.paymentMonth.month}/${payment.paymentMonth.year}',
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
            Expanded(
              flex: paymentColumnFlexes[4],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(payment.date),
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                  ),
                  if (context.shouldShowFullLayout) ...[
                    SizedBox(height: context.smallPadding / 4),
                    Text(
                      payment.formattedTime,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          if (context.shouldShowFullLayout) ...[
            Expanded(
              flex: paymentColumnFlexes[5],
              child: Center(
                child: payment.hasReceipt
                    ? Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_rounded, color: Colors.green, size: context.iconSize('small')),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        l10n.available,
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.green),
                      ),
                    ],
                  ),
                )
                    : Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Colors.red, size: context.iconSize('small')),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        l10n.missing,
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: context.smallPadding),
          ],

          if (context.isMediumDesktop || context.shouldShowFullLayout) ...[
            Expanded(
              flex: paymentColumnFlexes[6],
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(
                  color: payment.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(color: payment.statusColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: payment.statusColor, shape: BoxShape.circle),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Expanded(
                      child: Text(
                        payment.statusText,
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: payment.statusColor),
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
            flex: paymentColumnFlexes[7],
            child: ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildCompactActions(context, payment),
              small: _buildCompactActions(context, payment),
              medium: _buildStandardActions(context, payment),
              large: _buildExpandedActions(context, payment),
              ultrawide: _buildExpandedActions(context, payment),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActions(BuildContext context, PaymentModel payment) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit(payment);
        } else if (value == 'delete') {
          onDelete(payment);
        } else if (value == 'receipt') {
          onViewReceipt(payment);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.edit,
                style: TextStyle(fontSize: context.captionFontSize, color: Colors.blue),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'receipt',
          child: Row(
            children: [
              Icon(
                payment.hasReceipt ? Icons.visibility_outlined : Icons.add_photo_alternate_outlined,
                color: payment.hasReceipt ? Colors.green : Colors.orange,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                payment.hasReceipt ? l10n.viewReceipt : l10n.addReceipt,
                style: TextStyle(fontSize: context.captionFontSize, color: payment.hasReceipt ? Colors.green : Colors.orange),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.delete,
                style: TextStyle(fontSize: context.captionFontSize, color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.all(context.smallPadding),
        decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('small'))),
        child: Icon(Icons.more_vert, size: context.iconSize('small'), color: AppTheme.charcoalGray),
      ),
    );
  }

  Widget _buildStandardActions(BuildContext context, PaymentModel payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onEdit(payment),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onViewReceipt(payment),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(
                color: payment.hasReceipt ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Icon(
                payment.hasReceipt ? Icons.visibility_outlined : Icons.add_photo_alternate_outlined,
                color: payment.hasReceipt ? Colors.green : Colors.orange,
                size: context.iconSize('small'),
              ),
            ),
          ),
        ),
        SizedBox(width: context.smallPadding),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onDelete(payment),
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

  Widget _buildExpandedActions(BuildContext context, PaymentModel payment) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onEdit(payment),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      l10n.edit,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.blue),
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
              onTap: () => onViewReceipt(payment),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(
                  color: payment.hasReceipt ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      payment.hasReceipt ? Icons.visibility_outlined : Icons.add_photo_alternate_outlined,
                      color: payment.hasReceipt ? Colors.green : Colors.orange,
                      size: context.iconSize('small'),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      payment.hasReceipt ? l10n.view : l10n.add,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: payment.hasReceipt ? Colors.green : Colors.orange,
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
              onTap: () => onDelete(payment),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      l10n.delete,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.red),
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
            width: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 5.w, small: 5.w, medium: 5.w, large: 5.w, ultrawide: 5.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.payments_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.noPaymentRecordsFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.smallPadding),
          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startByAddingFirstPaymentRecord,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
