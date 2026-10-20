enum HomeLayoutMode {
  compact, // 320–599
  medium, // 600–1023
  desktop, // 1024–1439
  wide; // 1440+

  bool get hasPermanentSidebar =>
      this == HomeLayoutMode.desktop || this == HomeLayoutMode.wide;
  bool get usesDrawer =>
      this == HomeLayoutMode.compact || this == HomeLayoutMode.medium;
  bool get usesLabeledFab => this == HomeLayoutMode.compact;

  double get sidebarWidth => switch (this) {
    HomeLayoutMode.desktop => 240.0,
    HomeLayoutMode.wide => 256.0,
    _ => 280.0,
  };
}

class HomeLayout {
  const HomeLayout._();

  static const double breakpointCompact = 600.0;
  static const double breakpointMedium = 1024.0;
  static const double breakpointWide = 1440.0;

  static const double minCenterWidthForInlineDetails = 600.0;
  static const double inlineDetailWidth = 360.0;
  static const double maxModalDetailWidth = 420.0;

  static HomeLayoutMode fromWidth(double width) {
    if (width < breakpointCompact) return HomeLayoutMode.compact;
    if (width < breakpointMedium) return HomeLayoutMode.medium;
    if (width < breakpointWide) return HomeLayoutMode.desktop;
    return HomeLayoutMode.wide;
  }

  static bool shouldShowInlineDetails({
    required double availableWidth,
    required double textScaleFactor,
    required bool hasSelection,
  }) {
    if (!hasSelection) return false;
    if (textScaleFactor > 1.3) return false;
    if (availableWidth < breakpointWide) return false;

    final sidebarW = fromWidth(availableWidth).sidebarWidth;
    final remainingCenter = availableWidth - sidebarW - inlineDetailWidth;
    return remainingCenter >= minCenterWidthForInlineDetails;
  }

  static bool shouldCollapseSummary(double height) {
    return height < 600.0;
  }

  static bool shouldUseStackedRows({
    required double collectionWidth,
    required double textScaleFactor,
  }) {
    if (textScaleFactor > 1.3) return true;
    return collectionWidth < 840.0;
  }

  static bool shouldUseFullScreenDetails({
    required double width,
    required double textScaleFactor,
  }) {
    return width < breakpointCompact || textScaleFactor >= 2.0;
  }
}
