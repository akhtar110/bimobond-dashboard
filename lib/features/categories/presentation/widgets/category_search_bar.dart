import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/search_debounce.dart';
import '../bloc/categories_bloc.dart';

class CategorySearchBar extends StatefulWidget {
  const CategorySearchBar({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();
  final _debouncer = SearchDebouncer();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(CategorySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery.isEmpty &&
        oldWidget.initialQuery.isNotEmpty &&
        _ctrl.text.isNotEmpty &&
        !_focus.hasFocus) {
      _ctrl.clear();
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _dispatchSearch(String value, {bool immediate = false}) {
    void send() {
      if (!mounted) return;
      context.read<CategoriesBloc>().add(UpdateCategorySearchEvent(value));
    }

    if (immediate) {
      _debouncer.cancel();
      send();
      return;
    }

    _debouncer.run(send);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      onChanged: _dispatchSearch,
      onSubmitted: (value) => _dispatchSearch(value, immediate: true),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.tOr(
          'searchCategories',
          'Search by name, slug, ID, or keywords…',
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _ctrl,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: () {
                _ctrl.clear();
                _dispatchSearch('', immediate: true);
              },
            );
          },
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
    );
  }
}
