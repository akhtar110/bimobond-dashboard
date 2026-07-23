import 'package:flutter/material.dart';

/// Toolbar + scrollable body + optional footer (pagination) for data tabs.
class FeTabScaffold extends StatelessWidget {
  const FeTabScaffold({
    super.key,
    this.header,
    required this.child,
    this.footer,
  });

  final Widget? header;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[header!, const SizedBox(height: 8)],
        Expanded(
          child: SingleChildScrollView(
            clipBehavior: Clip.hardEdge,
            child: child,
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }
}
