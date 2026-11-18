import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns = gridColumnsOf(context);
    if (columns <= 1) {
      return Column(children: children);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
