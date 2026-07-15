import 'package:flutter/material.dart';

/// Scrollable data table on desktop; card list on narrow screens.
class ResponsiveDataTable extends StatelessWidget {
  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.mobileCards,
    this.mobileBreakpoint = 720,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final List<Widget> mobileCards;
  final double mobileBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < mobileCards.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                mobileCards[i],
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: columns,
              rows: rows,
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        );
      },
    );
  }
}
