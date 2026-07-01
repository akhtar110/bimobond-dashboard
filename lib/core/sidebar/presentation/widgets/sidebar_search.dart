import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../localization/localization.dart';
import '../../bloc/sidebar_bloc.dart';
import 'sidebar_tooltip.dart';

class SidebarSearch extends StatefulWidget {
  const SidebarSearch({super.key, required this.collapsed});

  final bool collapsed;

  @override
  State<SidebarSearch> createState() => _SidebarSearchState();
}

class _SidebarSearchState extends State<SidebarSearch> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<SidebarBloc>();

    if (widget.collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Center(
          child: SidebarTooltip(
            message: l10n.tOr('searchMenu', 'Search menu…'),
            child: Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => bloc.add(const ExpandSidebarEvent()),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.search_rounded, size: 18),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (v) {
          setState(() {});
          bloc.add(SearchMenuEvent(v));
        },
        decoration: InputDecoration(
          hintText: l10n.tOr('searchMenu', 'Search menu…'),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _controller.clear();
                    bloc.add(const SearchMenuEvent(''));
                    setState(() {});
                  },
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
