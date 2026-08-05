import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/search_debounce.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/admin_auctions_query.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/usecases/get_all_auctions_usecase.dart';

const int _kMaxResults = 6;
const double _kItemHeight = 52;

/// A selectable live session resolved from auctions that already have a live link.
class AuctionLiveOption {
  const AuctionLiveOption({
    required this.id,
    this.title,
    this.status,
    this.hostUsername,
    this.itemName,
  });

  final String id;
  final String? title;
  final String? status;
  final String? hostUsername;
  final String? itemName;

  factory AuctionLiveOption.fromAuction(AuctionEntity auction) {
    final host = auction.host;
    final username = host?['username']?.toString();
    return AuctionLiveOption(
      id: auction.liveId ?? auction.live?.id ?? '',
      title: auction.live?.title,
      status: auction.live?.status,
      hostUsername: username,
      itemName: auction.itemName,
    );
  }

  factory AuctionLiveOption.fromSummary(AuctionLiveSummary live) {
    return AuctionLiveOption(
      id: live.id,
      title: live.title,
      status: live.status,
    );
  }

  String displayLabel(AppLocalizations l10n) {
    final title = this.title?.trim();
    if (title != null && title.isNotEmpty) {
      final host = hostUsername?.trim();
      if (host != null && host.isNotEmpty) return '$title · @$host';
      return title;
    }
    final item = itemName?.trim();
    if (item != null && item.isNotEmpty) {
      final host = hostUsername?.trim();
      if (host != null && host.isNotEmpty) {
        return '${l10n.tOr('liveFromAuction', 'Live from')} $item · @$host';
      }
      return '${l10n.tOr('liveFromAuction', 'Live from')} $item';
    }
    return l10n.tOr('linkedLiveSession', 'Linked live session');
  }
}

/// Searchable live picker — finds live sessions via auctions with `hasLive`.
class AuctionLiveSearchField extends StatefulWidget {
  const AuctionLiveSearchField({
    super.key,
    required this.onLiveSelected,
    this.selectedLive,
    this.initialLive,
    this.label,
    this.hintText,
  });

  final ValueChanged<AuctionLiveOption?> onLiveSelected;
  final AuctionLiveOption? selectedLive;
  final AuctionLiveOption? initialLive;
  final String? label;
  final String? hintText;

  @override
  State<AuctionLiveSearchField> createState() => _AuctionLiveSearchFieldState();
}

class _AuctionLiveSearchFieldState extends State<AuctionLiveSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _searchGuard = SearchRequestGuard();
  Timer? _debounce;

  bool _showDropdown = false;
  bool _loading = false;
  bool _searched = false;
  bool _replacing = false;
  bool _dropdownPointerDown = false;
  List<AuctionLiveOption> _results = [];

  GetAllAuctions get _getAllAuctions => sl<GetAllAuctions>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    final initial = widget.selectedLive ?? widget.initialLive;
    if (initial != null && initial.id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.text = initial.displayLabel(context.l10n);
        if (widget.selectedLive == null) {
          widget.onLiveSelected(initial);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuctionLiveSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLive?.id == oldWidget.selectedLive?.id) return;
    if (widget.selectedLive != null) {
      _replacing = false;
      _controller.text = widget.selectedLive!.displayLabel(context.l10n);
      setState(() {
        _showDropdown = false;
        _results = [];
      });
      return;
    }
    if (!_replacing) {
      _controller.clear();
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.trim().isNotEmpty && widget.selectedLive == null) {
        setState(() => _showDropdown = true);
      }
      return;
    }
    if (!_showDropdown || _dropdownPointerDown) return;
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _focusNode.hasFocus || _dropdownPointerDown) return;
      setState(() => _showDropdown = false);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (widget.selectedLive != null) {
      _replacing = true;
      widget.onLiveSelected(null);
    }

    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchGuard.next();
      setState(() {
        _showDropdown = false;
        _loading = false;
        _searched = false;
        _results = [];
      });
      return;
    }

    setState(() => _showDropdown = true);
    _debounce = Timer(dashboardSearchDebounce, () async {
      final token = _searchGuard.next();
      if (!mounted) return;
      setState(() {
        _loading = true;
        _searched = false;
      });
      try {
        final page = await _getAllAuctions(
          page: 1,
          limit: 20,
          query: AdminAuctionsQuery(
            search: trimmed,
            hasLive: true,
          ),
        );
        if (!mounted || !_searchGuard.isCurrent(token)) return;

        final seen = <String>{};
        final options = <AuctionLiveOption>[];
        for (final auction in page.auctions) {
          final liveId = auction.liveId ?? auction.live?.id;
          if (liveId == null || liveId.isEmpty || seen.contains(liveId)) {
            continue;
          }
          seen.add(liveId);
          options.add(AuctionLiveOption.fromAuction(auction));
          if (options.length >= _kMaxResults) break;
        }

        setState(() {
          _results = options;
          _loading = false;
          _searched = true;
        });
      } catch (_) {
        if (!mounted || !_searchGuard.isCurrent(token)) return;
        setState(() {
          _results = [];
          _loading = false;
          _searched = true;
        });
      }
    });
  }

  void _select(AuctionLiveOption live) {
    _replacing = false;
    widget.onLiveSelected(live);
    _controller.text = live.displayLabel(context.l10n);
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
      _searched = false;
    });
    _focusNode.unfocus();
  }

  void _clear() {
    _replacing = false;
    _controller.clear();
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
      _searched = false;
    });
    widget.onLiveSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = widget.label ?? l10n.tOr('liveSession', 'Live session');
    final hint = widget.hintText ??
        l10n.tOr(
          'searchLiveHint',
          'Search live by auction name or host…',
        );
    final showDropdown = _showDropdown &&
        (widget.selectedLive == null || _replacing) &&
        (_loading || _searched || _controller.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onTap: () {
            if (_controller.text.trim().isNotEmpty) {
              setState(() => _showDropdown = true);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(
              Icons.live_tv_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (widget.selectedLive != null ||
                    _controller.text.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: scheme.onSurfaceVariant,
                    tooltip: l10n.t('clear'),
                    onPressed: _clear,
                  ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        if (showDropdown)
          Listener(
            onPointerDown: (_) => _dropdownPointerDown = true,
            onPointerUp: (_) => _dropdownPointerDown = false,
            onPointerCancel: (_) => _dropdownPointerDown = false,
            child: _LiveDropdown(
              loading: _loading,
              results: _results,
              searched: _searched,
              onSelected: _select,
            ),
          ),
      ],
    );
  }
}

class _LiveDropdown extends StatelessWidget {
  const _LiveDropdown({
    required this.loading,
    required this.results,
    required this.searched,
    required this.onSelected,
  });

  final bool loading;
  final List<AuctionLiveOption> results;
  final bool searched;
  final ValueChanged<AuctionLiveOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4),
      child: Material(
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: 0.14),
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxHeight: _kMaxResults * _kItemHeight + 8),
            child: loading
                ? const SizedBox(
                    height: _kItemHeight,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : results.isEmpty
                    ? SizedBox(
                        height: _kItemHeight,
                        child: Center(
                          child: Text(
                            searched
                                ? l10n.tOr(
                                    'noLivesFound',
                                    'No live sessions found',
                                  )
                                : l10n.tOr(
                                    'searchLiveHint',
                                    'Search live by auction name or host…',
                                  ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                        itemBuilder: (context, index) {
                          final live = results[index];
                          final title = live.title?.trim().isNotEmpty == true
                              ? live.title!.trim()
                              : (live.itemName?.trim().isNotEmpty == true
                                  ? live.itemName!.trim()
                                  : l10n.tOr(
                                      'linkedLiveSession',
                                      'Linked live session',
                                    ));
                          final subtitleParts = <String>[
                            if (live.hostUsername != null &&
                                live.hostUsername!.isNotEmpty)
                              '@${live.hostUsername}',
                            if (live.status != null && live.status!.isNotEmpty)
                              live.status!,
                          ];
                          return InkWell(
                            onTap: () => onSelected(live),
                            child: SizedBox(
                              height: _kItemHeight,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: scheme.primaryContainer,
                                      child: Icon(
                                        Icons.live_tv_rounded,
                                        size: 16,
                                        color: scheme.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (subtitleParts.isNotEmpty)
                                            Text(
                                              subtitleParts.join(' · '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11.5,
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
