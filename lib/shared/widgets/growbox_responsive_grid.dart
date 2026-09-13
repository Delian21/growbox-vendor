import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// One cell of a [GrowboxResponsiveGrid].
class ResponsiveGridItem {
  final Widget child;

  /// How many columns this item spans on the narrow layout
  /// ([GrowboxResponsiveGrid.narrowColumns]).
  final int narrowSpan;

  /// How many columns this item spans on the wide layout
  /// ([GrowboxResponsiveGrid.wideColumns]).
  final int wideSpan;

  const ResponsiveGridItem(
    this.child, {
    this.narrowSpan = 1,
    this.wideSpan = 1,
  });
}

/// Responsive grid where each item declaratively spans 1..n columns.
///
/// Column count adapts to the available width (narrow vs wide breakpoint),
/// items wrap to a new row when they would overflow it, and all cards in a
/// row share the row's height — so call sites never do pixel-width math.
class GrowboxResponsiveGrid extends StatelessWidget {
  final List<ResponsiveGridItem> items;

  /// Gap between items and between rows.
  final double spacing;

  /// Column count at or below [wideBreakpoint].
  final int narrowColumns;

  /// Column count above [wideBreakpoint].
  final int wideColumns;

  /// Width (in logical pixels) at which the layout switches from
  /// [narrowColumns] to [wideColumns].
  final double wideBreakpoint;

  const GrowboxResponsiveGrid({
    super.key,
    required this.items,
    this.spacing = AppDimensions.lg,
    this.narrowColumns = 2,
    this.wideColumns = 3,
    this.wideBreakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > wideBreakpoint;
        final columns = isWide ? wideColumns : narrowColumns;

        int spanOf(ResponsiveGridItem item) =>
            (isWide ? item.wideSpan : item.narrowSpan).clamp(1, columns);

        // Chunk items into rows, wrapping to the next row whenever an item
        // would overflow the current one.
        final rows = <List<ResponsiveGridItem>>[];
        var current = <ResponsiveGridItem>[];
        var used = 0;
        for (final item in items) {
          final span = spanOf(item);
          if (used + span > columns && current.isNotEmpty) {
            rows.add(current);
            current = [];
            used = 0;
          }
          current.add(item);
          used += span;
        }
        if (current.isNotEmpty) rows.add(current);

        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              _buildRow(rows[i], spanOf),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRow(
    List<ResponsiveGridItem> row,
    int Function(ResponsiveGridItem) spanOf,
  ) {
    final children = <Widget>[];
    for (var i = 0; i < row.length; i++) {
      final item = row[i];
      if (i > 0) children.add(SizedBox(width: spacing));
      // Flex ratios instead of pixel widths: spans scale with the row and
      // IntrinsicHeight + stretch keeps every card in the row equal height.
      children.add(
        Expanded(flex: spanOf(item), child: item.child),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
