import 'package:flutter/widgets.dart';

enum TourTooltipPosition { above, below, center }

// Where the label card appears when there is no spotlight.
enum TourLabelPosition { top, center, bottom }

class TourStep {
  final String title;
  final String? subtitle;
  // Replaces subtitle when you need dynamic/reactive content.
  final Widget Function()? subtitleBuilder;
  final GlobalKey? targetKey;
  // When set and there is no spotlight, the card is positioned just above
  // this widget's bounds (e.g. tourKeyTimer). Pixel-perfect on every device.
  final GlobalKey? anchorAboveKey;
  final TourTooltipPosition tooltipPosition;
  final double spotlightPadding;
  final bool isInteractive;
  final bool blockBackground;
  final VoidCallback? onSpotlightTap;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final bool showBackdrop;
  final double labelYOffset;
  // Controls card position when there is no spotlight and no anchorAboveKey.
  final TourLabelPosition labelPosition;
  final VoidCallback? onActivate;

  TourStep({
    required this.title,
    this.subtitle,
    this.subtitleBuilder,
    this.targetKey,
    this.anchorAboveKey,
    this.tooltipPosition = TourTooltipPosition.below,
    this.spotlightPadding = 6.0,
    this.isInteractive = false,
    this.blockBackground = true,
    this.showBackdrop = true,
    this.onSpotlightTap,
    this.onActionTap,
    this.actionLabel,
    this.labelYOffset = 0.0,
    this.labelPosition = TourLabelPosition.center,
    this.onActivate,
  });
}
