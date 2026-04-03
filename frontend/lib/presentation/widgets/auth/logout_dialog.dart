import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';

class LogoutDialogWidget extends StatefulWidget {
  final bool isExpanded;

  const LogoutDialogWidget({super.key, required this.isExpanded});

  @override
  _LogoutDialogWidgetState createState() => _LogoutDialogWidgetState();
}

class _LogoutDialogWidgetState extends State<LogoutDialogWidget> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius('medium')),
          ),
          backgroundColor: AppTheme.creamWhite,
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                AppLocalizations.of(context)!.confirmLogout,
                style: TextStyle(
                  fontSize: context.headerFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.logoutMessage,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final authProvider = Provider.of<AuthProvider>(context, listen: false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.pureWhite,
                            ),
                          ),
                        ),
                        SizedBox(width: context.smallPadding),
                        Text(
                          AppLocalizations.of(context)!.loggingOut,
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppTheme.primaryMaroon,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.borderRadius('medium'),
                      ),
                    ),
                    margin: EdgeInsets.all(context.mainPadding),
                    duration: const Duration(seconds: 1),
                  ),
                );

                try {
                  await authProvider.logout();
                  
                  if (mounted) {
                    AlNoorApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                    
                    Future.microtask(() {
                      final currentContext = AlNoorApp.navigatorKey.currentContext;
                      if (currentContext != null) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(currentContext)!.logoutSuccess,
                              style: const TextStyle(fontSize: 14),
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    AlNoorApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    context.borderRadius(),
                  ),
                ),
                elevation: 2,
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Container(
          padding: EdgeInsets.all(
            widget.isExpanded
                ? context.smallPadding / 1.5
                : context.smallPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          ),
          child: widget.isExpanded
              ? Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade300,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                AppLocalizations.of(context)!.logout,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ],
          )
              : Icon(
            Icons.logout_rounded,
            color: Colors.red.shade300,
            size: context.iconSize('medium'),
          ),
        ),
      ),
    );
  }
}
