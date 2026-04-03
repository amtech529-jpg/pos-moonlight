import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/app_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context);

    return Container(
      padding: context.pagePadding / 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settings,
            style: TextStyle(
              fontSize: context.headingFontSize,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.formFieldSpacing * 2),

          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader(context, l10n.language),
                _buildLanguageCard(context, appProvider),

                SizedBox(height: context.formFieldSpacing * 3),

                _buildSectionHeader(context, l10n.aboutApp),
                _buildAboutCard(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.smallPadding),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.headerFontSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryMaroon,
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, AppProvider appProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Column(
        children: [
          _buildLanguageTile(
            context,
            'اردو',
            'Urdu',
            'ur',
            appProvider.currentLanguage == 'ur',
            () {
              appProvider.setLanguage('ur');
              debugPrint('🌐 Language changed to Urdu');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('زبان اردو میں تبدیل کردی گئی'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildLanguageTile(
            context,
            'English',
            'English',
            'en',
            appProvider.currentLanguage == 'en',
            () {
              appProvider.setLanguage('en');
              debugPrint('🌐 Language changed to English');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Language changed to English'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String title,
    String subtitle,
    String code,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(context.smallPadding / 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryMaroon.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
        ),
        child: Icon(
          Icons.language_rounded,
          color: isSelected ? AppTheme.primaryMaroon : Colors.grey[600],
          size: context.iconSize('medium'),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: context.subtitleFontSize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: context.captionFontSize,
          color: Colors.grey[600],
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryMaroon,
              size: context.iconSize('medium'),
            )
          : Icon(
              Icons.circle_outlined,
              color: Colors.grey[400],
              size: context.iconSize('medium'),
            ),
    );
  }

  Widget _buildAboutCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.smallPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryMaroon,
                    size: context.iconSize('large'),
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.alNoorFashionPOS,
                        style: TextStyle(
                          fontSize: context.headerFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoalGray,
                        ),
                      ),
                      Text(
                        '${l10n.version} 1.0.0',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.smallPadding),
            Text(
              l10n.aPremiumPointOfSaleSolution,
              style: TextStyle(
                fontSize: context.subtitleFontSize,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}