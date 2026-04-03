import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payment/payment_model.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/image_upload.dart';
import '../globals/text_button.dart';
import '../../../l10n/app_localizations.dart';

class PaymentReceiptContent extends StatelessWidget {
  final PaymentModel payment;
  final bool isCompact;
  final VoidCallback onClose;

  const PaymentReceiptContent({super.key, required this.payment, required this.isCompact, required this.onClose});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPaymentDetailsCard(context),
          SizedBox(height: context.cardPadding),
          _buildDateTimeSection(context),
          SizedBox(height: context.cardPadding),
          _buildDescriptionSection(context),
          SizedBox(height: context.cardPadding),
          _buildPaymentMethodSection(context),
          SizedBox(height: context.cardPadding),
          _buildAmountBreakdownSection(context),
          SizedBox(height: context.cardPadding),
          if (payment.hasReceipt) ...[_buildReceiptImageSection(context)] else ...[_buildNoReceiptSection(context)],
          SizedBox(height: context.mainPadding),
          Align(
            alignment: Alignment.centerRight,
            child: PremiumButton(
              text: AppLocalizations.of(context)!.close,
              onPressed: onClose,
              height: context.buttonHeight / (isCompact ? 1 : 1.5),
              isOutlined: true,
              backgroundColor: Colors.grey[600],
              textColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentDetails,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
          SizedBox(height: context.cardPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildPaymentDetailsCompact(context),
            small: _buildPaymentDetailsCompact(context),
            medium: _buildPaymentDetailsExpanded(context),
            large: _buildPaymentDetailsExpanded(context),
            ultrawide: _buildPaymentDetailsExpanded(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCompact(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.labor,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          payment.laborName ?? l10n.notAvailable,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        Text(
          '${payment.laborRole ?? l10n.notAvailable} • ${payment.laborPhone ?? l10n.notAvailable}',
          style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),
        Text(
          l10n.paymentMonth,
          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
        ),
        Text(
          _formatDate(payment.paymentMonth),
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        if (payment.isFinalPayment) ...[
          SizedBox(height: context.smallPadding / 2),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              l10n.finalPaymentForMonth,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.green[700]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentDetailsExpanded(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.labor,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                payment.laborName ?? l10n.notAvailable,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              Text(
                '${payment.laborRole ?? l10n.notAvailable} • ${payment.laborPhone ?? l10n.notAvailable}',
                style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.paymentMonth,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
              Text(
                _formatDate(payment.paymentMonth),
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              if (payment.isFinalPayment) ...[
                SizedBox(height: context.smallPadding / 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                  child: Text(
                    l10n.finalPayment,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.green[700]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: _buildDateTimeCompact(context),
      small: _buildDateTimeCompact(context),
      medium: _buildDateTime(context),
      large: _buildDateTime(context),
      ultrawide: _buildDateTime(context),
    );
  }

  Widget _buildDateTimeCompact(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.purple),
              SizedBox(width: context.smallPadding),
              Text(
                _formatDate(payment.date),
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.smallPadding),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
          child: Row(
            children: [
              Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.orange),
              SizedBox(width: context.smallPadding),
              Text(
                payment.formattedTime,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTime(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: context.iconSize('small'), color: Colors.purple),
                SizedBox(width: context.smallPadding),
                Text(
                  _formatDate(payment.date),
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Row(
              children: [
                Icon(Icons.access_time, size: context.iconSize('small'), color: Colors.orange),
                SizedBox(width: context.smallPadding),
                Text(
                  payment.formattedTime,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.description,
            style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          SizedBox(height: context.smallPadding / 2),
          Text(
            payment.description ?? l10n.noDescription,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: AppTheme.charcoalGray),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: payment.paymentMethodColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: payment.paymentMethodColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: payment.paymentMethodColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(payment.paymentMethodIcon, color: payment.paymentMethodColor, size: context.iconSize('medium')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentMethod,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                Text(
                  payment.paymentMethod,
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: payment.paymentMethodColor),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
            decoration: BoxDecoration(color: payment.statusColor, borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              payment.statusText,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBreakdownSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate_rounded, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.amountBreakdown,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.green[700]),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.baseAmount}:',
                style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
              ),
              Text(
                'PKR ${payment.amountPaid.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          if (payment.bonus > 0) ...[
            SizedBox(height: context.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.bonus}:',
                  style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
                ),
                Text(
                  '+PKR ${payment.bonus.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.blue),
                ),
              ],
            ),
          ],
          if (payment.deduction > 0) ...[
            SizedBox(height: context.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.deduction}:',
                  style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[700]),
                ),
                Text(
                  '-PKR ${payment.deduction.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.red),
                ),
              ],
            ),
          ],
          SizedBox(height: context.cardPadding),
          Container(width: double.infinity, height: 1, color: Colors.grey.shade300),
          SizedBox(height: context.cardPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.netAmount}:',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
              Text(
                'PKR ${payment.netAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImageSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_rounded, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.receiptImage,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.green),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            height: ResponsiveBreakpoints.responsive(context, tablet: 25.h, small: 30.h, medium: 35.h, large: 40.h, ultrawide: 45.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ResponsiveImageUploadWidget(
              initialImagePath: payment.receiptImagePath,
              onImageChanged: (imagePath) {},
              label: l10n.paymentReceipt,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoReceiptSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.orange, size: context.iconSize('xl')),
          SizedBox(height: context.cardPadding),
          Text(
            l10n.noReceiptAvailable,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.smallPadding),
          Text(
            isCompact ? l10n.noReceiptAvailableShort : l10n.noReceiptAvailableLong,
            style: TextStyle(fontSize: context.subtitleFontSize, color: Colors.orange[400]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.cardPadding),
          Container(
            height: ResponsiveBreakpoints.responsive(context, tablet: 25.h, small: 30.h, medium: 35.h, large: 40.h, ultrawide: 45.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ResponsiveImageUploadWidget(
              initialImagePath: null,
              onImageChanged: (imagePath) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.receiptUploadedSaveToUpdate,
                      style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.pureWhite),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
                  ),
                );
              },
              label: l10n.addReceiptImage,
              context: context,
            ),
          ),
        ],
      ),
    );
  }
}
