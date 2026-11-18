import 'package:flutter/widgets.dart';

class Breakpoints {
  const Breakpoints._();

  static const double medium = 768;
  static const double expanded = 1280;
  static const double contentMaxWidth = 1200;
}

enum LayoutSize { compact, medium, expanded }

LayoutSize layoutSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.expanded) return LayoutSize.expanded;
  if (width >= Breakpoints.medium) return LayoutSize.medium;
  return LayoutSize.compact;
}

bool useCardListOf(BuildContext context) {
  return MediaQuery.sizeOf(context).width < Breakpoints.expanded;
}

int gridColumnsOf(BuildContext context) {
  final size = layoutSizeOf(context);
  return switch (size) {
    LayoutSize.compact => 1,
    LayoutSize.medium => 2,
    LayoutSize.expanded => 2,
  };
}
