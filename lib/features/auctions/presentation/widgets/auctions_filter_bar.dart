import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/auctions_bloc.dart';
import '../utils/auctions_responsive.dart';

/// Inline search field for the auctions toolbar (matches posts style).
class AuctionsFilterBar extends StatefulWidget {
  const AuctionsFilterBar({
    super.key,
    this.compact = false,
    this.metrics,
    this.height,
  });

  final bool compact;
  final AuctionsLayoutMetrics? metrics;
  final double? height;

  @override
  State<AuctionsFilterBar> createState() => _AuctionsFilterBarState();
}

class _AuctionsFilterBarState extends State<AuctionsFilterBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _lastAppliedSearch = '';

  double get _controlHeight {
    if (widget.height != null) return widget.height!;
    final m = widget.metrics;
    if (m == null) return widget.compact ? 34.0 : 36.0;
    return m.filterControlHeight;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSearch(context.read<AuctionsBloc>().activeSearchQuery, force: true);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final trimmed = value.trim();
    if (trimmed == _lastAppliedSearch) return;
    _lastAppliedSearch = trimmed;
    context.read<AuctionsBloc>().add(UpdateAuctionSearchEvent(trimmed));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _applySearch(value);
    });
  }

  void _syncSearch(String text, {bool force = false}) {
    if (!force && _searchFocusNode.hasFocus) return;
    if (_searchController.text == text) return;
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _lastAppliedSearch = text;
  }

  bool _isFetching(AuctionsState state) =>
      state is AuctionsLoaded && state.isFetching;

  InputDecoration _fieldDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = _controlHeight;
    final verticalPad = ((height - 20) / 2).clamp(5.0, 10.0);
    final borderColor = scheme.outline.withValues(alpha: 0.22);
    final radius = BorderRadius.circular(8);
    return InputDecoration(
      hintText: context.l10n.tOr('searchAuctions', 'Search auctions…'),
      hintStyle: TextStyle(
        fontSize: 12.5,
        height: 1.1,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        size: 17,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: height,
        minHeight: height,
      ),
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.metrics?.isMobile == true ? 4 : 8,
        vertical: verticalPad,
      ),
      constraints: BoxConstraints(
        minHeight: height,
        maxHeight: height,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final height = _controlHeight;

    return BlocListener<AuctionsBloc, AuctionsState>(
      listenWhen: (prev, next) {
        final prevQ = prev is AuctionsLoaded
            ? prev.searchQuery
            : context.read<AuctionsBloc>().activeSearchQuery;
        final nextQ = next is AuctionsLoaded
            ? next.searchQuery
            : context.read<AuctionsBloc>().activeSearchQuery;
        return prevQ != nextQ;
      },
      listener: (context, state) {
        final query = state is AuctionsLoaded
            ? state.searchQuery
            : context.read<AuctionsBloc>().activeSearchQuery;
        _syncSearch(query, force: true);
      },
      child: BlocBuilder<AuctionsBloc, AuctionsState>(
        buildWhen: (prev, next) =>
            _isFetching(prev) != _isFetching(next) ||
            (prev is AuctionsLoaded &&
                next is AuctionsLoaded &&
                prev.searchQuery != next.searchQuery),
        builder: (context, state) {
          final isFetching = _isFetching(state);

          return SizedBox(
            height: height,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _applySearch,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 12.5, height: 1.1),
              decoration: _fieldDecoration(context).copyWith(
                suffixIconConstraints: BoxConstraints(
                  minWidth: height,
                  maxWidth: height,
                  minHeight: height,
                  maxHeight: height,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    return SizedBox(
                      width: height,
                      height: height,
                      child: Center(
                        child: isFetching
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applySearch('');
                                    },
                                    tooltip: l10n.t('clear'),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: height,
                                      minHeight: height,
                                    ),
                                  )
                                : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
