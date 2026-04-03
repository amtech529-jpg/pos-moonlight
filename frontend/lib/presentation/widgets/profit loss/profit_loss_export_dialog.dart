import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ProfitLossExportDialog extends StatelessWidget {
  const ProfitLossExportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      title: Row(
        children: [
          Icon(Icons.download_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Text(
            l10n.exportFormat,
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.chooseTheFormatForYourProfitAndLossReport,
            style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
          ),
          SizedBox(height: context.cardPadding),
          _buildExportOption(
            context,
            l10n.pdfReport,
            l10n.professionalDocumentWithChartsAndFormatting,
            Icons.picture_as_pdf_rounded,
            Colors.red,
                () => Navigator.of(context).pop('pdf'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildExportOption(BuildContext context, String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.borderRadius('small')),
      child: Container(
        padding: EdgeInsets.all(context.cardPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(icon, color: color, size: context.iconSize('medium')),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: context.iconSize('small')),
          ],
        ),
      ),
    );
  }
}
