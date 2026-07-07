import 'package:flutter/material.dart';

/// Preserves tab state when switching sections in the reports center.
class ReportsKeepAliveTab extends StatefulWidget {
  const ReportsKeepAliveTab({super.key, required this.child});

  final Widget child;

  @override
  State<ReportsKeepAliveTab> createState() => _ReportsKeepAliveTabState();
}

class _ReportsKeepAliveTabState extends State<ReportsKeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
