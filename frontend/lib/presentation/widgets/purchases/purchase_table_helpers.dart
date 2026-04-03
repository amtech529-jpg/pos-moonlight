import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class PurchaseTableHelpers {
  /// Builds a premium-styled status badge for 'Draft' or 'Posted' states
  static Widget buildStatusBadge(BuildContext context, String status) {
    final String normalizedStatus = status.toLowerCase();
    final bool isPosted = normalizedStatus == 'posted';
    final bool isDraft = normalizedStatus == 'draft';

    Color baseColor;
    if (isPosted) {
      baseColor = Colors.green;
    } else if (isDraft) {
      baseColor = Colors.blue;
    } else {
      baseColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.smallPadding,
        vertical: context.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius('small')),
        border: Border.all(
          color: baseColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: context.smallPadding / 2),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: baseColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats currency values consistently across the table
  static Widget buildAmountText(double amount, {bool isTotal = false}) {
    return Text(
      NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount),
      style: TextStyle(
        fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
        color: isTotal ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
        fontSize: isTotal ? 14 : 13,
      ),
    );
  }

  /// Builds a styled header for the table columns
  static Widget buildTableHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.charcoalGray.withOpacity(0.8),
        letterSpacing: 1.1,
      ),
    );
  }

  /// Helper for consistent date formatting
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }
}