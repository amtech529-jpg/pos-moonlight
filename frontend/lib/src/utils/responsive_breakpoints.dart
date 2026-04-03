import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ResponsiveBreakpoints {
  // Desktop breakpoints for POS system (600px minimum for better compatibility)
  static const double tablet = 600;  // Reduced from 750 for better small screen support
  static const double smallDesktop = 1024; // Small desktop
  static const double mediumDesktop = 1366; // Medium desktop (HP EliteBook 840 G5)
  static const double largeDesktop = 1920; // Large desktop
  static const double ultrawide = 2560; // Ultrawide monitors

  // Screen type detection
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  }

  static bool isSmallDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024 && MediaQuery.of(context).size.width < 1366;
  }

  static bool isMediumDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1366 && MediaQuery.of(context).size.width < 1920;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1920 && MediaQuery.of(context).size.width < 2560;
  }

  static bool isUltrawide(BuildContext context) {
    return MediaQuery.of(context).size.width >= 2560;
  }

  static bool isMinimumSupported(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  // Get screen type as string
  static String getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 2560) return 'ultrawide';
    if (width >= 1920) return 'large';
    if (width >= 1366) return 'medium';
    if (width >= 1024) return 'small';
    if (width >= 600) return 'tablet';
    return 'unsupported'; // Below 600px
  }

  // Enhanced responsive values with tablet support
  static T responsive<T>(
    BuildContext context, {
    required T tablet, // 600-1023px
    required T small, // 1024-1365px
    required T medium, // 1366-1919px
    required T large, // 1920-2559px
    required T ultrawide, // 2560px+
  }) {
    if (isUltrawide(context)) return ultrawide;
    if (isLargeDesktop(context)) return large;
    if (isMediumDesktop(context)) return medium;
    if (isSmallDesktop(context)) return small;
    if (isTablet(context)) return tablet;
    return tablet; // Fallback for unsupported sizes
  }

  // Sizer-based responsive widths with tablet support
  static double getSidebarExpandedWidth(BuildContext context) {
    final baseWidth = responsive(
      context,
      tablet: 20.w, // Reduced from 25.w
      small: 20.w, // Reduced from 25.w
      medium: 12.w, // Reduced from 15.w
      large: 16.w, // Reduced from 20.w
      ultrawide: 14.w, // Reduced from 18.w
    );

    // Ensure minimum and maximum constraints
    return baseWidth.clamp(200.0, 350.0); // Reduced max from 400.0
  }

  static double getSidebarCollapsedWidth(BuildContext context) {
    return responsive(
      context,
      tablet: 6.w, // Reduced from 7.w
      small: 4.w, // Reduced from 5.w
      medium: 4.w, // Reduced from 4.5.w
      large: 3.5.w, // Reduced from 4.w
      ultrawide: 3.w, // Reduced from 3.5.w
    ).clamp(50.0, 80.0); // Reduced max from 100.0
  }

  static double getHeadingFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 18.8.sp, // Increased from 16.8.sp
      small: 17.2.sp, // Increased from 15.2.sp
      medium: 19.5.sp, // Increased from 17.5.sp
      large: 19.8.sp, // Increased from 17.8.sp
      ultrawide: 20.2.sp, // Increased from 18.2.sp
    );
  }

  // Enhanced font sizes with tablet support - INCREASED FOR BETTER READABILITY
  static double getHeaderFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 12.8.sp, // Increased from 10.8.sp
      small: 13.2.sp, // Increased from 11.2.sp
      medium: 13.5.sp, // Increased from 11.5.sp
      large: 13.8.sp, // Increased from 11.8.sp
      ultrawide: 14.2.sp, // Increased from 12.2.sp
    );
  }

  static double getBodyFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 11.6.sp, // Increased from 9.6.sp
      small: 11.8.sp, // Increased from 9.8.sp
      medium: 12.0.sp, // Increased from 10.sp
      large: 12.2.sp, // Increased from 10.2.sp
      ultrawide: 12.4.sp, // Increased from 10.4.sp
    );
  }

  static double getSubtitleFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 11.6.sp, // Increased from 9.6.sp
      small: 11.8.sp, // Increased from 9.8.sp
      medium: 12.0.sp, // Increased from 10.sp
      large: 12.2.sp, // Increased from 10.2.sp
      ultrawide: 12.4.sp, // Increased from 10.4.sp
    );
  }

  static double getCaptionFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 10.6.sp, // Increased from 8.6.sp
      small: 10.8.sp, // Increased from 8.8.sp
      medium: 11.0.sp, // Increased from 9.sp
      large: 11.2.sp, // Increased from 9.2.sp
      ultrawide: 11.4.sp, // Increased from 9.4.sp
    );
  }

  // Dashboard-specific font sizes (ORIGINAL SIZES TO PREVENT OVERFLOW)
  static double getDashboardHeaderFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 10.8.sp, // Original size
      small: 11.2.sp, // Original size
      medium: 11.5.sp, // Original size
      large: 11.8.sp, // Original size
      ultrawide: 12.2.sp, // Original size
    );
  }

  static double getDashboardBodyFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 9.6.sp, // Original size
      small: 9.8.sp, // Original size
      medium: 10.sp, // Original size
      large: 10.2.sp, // Original size
      ultrawide: 10.4.sp, // Original size
    );
  }

  static double getDashboardSubtitleFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 9.6.sp, // Original size
      small: 9.8.sp, // Original size
      medium: 10.sp, // Original size
      large: 10.2.sp, // Original size
      ultrawide: 10.4.sp, // Original size
    );
  }

  static double getDashboardCaptionFontSize(BuildContext context) {
    return responsive(
      context,
      tablet: 8.6.sp, // Original size
      small: 8.8.sp, // Original size
      medium: 9.sp, // Original size
      large: 9.2.sp, // Original size
      ultrawide: 9.4.sp, // Original size
    );
  }

  // Enhanced padding and margins with tablet support
  static double getMainPadding(BuildContext context) {
    return responsive(
      context,
      tablet: 1.5.w, // Smaller padding for tablets
      small: 2.w, // 2% of screen width
      medium: 2.5.w, // 2.5% of screen width
      large: 3.w, // 3% of screen width
      ultrawide: 3.5.w, // 3.5% of screen width
    );
  }

  static double getCardPadding(BuildContext context) {
    return responsive(
      context,
      tablet: 1.2.w, // Smaller for tablets
      small: 1.5.w,
      medium: 1.8.w,
      large: 2.w,
      ultrawide: 2.2.w,
    );
  }

  static double getSmallPadding(BuildContext context) {
    return responsive(
      context,
      tablet: 0.6.w, // Smaller for tablets
      small: 0.8.w,
      medium: 1.w,
      large: 1.2.w,
      ultrawide: 1.4.w,
    );
  }

  // Enhanced heights with tablet support
  static double getButtonHeight(BuildContext context) {
    return responsive(
      context,
      tablet: 5.5.h, // Smaller buttons for tablets
      small: 6.h, // 6% of screen height
      medium: 6.5.h, // 6.5% of screen height
      large: 7.h, // 7% of screen height
      ultrawide: 7.5.h, // 7.5% of screen height
    ).clamp(40.0, 60.0); // Ensure accessibility standards
  }

  static double getHeaderHeight(BuildContext context) {
    return responsive(
      context,
      tablet: 7.h, // Smaller header for tablets
      small: 8.h,
      medium: 9.h,
      large: 10.h,
      ultrawide: 11.h,
    ).clamp(60.0, 120.0);
  }

  // Enhanced grid and layout with tablet support
  static int getStatsCardColumns(BuildContext context) {
    return responsive(
      context,
      tablet: 2, // 2x2 grid for tablets
      small: 2, // 2x2 grid for small screens
      medium: 4, // 1x4 row for medium screens
      large: 4, // 1x4 row for large screens
      ultrawide: 4, // 1x4 row for ultrawide
    );
  }

  static List<int> getTableColumnFlexes(BuildContext context) {
    return responsive(
      context,
      tablet: [1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Very compressed for tablets
      small: [1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Compressed for small screens
      medium: [1, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Balanced for medium screens
      large: [1, 2, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1], // More space for description
      ultrawide: [1, 2, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Extra space for ultrawide
    );
  }

  static List<int> getLaborTableColumnFlexes(BuildContext context) {
    return responsive(
      context,
      tablet: [1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Very compressed for tablets
      small: [1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Compressed for small screens
      medium: [1, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Balanced for medium screens
      large: [1, 2, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1], // More space for description
      ultrawide: [1, 2, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Extra space for ultrawide
    );
  }

  // Order table column flexes (7 columns: Order ID, Customer, Description, Amount, Status, Delivery, Actions)
  static List<int> getOrderTableColumnFlexes(BuildContext context) {
    return responsive(
      context,
      tablet: [1, 2, 1, 1, 1, 1, 2], // Actions column gets 2x space on tablets
      small: [1, 2, 2, 1, 1, 1, 2], // Actions column gets 2x space on small screens
      medium: [1, 2, 3, 1, 1, 1, 2], // Actions column gets 2x space on medium screens
      large: [1, 2, 4, 1, 1, 1, 2], // Actions column gets 2x space on large screens
      ultrawide: [1, 2, 4, 1, 1, 1, 2], // Actions column gets 2x space on ultrawide
    );
  }

  // Enhanced component dimensions with tablet support
  static double getDialogWidth(BuildContext context) {
    return responsive(
      context,
      tablet: 85.w, // 85% of screen width for tablets
      small: 75.w, // 70% of screen width
      medium: 65.w, // 60% of screen width
      large: 55.w, // 50% of screen width
      ultrawide: 45.w, // 40% of screen width
    ).clamp(300.0, 800.0);
  }

  static double getSearchBarWidth(BuildContext context) {
    return responsive(
      context,
      tablet: 30.w, // Larger percentage for tablets
      small: 15.w,
      medium: 20.w,
      large: 25.w,
      ultrawide: 30.w,
    );
  }

  static double getIconSize(BuildContext context, {required String type}) {
    switch (type) {
      case 'small':
        return responsive(context, tablet: 14.sp, small: 14.sp, medium: 14.sp, large: 14.sp, ultrawide: 14.sp); // Increased from 12.sp
      case 'medium':
        return responsive(context, tablet: 16.sp, small: 16.sp, medium: 16.sp, large: 16.sp, ultrawide: 16.sp); // Increased from 12.sp
      case 'large':
        return responsive(context, tablet: 18.sp, small: 18.sp, medium: 18.sp, large: 18.sp, ultrawide: 18.sp); // Increased from 12.sp
      case 'xl':
        return responsive(context, tablet: 20.sp, small: 20.sp, medium: 20.sp, large: 20.sp, ultrawide: 20.sp); // Increased from 12.sp
      case 'special':
        return responsive(context, tablet: 34.sp, small: 34.sp, medium: 34.sp, large: 34.sp, ultrawide: 34.sp); // Increased from 30.sp
      default:
        return responsive(context, tablet: 14.sp, small: 14.sp, medium: 14.sp, large: 14.sp, ultrawide: 14.sp); // Increased from 12.sp
    }
  }

  // Dashboard-specific icon sizes (ORIGINAL SIZES TO PREVENT OVERFLOW)
  static double getDashboardIconSize(BuildContext context, {required String type}) {
    switch (type) {
      case 'small':
        return responsive(context, tablet: 12.sp, small: 12.sp, medium: 12.sp, large: 12.sp, ultrawide: 12.sp); // Original size
      case 'medium':
        return responsive(context, tablet: 12.sp, small: 12.sp, medium: 12.sp, large: 12.sp, ultrawide: 12.sp); // Original size
      case 'large':
        return responsive(context, tablet: 12.sp, small: 12.sp, medium: 12.sp, large: 12.sp, ultrawide: 12.sp); // Original size
      case 'xl':
        return responsive(context, tablet: 12.sp, small: 12.sp, medium: 12.sp, large: 12.sp, ultrawide: 12.sp); // Original size
      case 'special':
        return responsive(context, tablet: 30.sp, small: 30.sp, medium: 30.sp, large: 30.sp, ultrawide: 30.sp); // Original size
      default:
        return responsive(context, tablet: 12.sp, small: 12.sp, medium: 12.sp, large: 12.sp, ultrawide: 12.sp); // Original size
    }
  }

  // Enhanced dimensions with tablet support
  static double getChartHeight(BuildContext context) {
    return responsive(
      context,
      tablet: 20.h, // Smaller charts for tablets
      small: 25.h, // 25% of screen height
      medium: 30.h, // 30% of screen height
      large: 35.h, // 35% of screen height
      ultrawide: 40.h, // 40% of screen height
    ).clamp(180.0, 400.0);
  }

  static double getStatsCardHeight(BuildContext context) {
    return responsive(
      context,
      tablet: 10.h, // Smaller cards for tablets
      small: 12.h,
      medium: 14.h,
      large: 16.h,
      ultrawide: 18.h,
    ).clamp(80.0, 180.0);
  }

  // Enhanced border radius with tablet support
  static double getBorderRadius(BuildContext context, {String size = 'medium'}) {
    final baseRadius = responsive(
      context,
      tablet: 0.8.w, // Smaller radius for tablets
      small: 1.w,
      medium: 1.2.w,
      large: 1.4.w,
      ultrawide: 1.6.w,
    );

    switch (size) {
      case 'small':
        return (baseRadius * 0.6).clamp(4.0, 12.0);
      case 'large':
        return (baseRadius * 1.5).clamp(12.0, 24.0);
      case 'xl':
        return (baseRadius * 2).clamp(16.0, 32.0);
      default:
        return baseRadius.clamp(6.0, 16.0);
    }
  }

  // Enhanced shadow blur with tablet support
  static double getShadowBlur(BuildContext context, {String intensity = 'medium'}) {
    final baseBlur = responsive(
      context,
      tablet: 0.6.w, // Lighter shadows for tablets
      small: 0.8.w,
      medium: 1.w,
      large: 1.2.w,
      ultrawide: 1.4.w,
    );

    switch (intensity) {
      case 'light':
        return (baseBlur * 0.5).clamp(2.0, 8.0);
      case 'heavy':
        return (baseBlur * 1.5).clamp(8.0, 20.0);
      default:
        return baseBlur.clamp(4.0, 12.0);
    }
  }

  // Layout helpers for different screen types
  static bool shouldShowCompactLayout(BuildContext context) {
    return isTablet(context) || isSmallDesktop(context);
  }

  static bool shouldShowFullLayout(BuildContext context) {
    return isLargeDesktop(context) || isUltrawide(context);
  }

  static bool shouldUseDropdownActions(BuildContext context) {
    return isTablet(context);
  }

  static bool shouldUseLabeledButtons(BuildContext context) {
    return isLargeDesktop(context) || isUltrawide(context);
  }

  // Additional responsive helpers
  static double getAppBarHeight(BuildContext context) {
    return responsive(context, tablet: 6.h, small: 7.h, medium: 8.h, large: 9.h, ultrawide: 10.h).clamp(56.0, 100.0);
  }

  static double getDrawerWidth(BuildContext context) {
    return responsive(context, tablet: 70.w, small: 60.w, medium: 50.w, large: 40.w, ultrawide: 30.w).clamp(250.0, 400.0);
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    final padding = getMainPadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getCardMargin(BuildContext context) {
    final margin = getSmallPadding(context);
    return EdgeInsets.all(margin);
  }

  static EdgeInsets getSectionPadding(BuildContext context) {
    final padding = getCardPadding(context);
    return EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.8);
  }

  // Form field responsive properties
  static double getFormFieldHeight(BuildContext context) {
    return responsive(context, tablet: 5.h, small: 5.5.h, medium: 6.h, large: 6.5.h, ultrawide: 7.h).clamp(48.0, 72.0);
  }

  static double getFormFieldSpacing(BuildContext context) {
    return responsive(context, tablet: 1.h, small: 1.5.h, medium: 2.h, large: 2.5.h, ultrawide: 3.h).clamp(8.0, 24.0);
  }

  // Navigation responsive properties
  static double getBottomNavHeight(BuildContext context) {
    return responsive(context, tablet: 7.h, small: 8.h, medium: 9.h, large: 10.h, ultrawide: 11.h).clamp(60.0, 100.0);
  }

  static double getTabHeight(BuildContext context) {
    return responsive(context, tablet: 5.h, small: 5.5.h, medium: 6.h, large: 6.5.h, ultrawide: 7.h).clamp(48.0, 72.0);
  }

  // Content responsive properties
  static double getMaxContentWidth(BuildContext context) {
    return responsive(
      context,
      tablet: 100.w, // Full width on tablets
      small: 95.w, // 95% width on small screens
      medium: 90.w, // 90% width on medium screens
      large: 85.w, // 85% width on large screens
      ultrawide: 80.w, // 80% width on ultrawide
    );
  }

  static int getGridCrossAxisCount(BuildContext context) {
    return responsive(context, tablet: 2, small: 3, medium: 4, large: 5, ultrawide: 6);
  }

  static double getListTileHeight(BuildContext context) {
    return responsive(context, tablet: 6.h, small: 7.h, medium: 8.h, large: 9.h, ultrawide: 10.h).clamp(56.0, 100.0);
  }
}

// Enhanced extension with tablet support and additional helpers
extension ResponsiveContext on BuildContext {
  // Screen type detection
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isSmallDesktop => ResponsiveBreakpoints.isSmallDesktop(this);
  bool get isMediumDesktop => ResponsiveBreakpoints.isMediumDesktop(this);
  bool get isLargeDesktop => ResponsiveBreakpoints.isLargeDesktop(this);
  bool get isUltrawide => ResponsiveBreakpoints.isUltrawide(this);
  bool get isMinimumSupported => ResponsiveBreakpoints.isMinimumSupported(this);
  String get screenType => ResponsiveBreakpoints.getScreenType(this);

  // Layout helpers
  bool get shouldShowCompactLayout => ResponsiveBreakpoints.shouldShowCompactLayout(this);
  bool get shouldShowFullLayout => ResponsiveBreakpoints.shouldShowFullLayout(this);
  bool get shouldUseDropdownActions => ResponsiveBreakpoints.shouldUseDropdownActions(this);
  bool get shouldUseLabeledButtons => ResponsiveBreakpoints.shouldUseLabeledButtons(this);

  // Dimensions with Sizer + Breakpoints
  double get sidebarExpandedWidth => ResponsiveBreakpoints.getSidebarExpandedWidth(this);
  double get sidebarCollapsedWidth => ResponsiveBreakpoints.getSidebarCollapsedWidth(this);

  // Typography with Sizer scaling
  double get headerFontSize => ResponsiveBreakpoints.getHeaderFontSize(this);
  double get headingFontSize => ResponsiveBreakpoints.getHeadingFontSize(this);
  double get bodyFontSize => ResponsiveBreakpoints.getBodyFontSize(this);
  double get subtitleFontSize => ResponsiveBreakpoints.getSubtitleFontSize(this);
  double get captionFontSize => ResponsiveBreakpoints.getCaptionFontSize(this);

  // Dashboard-specific typography (ORIGINAL SIZES)
  double get dashboardHeaderFontSize => ResponsiveBreakpoints.getDashboardHeaderFontSize(this);
  double get dashboardBodyFontSize => ResponsiveBreakpoints.getDashboardBodyFontSize(this);
  double get dashboardSubtitleFontSize => ResponsiveBreakpoints.getDashboardSubtitleFontSize(this);
  double get dashboardCaptionFontSize => ResponsiveBreakpoints.getDashboardCaptionFontSize(this);

  // Spacing with Sizer scaling
  double get mainPadding => ResponsiveBreakpoints.getMainPadding(this);
  double get cardPadding => ResponsiveBreakpoints.getCardPadding(this);
  double get smallPadding => ResponsiveBreakpoints.getSmallPadding(this);

  // Component dimensions
  double get buttonHeight => ResponsiveBreakpoints.getButtonHeight(this);
  double get headerHeight => ResponsiveBreakpoints.getHeaderHeight(this);
  double get dialogWidth => ResponsiveBreakpoints.getDialogWidth(this);
  double get chartHeight => ResponsiveBreakpoints.getChartHeight(this);
  double get statsCardHeight => ResponsiveBreakpoints.getStatsCardHeight(this);
  double get appBarHeight => ResponsiveBreakpoints.getAppBarHeight(this);
  double get drawerWidth => ResponsiveBreakpoints.getDrawerWidth(this);
  double get formFieldHeight => ResponsiveBreakpoints.getFormFieldHeight(this);
  double get formFieldSpacing => ResponsiveBreakpoints.getFormFieldSpacing(this);
  double get bottomNavHeight => ResponsiveBreakpoints.getBottomNavHeight(this);
  double get tabHeight => ResponsiveBreakpoints.getTabHeight(this);
  double get maxContentWidth => ResponsiveBreakpoints.getMaxContentWidth(this);
  double get listTileHeight => ResponsiveBreakpoints.getListTileHeight(this);

  // Layout helpers
  int get statsCardColumns => ResponsiveBreakpoints.getStatsCardColumns(this);
  List<int> get tableColumnFlexes => ResponsiveBreakpoints.getTableColumnFlexes(this);
  List<int> get laborTableColumnFlexes => ResponsiveBreakpoints.getLaborTableColumnFlexes(this);
  List<int> get orderTableColumnFlexes => ResponsiveBreakpoints.getOrderTableColumnFlexes(this);
  int get gridCrossAxisCount => ResponsiveBreakpoints.getGridCrossAxisCount(this);

  // Edge insets helpers
  EdgeInsets get pagePadding => ResponsiveBreakpoints.getPagePadding(this);
  EdgeInsets get cardMargin => ResponsiveBreakpoints.getCardMargin(this);
  EdgeInsets get sectionPadding => ResponsiveBreakpoints.getSectionPadding(this);

  // Style helpers
  double borderRadius([String size = 'medium']) => ResponsiveBreakpoints.getBorderRadius(this, size: size);
  double shadowBlur([String intensity = 'medium']) => ResponsiveBreakpoints.getShadowBlur(this, intensity: intensity);
  double iconSize(String type) => ResponsiveBreakpoints.getIconSize(this, type: type);
  double dashboardIconSize(String type) => ResponsiveBreakpoints.getDashboardIconSize(this, type: type);
}
